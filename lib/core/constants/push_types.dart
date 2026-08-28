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
    return t == documentUploaded ||
        t == 'document' ||
        t == 'documents' ||
        t == 'document_upload' ||
        t == 'user_document_upload' ||
        (t != null && t.contains('document'));
  }

  /// Private / admin DM aliases (backend may send any of these).
  static bool isPrivateChat(String? type) {
    final t = normalize(type);
    if (t == null) return false;
    return t == privateChatMessage ||
        t == privateChat ||
        t == 'privatechat' ||
        t == 'admin_chat' ||
        t == 'adminchat' ||
        t == 'admin_message' ||
        t == 'private_message' ||
        t == 'direct_message' ||
        t == 'dm' ||
        t.contains('private_chat') ||
        t.contains('admin_chat') ||
        t.contains('privatechat') ||
        t.contains('adminchat');
  }

  /// Group / condominium chat aliases.
  static bool isGroupChat(String? type) {
    final t = normalize(type);
    if (t == null) return false;
    if (isPrivateChat(t)) return false;
    return t == groupChat ||
        t == 'groupchat' ||
        t == 'chat' ||
        t == 'message' ||
        t == 'messages' ||
        t == 'chat_message' ||
        t == 'group_message' ||
        t == 'condominium_chat' ||
        t == 'condominio_chat' ||
        t == 'condominium' ||
        t == 'condominio' ||
        t == 'condo_chat' ||
        t == 'announcement' ||
        t == 'announcements' ||
        t.contains('group_chat') ||
        t.contains('groupchat') ||
        t.contains('condominium') ||
        t.contains('condominio') ||
        t.contains('announcement') ||
        t.contains('chat');
  }

  static bool isChat(String? type) => isPrivateChat(type) || isGroupChat(type);

  static bool isTicketOrSupport(String? type) {
    final t = normalize(type);
    return t == 'ticket' ||
        t == 'tickets' ||
        t == 'support' ||
        t == 'support_ticket' ||
        t == 'support_tickets';
  }

  /// Maintenance aliases (API may use EN, IT, or the historical `mantenance` typo).
  static bool isMaintenance(String? type) {
    final t = normalize(type);
    if (t == null) return false;
    return t == 'maintenance' ||
        t == 'mantenance' ||
        t == 'manutenzione' ||
        t == 'maintenance_updated' ||
        t == 'maintenance_status' ||
        t == 'maintenance_task' ||
        t == 'maintenance_tasks' ||
        t.contains('maintenance') ||
        t.contains('mantenance') ||
        t.contains('manutenzione');
  }

  static bool isSyncOrAnnouncement(String? type) {
    final t = normalize(type);
    return t == null || t == syncNotifications;
  }
}
