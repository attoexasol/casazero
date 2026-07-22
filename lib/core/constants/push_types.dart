// core/constants/push_types.dart
// Centralized FCM push payload type values. Use these instead of raw strings.

class PushTypes {
  PushTypes._();

  /// Admin uploaded a document; refresh documents list.
  static const String documentUploaded = 'document_uploaded';

  /// Backend-driven silent sync; refresh notifications and unread count.
  static const String syncNotifications = 'sync_notifications';

  /// Canonical private-chat push type (resident ↔ admin).
  static const String privateChatMessage = 'private_chat_message';

  /// Backend / outgoing alias for private chat.
  static const String privateChat = 'private_chat';

  /// Outgoing / feed alias for condominium group chat.
  static const String groupChat = 'group_chat';

  /// Normalize a raw type string (trim + lowercase). Empty → null.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    return s.isEmpty ? null : s;
  }

  static bool isDocument(String? type) {
    final t = normalize(type);
    return t == documentUploaded || t == 'document' || t == 'documents';
  }

  /// Private / admin DM aliases (backend may send any of these).
  static bool isPrivateChat(String? type) {
    final t = normalize(type);
    return t == privateChatMessage ||
        t == privateChat ||
        t == 'admin_chat' ||
        t == 'adminchat';
  }

  /// Group / condominium chat aliases.
  static bool isGroupChat(String? type) {
    final t = normalize(type);
    return t == groupChat ||
        t == 'groupchat' ||
        t == 'chat' ||
        t == 'message' ||
        t == 'messages' ||
        t == 'chat_message';
  }

  static bool isChat(String? type) =>
      isPrivateChat(type) || isGroupChat(type);

  static bool isTicketOrSupport(String? type) {
    final t = normalize(type);
    return t == 'ticket' ||
        t == 'tickets' ||
        t == 'support' ||
        t == 'support_ticket' ||
        t == 'support_tickets';
  }

  static bool isMaintenance(String? type) => normalize(type) == 'maintenance';

  static bool isSyncOrAnnouncement(String? type) {
    final t = normalize(type);
    return t == null ||
        t == syncNotifications ||
        t == 'announcement' ||
        t == 'announcements';
  }
}
