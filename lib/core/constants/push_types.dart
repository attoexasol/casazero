// core/constants/push_types.dart
// Centralized FCM push payload type values. Use these instead of raw strings.

class PushTypes {
  PushTypes._();

  /// Admin uploaded a document; refresh documents list.
  static const String documentUploaded = 'document_uploaded';

  /// Backend-driven silent sync; refresh notifications and unread count.
  static const String syncNotifications = 'sync_notifications';

  // Reserved for future use (do not remove; document navigation/chat/etc. can use these)
  // static const String newMessage = 'new_message';
  // static const String announcement = 'announcement';
}
