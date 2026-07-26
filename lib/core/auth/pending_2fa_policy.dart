import '../constants/api_constants.dart';
import 'auth_phase.dart';

/// Pure client-side policy for the login-time pending-2FA state.
///
/// Kept free of Flutter/GetX so unit tests can verify restart-recovery
/// behaviour without spinning up the full app.
class Pending2FAPolicy {
  Pending2FAPolicy._();

  /// Cold-start destination after splash.
  ///
  /// Mirrors [SplashController._checkAuthenticationAndNavigate]:
  /// - no session → AUTH
  /// - pending 2FA → OTP
  /// - otherwise (authenticated or legacy token session) → HOME
  static String splashDestination({
    required String? accessToken,
    required Map<String, dynamic>? userData,
    required AuthPhase phase,
  }) {
    final hasSession =
        accessToken != null && accessToken.isNotEmpty && userData != null;
    if (!hasSession) return '/auth';
    if (phase == AuthPhase.pending2FA) return '/otp-verification';
    return '/home';
  }

  /// Endpoints callable while [AuthPhase.pending2FA].
  ///
  /// OTP send/verify for all methods + auth endpoints (login/logout/refresh/
  /// forgot/reset). Everything else must be blocked client-side.
  static bool isAllowedEndpoint(String path) {
    const authEndpoints = {
      ApiConstants.LOGIN,
      ApiConstants.LOGOUT,
      ApiConstants.REFRESH_TOKEN,
      ApiConstants.FORGOT_PASSWORD,
      ApiConstants.RESET_PASSWORD,
    };

    const otpEndpoints = {
      ApiConstants.SEND_EMAIL_OTP,
      ApiConstants.VERIFY_EMAIL_OTP,
      ApiConstants.SEND_SMS_OTP,
      ApiConstants.VERIFY_SMS_OTP,
      ApiConstants.VERIFY_QR_CODE,
    };

    for (final endpoint in {...authEndpoints, ...otpEndpoints}) {
      if (path == endpoint || path.endsWith(endpoint)) {
        return true;
      }
    }
    return false;
  }
}
