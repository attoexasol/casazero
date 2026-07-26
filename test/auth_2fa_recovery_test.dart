import 'dart:io';

import 'package:casazero/app/middleware/auth_guard.dart';
import 'package:casazero/app/routes/app_routes.dart';
import 'package:casazero/core/auth/auth_phase.dart';
import 'package:casazero/core/auth/pending_2fa_policy.dart';
import 'package:casazero/core/constants/api_constants.dart';
import 'package:casazero/core/services/api_service.dart';
import 'package:casazero/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Verifies the client-side fix for:
/// Login → OTP → kill app → reopen must resume OTP, never HOME.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('casazero_2fa_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    await GetStorage.init();
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {
      // Windows may keep GetStorage file handles open briefly; ignore.
    }
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    storage = await StorageService().init();
    Get.put<StorageService>(storage);
  });

  tearDown(() async {
    await GetStorage().erase();
    Get.reset();
  });

  group('AuthPhase serialization', () {
    test('pending2FA round-trips through storage value', () {
      expect(AuthPhase.pending2FA.storageValue, 'pending_2fa');
      expect(AuthPhase.fromStorage('pending_2fa'), AuthPhase.pending2FA);
    });

    test('authenticated round-trips through storage value', () {
      expect(AuthPhase.authenticated.storageValue, 'authenticated');
      expect(AuthPhase.fromStorage('authenticated'), AuthPhase.authenticated);
    });

    test('missing / unknown values map to none (legacy-safe)', () {
      expect(AuthPhase.fromStorage(null), AuthPhase.none);
      expect(AuthPhase.fromStorage(''), AuthPhase.none);
      expect(AuthPhase.fromStorage('garbage'), AuthPhase.none);
    });
  });

  group('StorageService auth phase persistence', () {
    test('saveAuthPhase(pending2FA) survives re-init — process-death simulation',
        () async {
      await storage.saveAccessToken('tok_password_ok');
      await storage.saveUserData({
        'id': 1,
        'email': 'user@test.com',
        'two_fa_method': 'email',
      });
      await storage.saveAuthPhase(AuthPhase.pending2FA);

      // Simulate "app kill": discard DI, re-bind StorageService against same box.
      Get.reset();
      final restored = await StorageService().init();
      Get.put<StorageService>(restored);

      expect(restored.getAccessToken(), 'tok_password_ok');
      expect(restored.getUserData()?['two_fa_method'], 'email');
      expect(restored.getAuthPhase(), AuthPhase.pending2FA);
      expect(restored.isPending2FA, isTrue);
    });

    test('OTP success promotes pending2FA → authenticated', () async {
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      expect(storage.isPending2FA, isTrue);

      await storage.saveAuthPhase(AuthPhase.authenticated);

      expect(storage.getAuthPhase(), AuthPhase.authenticated);
      expect(storage.isPending2FA, isFalse);
    });

    test('clearAll (OTP cancel / logout) clears auth phase', () async {
      await storage.saveAccessToken('tok');
      await storage.saveUserData({'id': 1});
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      await storage.saveLanguage('en');

      await storage.clearAll();

      expect(storage.getAccessToken(), isNull);
      expect(storage.getUserData(), isNull);
      expect(storage.getAuthPhase(), AuthPhase.none);
      expect(storage.isPending2FA, isFalse);
      expect(storage.getLanguage(), 'en');
    });

    test('legacy session without AUTH_PHASE is NOT pending2FA', () async {
      await storage.saveAccessToken('legacy_tok');
      await storage.saveUserData({'id': 9, 'two_fa_method': 'email'});

      expect(storage.getAuthPhase(), AuthPhase.none);
      expect(storage.isPending2FA, isFalse);
    });
  });

  group('Splash destination (kill-app recovery)', () {
    test('Scenario 1: pending2FA + token → OTP, never HOME', () {
      final dest = Pending2FAPolicy.splashDestination(
        accessToken: 'tok',
        userData: {'id': 1, 'two_fa_method': 'email'},
        phase: AuthPhase.pending2FA,
      );
      expect(dest, AppRoutes.OTP_VERIFICATION);
      expect(dest, isNot(AppRoutes.HOME));
    });

    test('Scenario 2: authenticated + token → HOME', () {
      final dest = Pending2FAPolicy.splashDestination(
        accessToken: 'tok',
        userData: {'id': 1},
        phase: AuthPhase.authenticated,
      );
      expect(dest, AppRoutes.HOME);
    });

    test('Scenario 3: no session → AUTH', () {
      expect(
        Pending2FAPolicy.splashDestination(
          accessToken: null,
          userData: null,
          phase: AuthPhase.none,
        ),
        AppRoutes.AUTH,
      );
      expect(
        Pending2FAPolicy.splashDestination(
          accessToken: '',
          userData: {'id': 1},
          phase: AuthPhase.pending2FA,
        ),
        AppRoutes.AUTH,
      );
    });

    test('Scenario 4: trusted / legacy token without phase → HOME', () {
      final dest = Pending2FAPolicy.splashDestination(
        accessToken: 'legacy_tok',
        userData: {'id': 1, 'two_fa_method': 'email'},
        phase: AuthPhase.none,
      );
      expect(dest, AppRoutes.HOME);
    });

    test('end-to-end storage → splash decision after simulated kill', () async {
      await storage.saveAccessToken('tok');
      await storage.saveUserData({'id': 1, 'two_fa_method': 'sms'});
      await storage.saveAuthPhase(AuthPhase.pending2FA);

      Get.reset();
      final restored = await StorageService().init();

      final dest = Pending2FAPolicy.splashDestination(
        accessToken: restored.getAccessToken(),
        userData: restored.getUserData(),
        phase: restored.getAuthPhase(),
      );

      expect(dest, AppRoutes.OTP_VERIFICATION);
    });
  });

  group('AuthGuard middleware', () {
    test('pending2FA redirects HOME to OTP', () async {
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      final guard = AuthGuard();
      final redirect = guard.redirect(AppRoutes.HOME);

      expect(redirect, isNotNull);
      expect(redirect!.name, AppRoutes.OTP_VERIFICATION);
    });

    test('authenticated allows HOME', () async {
      await storage.saveAuthPhase(AuthPhase.authenticated);
      final guard = AuthGuard();
      expect(guard.redirect(AppRoutes.HOME), isNull);
    });

    test('legacy (none) allows HOME — does not break existing sessions', () {
      final guard = AuthGuard();
      expect(guard.redirect(AppRoutes.HOME), isNull);
    });

    test('deep-link into CHANGE_PASSWORD while pending → OTP', () async {
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      final guard = AuthGuard();
      final redirect = guard.redirect(AppRoutes.CHANGE_PASSWORD);
      expect(redirect?.name, AppRoutes.OTP_VERIFICATION);
    });
  });

  group('Pending2FA API allowlist', () {
    test('allows OTP send/verify for email, sms, authenticator', () {
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.SEND_EMAIL_OTP),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.VERIFY_EMAIL_OTP),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.SEND_SMS_OTP),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.VERIFY_SMS_OTP),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.VERIFY_QR_CODE),
        isTrue,
      );
    });

    test('allows logout / login / refresh / forgot / reset', () {
      expect(Pending2FAPolicy.isAllowedEndpoint(ApiConstants.LOGOUT), isTrue);
      expect(Pending2FAPolicy.isAllowedEndpoint(ApiConstants.LOGIN), isTrue);
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.REFRESH_TOKEN),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.FORGOT_PASSWORD),
        isTrue,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.RESET_PASSWORD),
        isTrue,
      );
    });

    test('blocks home/profile/documents and other authenticated APIs', () {
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.GET_USER_PROFILE),
        isFalse,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.GET_DOCUMENT_PASSWORD),
        isFalse,
      );
      expect(
        Pending2FAPolicy.isAllowedEndpoint(ApiConstants.SETUP_AUTHENTICATOR_2FA),
        isFalse,
      );
      expect(Pending2FAPolicy.isAllowedEndpoint('/home/dashboard'), isFalse);
    });
  });

  group('ApiService interceptor while pending2FA', () {
    test('blocks non-OTP authenticated request client-side', () async {
      await storage.saveAccessToken('tok');
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      final api = ApiService();

      expect(
        () => api.post(ApiConstants.GET_USER_PROFILE, data: {'token': 'tok'}),
        throwsA(
          predicate(
            (e) =>
                e is String &&
                (e.contains('cancelled') || e.contains('Request cancelled')),
          ),
        ),
      );
    });

    test('interceptor gate is inactive when authenticated', () async {
      await storage.saveAccessToken('tok');
      await storage.saveAuthPhase(AuthPhase.authenticated);
      expect(storage.isPending2FA, isFalse);
    });
  });

  group('Login navigation phase matrix', () {
    test('untrusted + 2FA → pending2FA before OTP', () async {
      await storage.saveAccessToken('tok');
      await storage.saveUserData({'two_fa_method': 'email'});
      await storage.saveAuthPhase(AuthPhase.pending2FA);

      expect(
        Pending2FAPolicy.splashDestination(
          accessToken: storage.getAccessToken(),
          userData: storage.getUserData(),
          phase: storage.getAuthPhase(),
        ),
        AppRoutes.OTP_VERIFICATION,
      );
    });

    test('trusted device → authenticated → HOME on restart', () async {
      await storage.saveAccessToken('tok');
      await storage.saveUserData({'id': 1, 'two_fa_method': 'email'});
      await storage.saveAuthPhase(AuthPhase.authenticated);

      expect(
        Pending2FAPolicy.splashDestination(
          accessToken: storage.getAccessToken(),
          userData: storage.getUserData(),
          phase: storage.getAuthPhase(),
        ),
        AppRoutes.HOME,
      );
    });

    test('OTP cancel clears session → AUTH on next splash', () async {
      await storage.saveAccessToken('tok');
      await storage.saveUserData({'id': 1});
      await storage.saveAuthPhase(AuthPhase.pending2FA);
      await storage.clearAll();

      expect(
        Pending2FAPolicy.splashDestination(
          accessToken: storage.getAccessToken(),
          userData: storage.getUserData(),
          phase: storage.getAuthPhase(),
        ),
        AppRoutes.AUTH,
      );
    });
  });

  group('Route guard coverage sanity', () {
    test('authenticated routes declare AuthGuard; public routes do not', () {
      final guarded = <String>{};
      for (final page in AppRoutes.routes) {
        final hasGuard = page.middlewares?.any((m) => m is AuthGuard) ?? false;
        if (hasGuard) guarded.add(page.name);
      }

      expect(guarded, contains(AppRoutes.HOME));
      expect(guarded, contains(AppRoutes.CHANGE_PASSWORD));
      expect(guarded, contains(AppRoutes.TWO_FA_MANAGEMENT));
      expect(guarded, contains(AppRoutes.TWO_FA_ACTIVATION));
      expect(guarded, contains(AppRoutes.TWO_FA_DEACTIVATION_VERIFICATION));
      expect(guarded, contains(AppRoutes.TRUSTED_DEVICES));
      expect(guarded, contains(AppRoutes.DOCUMENT_PASSWORD));
      expect(guarded, contains(AppRoutes.DOCUMENT_PASSWORD_2FA));

      expect(guarded, isNot(contains(AppRoutes.SPLASH)));
      expect(guarded, isNot(contains(AppRoutes.AUTH)));
      expect(guarded, isNot(contains(AppRoutes.OTP_VERIFICATION)));
      expect(guarded, isNot(contains(AppRoutes.FIRST_LOGIN)));
      expect(guarded, isNot(contains(AppRoutes.FORGOT_PASSWORD)));
      expect(guarded, isNot(contains(AppRoutes.FORGOT_CHANGE_PASSWORD)));
    });
  });
}

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this._path);

  final String _path;

  @override
  Future<String?> getApplicationDocumentsPath() async => _path;

  @override
  Future<String?> getTemporaryPath() async => _path;

  @override
  Future<String?> getApplicationSupportPath() async => _path;

  @override
  Future<String?> getLibraryPath() async => _path;

  @override
  Future<String?> getDownloadsPath() async => _path;
}
