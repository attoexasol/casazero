import 'dart:io';

import 'package:casazero/core/localization/locale_controller.dart';
import 'package:casazero/core/services/storage_service.dart';
import 'package:casazero/main.dart';
import 'package:casazero/presentation/splash/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('casazero_widget_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    await GetStorage.init();
  });

  tearDownAll(() async {
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  setUp(() async {
    Get.reset();
    await GetStorage().erase();
    await Get.putAsync(() => StorageService().init());
  });

  tearDown(Get.reset);

  testWidgets('CasaZero app starts on the splash screen', (tester) async {
    // LocaleController.onInit calls Get.updateLocale, which reassembles the
    // binding. Register it after a widget tree exists (same order as main.dart:
    // StorageService → LocaleController → CasaZeroApp).
    await tester.pumpWidget(const SizedBox.shrink());
    Get.put(LocaleController());
    await tester.pump();

    await tester.pumpWidget(const CasaZeroApp());
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('La tua casa, sempre con te.'), findsOneWidget);
    expect(find.text('CASAZERO', findRichText: true), findsOneWidget);
  });
}

/// Test-only path_provider stand-in used by GetStorage (see auth_2fa_recovery_test).
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
