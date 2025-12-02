import '../../data/models/user_model.dart';

class NotificationPreferences {
  final UserModel user;

  NotificationPreferences(this.user);

  bool get canSendDocumentNotification => user.isDocumentNotify;
  bool get canSendMaintenanceNotification => user.isMaintenanceNotify;
  bool get canSendChatNotification => user.isChatNotify;
  bool get canSendSupportTicketNotification => user.isSupportTicketNotify;

  Map<String, bool> toMap() {
    return {
      'document': user.isDocumentNotify,
      'maintenance': user.isMaintenanceNotify,
      'chat': user.isChatNotify,
      'support_ticket': user.isSupportTicketNotify,
    };
  }
}
