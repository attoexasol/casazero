import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../localization/app_translations.dart';
import '../localization/locale_controller.dart';
import '../constants/storage_keys.dart';
import '../constants/push_types.dart';

/// Structured fields extracted from notification body (display-only).
class NotificationParsedContent {
  const NotificationParsedContent({this.subject, this.rawStatus});

  final String? subject;
  final String? rawStatus;

  bool get hasSubject => subject != null && subject!.trim().isNotEmpty;

  bool get hasStatus => rawStatus != null && rawStatus!.trim().isNotEmpty;

  bool get hasStructure => hasSubject || hasStatus;
}

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

  /// Matches: Il ticket "Name" … / The ticket "Name" …
  static final RegExp _ticketQuotedNameRegex = RegExp(
    r'''ticket\s+["“«]([^"”»]+)["”»]''',
    caseSensitive: false,
  );

  /// Matches trailing "Stato: …" / "Status: …"
  static final RegExp _statusLabelRegex = RegExp(
    r'(?:Stato|Status)\s*:\s*(.+)$',
    caseSensitive: false,
  );

  /// Subject - Status separators used by maintenance content.
  static final RegExp _dashSeparatorRegex = RegExp(r'\s+[-–—]\s+');

  static String stripEmojis(String text) {
    return text
        .replaceAll(_emojiRegex, '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Collapse newlines/extra spaces so embedded `\n` does not leak into UI.
  static String normalizeWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'[\r\n]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Test-only override for [isItalian]. Null = use real locale/storage.
  static bool? debugIsItalianOverride;

  static bool get isItalian {
    if (debugIsItalianOverride != null) return debugIsItalianOverride!;

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

  /// Resolves a translation key in UI and FCM background isolates.
  static String translate(String key, {Map<String, String>? params}) {
    try {
      if (params != null && params.isNotEmpty) {
        final result = key.trParams(params);
        if (result != key) return result;
      } else {
        final result = key.tr;
        if (result != key) return result;
      }
    } catch (_) {}

    final map = isItalian ? AppTranslations.itIT : AppTranslations.enUS;
    var text = map[key] ?? key;
    if (params != null) {
      for (final entry in params.entries) {
        text = text
            .replaceAll('{${entry.key}}', entry.value)
            .replaceAll('@${entry.key}', entry.value);
      }
    }
    return text;
  }

  static bool isTicketType(String? type) => PushTypes.isTicketOrSupport(type);

  static bool isMaintenanceType(String? type) => PushTypes.isMaintenance(type);

  static bool isChatType(String? type) {
    final t = PushTypes.normalize(type);
    if (t == null) return false;
    if (t == 'announcement' || t == 'announcements') return false;
    return PushTypes.isChat(t);
  }

  static bool looksLikeTicket({String? title, String? body}) {
    final haystack = '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return haystack.contains('support ticket') ||
        haystack.contains('ticket updated') ||
        haystack.contains('ticket status') ||
        haystack.contains('ticket di supporto') ||
        haystack.contains('ticket aggiornato');
  }

  /// True when title/body clearly refer to a maintenance update (EN/IT).
  static bool looksLikeMaintenance({String? title, String? body}) {
    final haystack = '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return haystack.contains('maintenance status') ||
        haystack.contains('maintenance updated') ||
        haystack.contains('maintenance task') ||
        haystack.contains('stato manutenzione') ||
        haystack.contains('manutenzione aggiornat') ||
        haystack.contains('attività di manutenzione') ||
        haystack.contains('aggiornamento manutenzione') ||
        haystack.contains('maintenance update') ||
        haystack.contains('maintenance:') ||
        haystack.contains('manutenzione:');
  }

  /// True when title/body clearly refer to a chat message (EN/IT).
  static bool looksLikeChat({String? title, String? body}) {
    if (isGenericChatTitle(title ?? '')) return true;

    final haystack = '${title ?? ''} ${body ?? ''}'.toLowerCase();
    return haystack.contains('new message') ||
        haystack.contains('nuovo messaggio') ||
        haystack.contains('condominium chat') ||
        haystack.contains('chat di condominio') ||
        haystack.contains('chat message') ||
        haystack.contains('messaggio chat') ||
        haystack.contains('new chat message') ||
        haystack.contains('nuovo messaggio chat');
  }

  static bool isGenericChatTitle(String text) {
    final lower = stripEmojis(text).toLowerCase().trim();
    if (lower.isEmpty) return true;

    const genericPatterns = [
      'new message',
      'nuovo messaggio',
      'condominium chat',
      'chat di condominio',
      'chat message',
      'messaggio chat',
      'new chat message',
      'nuovo messaggio chat',
      'group chat',
      'chat di gruppo',
    ];

    return genericPatterns.any(
      (pattern) => lower == pattern || lower.contains(pattern),
    );
  }

  /// Localized chat push title — mirrors [localizedTicketTitle] pattern.
  static String localizedChatTitle({String? type, String? rawTitle}) {
    final titleLower = stripEmojis(rawTitle ?? '').toLowerCase();
    final isGroup = PushTypes.isGroupChat(type) ||
        (!PushTypes.isPrivateChat(type) &&
            (titleLower.contains('condominium chat') ||
                titleLower.contains('chat di condominio') ||
                titleLower.contains('group chat') ||
                titleLower.contains('chat di gruppo')));

    if (isGroup) {
      return translate('notification_center_title_chat');
    }

    return translate('notification_new_message');
  }

  /// Extract status from the legacy English ticket pattern.
  static String? extractTicketStatus(String? text) {
    if (text == null || text.isEmpty) return null;
    final match = _ticketStatusRegex.firstMatch(normalizeWhitespace(stripEmojis(text)));
    return match?.group(1);
  }

  /// Parse ticket subject + status from backend content (safe; null if no match).
  static NotificationParsedContent? parseTicketContent(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    try {
      final cleaned = normalizeWhitespace(stripEmojis(text));
      if (cleaned.isEmpty) return null;

      String? subject;
      String? status;

      final quoted = _ticketQuotedNameRegex.firstMatch(cleaned);
      if (quoted != null) {
        subject = normalizeWhitespace(quoted.group(1) ?? '');
        if (subject.isEmpty) subject = null;
      }

      final labeled = _statusLabelRegex.firstMatch(cleaned);
      if (labeled != null) {
        status = normalizeWhitespace(
          (labeled.group(1) ?? '').replaceAll(RegExp(r'[.]+$'), ''),
        );
        if (status.isEmpty) status = null;
      }

      status ??= extractTicketStatus(cleaned);

      if (subject == null && status == null) return null;
      return NotificationParsedContent(subject: subject, rawStatus: status);
    } catch (_) {
      return null;
    }
  }

  /// Parse maintenance "Subject - Status" content (safe; null if no match).
  static NotificationParsedContent? parseMaintenanceContent(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    try {
      final cleaned = normalizeWhitespace(stripEmojis(text));
      if (cleaned.isEmpty) return null;

      final parts = cleaned.split(_dashSeparatorRegex);
      if (parts.length >= 2) {
        final status = parts.last.trim();
        final subject = parts.sublist(0, parts.length - 1).join(' - ').trim();
        if (subject.isNotEmpty &&
            status.isNotEmpty &&
            looksLikeKnownStatus(status)) {
          return NotificationParsedContent(
            subject: subject,
            rawStatus: status,
          );
        }
      }

      // Unstructured maintenance body — treat whole text as subject.
      return NotificationParsedContent(subject: cleaned);
    } catch (_) {
      return null;
    }
  }

  /// True when [value] matches a known notification status (EN/IT/API codes).
  static bool looksLikeKnownStatus(String value) {
    final normalized = _normalizeStatusKey(value);
    const known = {
      'pending',
      'open',
      'in_attesa',
      'in_progress',
      'in_corso',
      'in_scadenza',
      'due',
      'completato',
      'completed',
      'resolved',
      'closed',
      'overdue',
      'scaduto',
    };
    return known.contains(normalized);
  }

  static String _normalizeStatusKey(String rawStatus) {
    return rawStatus
        .toLowerCase()
        .trim()
        .replaceAll('-', '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  /// Whether ticket content is a generic placeholder (no useful subject/status).
  static bool isGenericTicketContent(String text) {
    final cleaned = normalizeWhitespace(stripEmojis(text));
    if (cleaned.isEmpty) return true;

    // Structured ticket payloads are never "generic".
    final parsed = parseTicketContent(cleaned);
    if (parsed != null && parsed.hasSubject) return false;

    final lower = cleaned.toLowerCase();
    return lower.contains('support ticket status has been updated') ||
        lower.contains('your support ticket status has been updated') ||
        lower.contains('your ticket status has been updated') ||
        lower.contains('your support ticket has been updated') ||
        lower.contains('your ticket has been updated') ||
        lower.contains('il tuo ticket') ||
        lower.contains('stato del ticket') ||
        lower == 'ticket di supporto' ||
        lower == 'support ticket';
  }

  /// Display-only status localization (does not mutate API data).
  static String localizeNotificationStatus(String rawStatus) {
    final normalized = _normalizeStatusKey(rawStatus);
    switch (normalized) {
      case 'pending':
      case 'open':
      case 'in_attesa':
        return translate('pending');
      case 'in_progress':
      case 'in_corso':
        return translate('in_progress');
      case 'in_scadenza':
      case 'due':
        return translate('dueStatus');
      case 'completato':
      case 'completed':
      case 'resolved':
      case 'closed':
        return translate('completed');
      case 'overdue':
      case 'scaduto':
        return translate('overdueStatus');
      default:
        return rawStatus.trim().replaceAll('_', ' ');
    }
  }

  /// Backward-compatible alias used by older call sites.
  static String localizeTicketStatus(String rawStatus) =>
      localizeNotificationStatus(rawStatus);

  static String localizedTicketTitle({String? rawTitle}) {
    return translate('notification_ticket_updated');
  }

  static String localizedMaintenanceTitle({String? rawTitle}) {
    return translate('notification_maintenance_updated');
  }

  static String _statusPrefixLabel() => translate('notification_status_label');

  /// Modal: subject + newline + "Stato/Status: …"
  /// Push: subject — Stato/Status: …
  static String formatStructuredBody({
    String? subject,
    String? rawStatus,
    bool forPush = false,
    String? fallbackBody,
  }) {
    final cleanSubject =
        subject == null ? '' : normalizeWhitespace(stripEmojis(subject));
    final statusText = (rawStatus == null || rawStatus.trim().isEmpty)
        ? null
        : localizeNotificationStatus(rawStatus);
    final statusLine =
        statusText == null ? null : '${_statusPrefixLabel()}: $statusText';

    if (cleanSubject.isNotEmpty && statusLine != null) {
      return forPush ? '$cleanSubject — $statusLine' : '$cleanSubject\n$statusLine';
    }
    if (cleanSubject.isNotEmpty) return cleanSubject;
    if (statusLine != null) return statusLine;

    final fallback = fallbackBody == null
        ? ''
        : normalizeWhitespace(stripEmojis(fallbackBody));
    return fallback;
  }

  /// Ticket body for modal (`forPush: false`) or push banner (`forPush: true`).
  static String localizedTicketBody({
    String? rawBody,
    bool forPush = false,
  }) {
    final cleaned = normalizeWhitespace(stripEmojis(rawBody ?? ''));
    final parsed = parseTicketContent(cleaned);

    if (parsed != null && parsed.hasStructure) {
      final formatted = formatStructuredBody(
        subject: parsed.subject,
        rawStatus: parsed.rawStatus,
        forPush: forPush,
        fallbackBody: cleaned,
      );
      if (formatted.isNotEmpty) return formatted;
    }

    // Preserve original content when structure cannot be parsed.
    if (cleaned.isNotEmpty) return cleaned;
    return translate('notification_ticket_description');
  }

  /// Maintenance body for modal (`forPush: false`) or push banner (`forPush: true`).
  static String localizedMaintenanceBody({
    String? rawBody,
    bool forPush = false,
  }) {
    final cleaned = normalizeWhitespace(stripEmojis(rawBody ?? ''));
    final parsed = parseMaintenanceContent(cleaned);

    if (parsed != null && parsed.hasStatus) {
      final formatted = formatStructuredBody(
        subject: parsed.subject,
        rawStatus: parsed.rawStatus,
        forPush: forPush,
        fallbackBody: cleaned,
      );
      if (formatted.isNotEmpty) return formatted;
    }

    if (cleaned.isNotEmpty) return cleaned;
    return translate('notification_maintenance_description');
  }

  /// Resolve display title/body for push and notification center.
  static ({String title, String body}) localize({
    String? type,
    required String title,
    required String body,
  }) {
    final cleanTitle = normalizeWhitespace(stripEmojis(title));
    final cleanBody = normalizeWhitespace(stripEmojis(body));

    // Prefer notification_type over content heuristics.
    final ticket = isTicketType(type) ||
        (!isMaintenanceType(type) &&
            looksLikeTicket(title: cleanTitle, body: cleanBody));

    if (ticket) {
      return (
        title: localizedTicketTitle(rawTitle: cleanTitle),
        body: localizedTicketBody(rawBody: cleanBody, forPush: true),
      );
    }

    final maintenance = isMaintenanceType(type) ||
        looksLikeMaintenance(title: cleanTitle, body: cleanBody);

    if (maintenance) {
      return (
        title: localizedMaintenanceTitle(rawTitle: cleanTitle),
        body: localizedMaintenanceBody(rawBody: cleanBody, forPush: true),
      );
    }

    final chat = isChatType(type) ||
        looksLikeChat(title: cleanTitle, body: cleanBody);

    if (chat) {
      return (
        title: localizedChatTitle(type: type, rawTitle: cleanTitle),
        body: cleanBody,
      );
    }

    return (
      title: cleanTitle.isNotEmpty ? cleanTitle : translate('app_name'),
      body: cleanBody,
    );
  }
}
