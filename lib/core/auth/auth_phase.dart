/// Durable authentication phase, persisted across process death.
///
/// Fixes the "kill app during OTP → reopen → bypass OTP" vulnerability:
/// tokens are written at password-login time, so token presence alone can
/// never distinguish "password verified" from "2FA completed". This phase can.
///
/// Storage semantics (see [StorageKeys.AUTH_PHASE]):
/// - `pending_2fa`   — password accepted, OTP challenge NOT completed yet.
/// - `authenticated` — session fully established (OTP done, trusted device,
///                     or 2FA not enabled).
/// - key absent      — either logged out (storage cleared) or a legacy
///                     session created before this flag existed. Legacy
///                     sessions are treated as authenticated so existing
///                     users are not forced through OTP on update.
enum AuthPhase {
  none,
  pending2FA,
  authenticated;

  static const String _pendingValue = 'pending_2fa';
  static const String _authenticatedValue = 'authenticated';

  String get storageValue {
    switch (this) {
      case AuthPhase.pending2FA:
        return _pendingValue;
      case AuthPhase.authenticated:
        return _authenticatedValue;
      case AuthPhase.none:
        return '';
    }
  }

  static AuthPhase fromStorage(String? raw) {
    switch (raw) {
      case _pendingValue:
        return AuthPhase.pending2FA;
      case _authenticatedValue:
        return AuthPhase.authenticated;
      default:
        return AuthPhase.none;
    }
  }
}
