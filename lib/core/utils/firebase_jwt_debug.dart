import 'dart:convert';

/// Decodes Firebase custom-token JWT payload for debugging (no signature verify).
class FirebaseJwtDebug {
  FirebaseJwtDebug._();

  static Map<String, dynamic>? decodePayload(String jwt) {
    try {
      final parts = jwt.trim().split('.');
      if (parts.length < 2) return null;
      var segment = parts[1];
      final mod = segment.length % 4;
      if (mod > 0) {
        segment += '=' * (4 - mod);
      }
      final normalized = segment.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded);
      if (json is Map) {
        return Map<String, dynamic>.from(json);
      }
    } catch (_) {}
    return null;
  }

  /// Human-readable claims for logs (never log full token).
  static String describeClaims(Map<String, dynamic>? payload) {
    if (payload == null) return 'payload=decode_failed';
    final aud = payload['aud'];
    final iss = payload['iss'];
    final sub = payload['sub'];
    final uid = payload['uid'] ?? payload['user_id'];
    final exp = payload['exp'];
    final iat = payload['iat'];
    return 'aud=$aud iss=$iss sub=$sub uid=$uid iat=$iat exp=$exp';
  }

  /// Compare token audience to the Firebase app the client initialized.
  static String? audienceMismatchHint({
    required String? clientProjectId,
    required Map<String, dynamic>? payload,
  }) {
    if (clientProjectId == null || clientProjectId.isEmpty || payload == null) {
      return null;
    }
    final aud = payload['aud']?.toString();
    if (aud == null || aud.isEmpty) return null;
    if (aud == clientProjectId) return null;
    return 'TOKEN_AUD_MISMATCH: JWT aud="$aud" but Firebase app projectId="$clientProjectId". '
        'Laravel Admin SDK service account must be from project "$clientProjectId".';
  }
}
