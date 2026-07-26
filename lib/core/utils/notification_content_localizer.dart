import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../localization/locale_controller.dart';
import '../constants/storage_keys.dart';
import '../constants/push_types.dart';

/// Localizes API/FCM notification title+body for in-app and push display.
/// Works in the UI isolate via GetX, and in FCM background with GetStorage.
class NotificationContentLocalizer {
  NotificationContentLocalizer._();

  static final RegExp _emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{FE0F}\u{200D}\u{20E3}]',
    unicode: true,
  );

  /// Matches: Your support ticket status has been updated to "pending".
  static final RegExp _ticketStatusRegex = RegExp(
    r'ticket\s+status\s+has\s+been\s+updated\s+to\s+["“]?([a-zA-Z0-9_-]+)["”]?',
    caseSensitive: false,
  );

  static String stripEmojis(String text) {
    return text
        .replaceAll(_emojiRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool get isItalian {
    try {
      if (Get.isRegistered<LocaleController>()) {
        return Get.find<LocaleController>().isItalian;
      }
    } catch (_) {}

    try {
      final stored = GetStorage().read(StorageKeys.LANGUAGE)?.toString();
      if (stored == 'en') return false;
      if (stored == 'it') return true;
    } catch (_) {}

    // App default locale is Italian.
    return true;
  }

  static bool isTicketType(String? type) => PushTypes.isTicketOrSupport(type);

  static bool looksLikeTicket({String? title, String? body}) {
    final haystack =
        '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return haystack.contains('support ticket') ||
        haystack.contains('ticket updated') ||
        haystack.contains('ticket status') ||
        haystack.contains('ticket di supporto') ||
        haystack.contains('ticket aggiornato');
  }

  /// True when title/body clearly refer to a maintenance update (EN/IT).
  static bool looksLikeMaintenance({String? title, String? body}) {
    final haystack =
        '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return haystack.contains('maintenance status') ||
        haystack.contains('maintenance updated') ||
        haystack.contains('maintenance task') ||
        haystack.contains('stato manutenzione') ||
        haystack.contains('manutenzione aggiornat') ||
        haystack.contains('attività di manutenzione') ||
        haystack.contains('maintenance:') ||
        haystack.contains('manutenzione:');
  }

  static String? extractTicketStatus(String? text) {
    if (text == null || text.isEmpty) return null;
    final match = _ticketStatusRegex.firstMatch(stripEmojis(text));
    return match?.group(1);
  }

  static bool isGenericTicketContent(String text) {
    final lower = stripEmojis(text).toLowerCase();
    if (lower.isEmpty) return true;
    return lower.contains('support ticket status has been updated') ||
        lower.contains('your support ticket status has been updated') ||
        lower.contains('your ticket status has been updated') ||
        lower.contains('your support ticket has been updated') ||
        lower.contains('your ticket has been updated') ||
        lower.contains('il tuo ticket') ||
        lower.contains('stato del ticket') ||
        lower.contains('ticket di supporto');
  }

  static String localizeTicketStatus(String rawStatus) {
    final normalized = rawStatus.toLowerCase().trim().replaceAll('-', '_');
    switch (normalized) {
      case 'pending':
      case 'open':
        return isItalian ? 'In Attesa' : 'Pending';
      case 'in_progress':
        return isItalian ? 'In Corso' : 'In Progress';
      case 'resolved':
      case 'closed':
        return isItalian ? 'Risolto' : 'Resolved';
      default:
        return rawStatus.replaceAll('_', ' ');
    }
  }

  static String localizedTicketTitle() {
    return isItalian ? 'Ticket aggiornato' : 'Ticket updated';
  }

  static String localizedTicketBody({String? rawBody}) {
    final status = extractTicketStatus(rawBody);
    if (status != null) {
      final label = localizeTicketStatus(status);
      return isItalian
          ? 'Lo stato del tuo ticket di supporto è stato aggiornato a "$label".'
          : 'Your support ticket status has been updated to "$label".';
    }

    return isItalian
        ? 'Il tuo ticket è stato aggiornato.'
        : 'Your ticket has been updated.';
  }

  /// Resolve display title/body for push and notification center.
  static ({String title, String body}) localize({
    String? type,
    required String title,
    required String body,
  }) {
    final cleanTitle = stripEmojis(title);
    final cleanBody = stripEmojis(body);

    final ticket = isTicketType(type) ||
        looksLikeTicket(title: cleanTitle, body: cleanBody);

    if (ticket) {
      return (
        title: localizedTicketTitle(),
        body: localizedTicketBody(rawBody: cleanBody),
      );
    }

    return (
      title: cleanTitle.isNotEmpty ? cleanTitle : 'CasaZero',
      body: cleanBody,
    );
  }
}
