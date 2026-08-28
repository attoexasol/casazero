import 'package:casazero/core/utils/notification_content_localizer.dart';
import 'package:casazero/data/models/feed_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    NotificationContentLocalizer.debugIsItalianOverride = null;
  });

  tearDown(() {
    NotificationContentLocalizer.debugIsItalianOverride = null;
  });

  group('FeedItemModel type inference and payload mapping', () {
    test('announcement type infers group_chat type safely without loop or overflow', () {
      final item = FeedItemModel(
        id: '1',
        type: 'announcement',
        title: 'Community Announcement',
        description: 'Notice about power cut',
        timestamp: DateTime.now(),
      );
      expect(item.isDocumentType, isFalse);
      expect(item.isMaintenanceType, isFalse);
      expect(item.isTicketType, isFalse);
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isFalse);
      expect(item.toNavigationPayload()['type'], 'group_chat');
    });

    test('maintenance_residence type infers maintenance correctly', () {
      final item = FeedItemModel(
        id: '2',
        type: 'maintenance_residence',
        title: 'Carica refrigerante',
        description: 'Controllo refrigerante',
        timestamp: DateTime.now(),
        referenceId: '196',
      );
      expect(item.isMaintenanceType, isTrue);
      expect(item.isDocumentType, isFalse);
      expect(item.toNavigationPayload()['type'], 'maintenance');
      expect(item.toNavigationPayload()['reference_id'], '196');
    });

    test('residence_status type maps safely', () {
      final item = FeedItemModel(
        id: '3',
        type: 'residence_status',
        title: 'Status Updated',
        description: 'Phase completed',
        timestamp: DateTime.now(),
      );
      expect(item.isDocumentType, isFalse);
      expect(item.isMaintenanceType, isFalse);
      expect(item.toNavigationPayload()['type'], 'residence_status');
    });

    test('announcement with pdf url infers document type', () {
      final item = FeedItemModel(
        id: '4',
        type: 'announcement',
        title: 'New Document Uploaded 📄',
        description: 'Your document is ready',
        timestamp: DateTime.now(),
        url: 'https://backend.casazero.site/storage/documents/contract.pdf',
      );
      expect(item.isDocumentType, isTrue);
      expect(item.toNavigationPayload()['type'], 'document');
    });

    test('chat announcement infers group_chat type', () {
      final item = FeedItemModel(
        id: '5',
        type: 'announcement',
        title: 'New Message 💬',
        description: 'New chat message in group',
        timestamp: DateTime.now(),
      );
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isFalse);
      expect(item.toNavigationPayload()['type'], 'group_chat');
    });

    test('condominium group chat notification in Italian infers group_chat type', () {
      final item = FeedItemModel(
        id: '6',
        type: 'announcement',
        title: 'Chat di condominio: Nuovo messaggio',
        description: 'Marco Rossi: Buongiorno a tutti i residenti',
        timestamp: DateTime.now(),
      );
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isFalse);
      expect(item.toNavigationPayload()['type'], 'group_chat');
    });

    test('condominium_chat alias maps to group_chat', () {
      final item = FeedItemModel(
        id: '7',
        type: 'condominium_chat',
        title: 'Condominium Chat',
        description: 'Hello everyone',
        timestamp: DateTime.now(),
      );
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isFalse);
      expect(item.toNavigationPayload()['type'], 'group_chat');
    });

    test('admin private chat notification maps to private_chat', () {
      final item = FeedItemModel(
        id: '8',
        type: 'private_chat',
        title: 'Amministratore Supporto',
        description: 'Abbiamo ricevuto la tua richiesta',
        timestamp: DateTime.now(),
      );
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isTrue);
      expect(item.toNavigationPayload()['type'], 'private_chat');
    });

    test('chat notification with admin in title maps to private_chat', () {
      final item = FeedItemModel(
        id: '9',
        type: 'announcement',
        title: 'Messaggio da Amministratore',
        description: 'Gentile condomino, si comunica...',
        timestamp: DateTime.now(),
      );
      expect(item.isChatNotification, isTrue);
      expect(item.isAdminChatNotification, isTrue);
      expect(item.toNavigationPayload()['type'], 'private_chat');
    });
  });

  group('normalizeWhitespace', () {
    test('strips embedded newlines inside quoted ticket names', () {
      final cleaned = NotificationContentLocalizer.normalizeWhitespace(
        'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Attesa.',
      );
      expect(cleaned.contains('\n'), isFalse);
      expect(cleaned.contains('Impianti idraulici e idrici'), isTrue);
    });
  });

  group('parseTicketContent', () {
    test('extracts subject and Italian status', () {
      final parsed = NotificationContentLocalizer.parseTicketContent(
        'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Attesa.',
      );
      expect(parsed, isNotNull);
      expect(parsed!.subject, 'Impianti idraulici e idrici');
      expect(parsed.rawStatus, 'In Attesa');
    });

    test('extracts subject and In Corso status', () {
      final parsed = NotificationContentLocalizer.parseTicketContent(
        'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Corso.',
      );
      expect(parsed, isNotNull);
      expect(parsed!.subject, 'Impianti idraulici e idrici');
      expect(parsed.rawStatus, 'In Corso');
    });

    test('returns null for unrelated content', () {
      final parsed = NotificationContentLocalizer.parseTicketContent(
        'A new document has been uploaded.',
      );
      expect(parsed, isNull);
    });
  });

  group('parseMaintenanceContent', () {
    test('splits subject and Italian due status', () {
      final parsed = NotificationContentLocalizer.parseMaintenanceContent(
        'Imbiancatura interni - In Scadenza',
      );
      expect(parsed, isNotNull);
      expect(parsed!.subject, 'Imbiancatura interni');
      expect(parsed.rawStatus, 'In Scadenza');
    });

    test('splits subject and Completato status', () {
      final parsed = NotificationContentLocalizer.parseMaintenanceContent(
        'Pulizia muri esterni - Completato',
      );
      expect(parsed, isNotNull);
      expect(parsed!.subject, 'Pulizia muri esterni');
      expect(parsed.rawStatus, 'Completato');
    });

    test('splits subject and English pending status', () {
      final parsed = NotificationContentLocalizer.parseMaintenanceContent(
        'Verifica lucernari - pending',
      );
      expect(parsed, isNotNull);
      expect(parsed!.subject, 'Verifica lucernari');
      expect(parsed.rawStatus, 'pending');
    });
  });

  group('Italian display formatting', () {
    setUp(() {
      NotificationContentLocalizer.debugIsItalianOverride = true;
    });

    test('ticket modal body preserves subject and status', () {
      final body = NotificationContentLocalizer.localizedTicketBody(
        rawBody:
            'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Attesa.',
        forPush: false,
      );
      expect(body, 'Impianti idraulici e idrici\nStato: In Attesa');
    });

    test('ticket push body uses em dash format', () {
      final localized = NotificationContentLocalizer.localize(
        type: 'support_ticket',
        title: 'Ticket di supporto aggiornato',
        body:
            'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Corso.',
      );
      expect(localized.title, 'Ticket di supporto aggiornato');
      expect(
        localized.body,
        'Impianti idraulici e idrici — Stato: In Corso',
      );
    });

    test('maintenance pending localizes to In Attesa', () {
      final localized = NotificationContentLocalizer.localize(
        type: 'maintenance_residence',
        title: 'Aggiornamento manutenzione',
        body: 'Verifica lucernari - pending',
      );
      expect(localized.title, 'Aggiornamento manutenzione');
      expect(localized.body, 'Verifica lucernari — Stato: In Attesa');
    });

    test('maintenance due formats for modal', () {
      final body = NotificationContentLocalizer.localizedMaintenanceBody(
        rawBody: 'Imbiancatura interni - In Scadenza',
        forPush: false,
      );
      expect(body, 'Imbiancatura interni\nStato: In Scadenza');
    });

    test('maintenance completed formats for modal', () {
      final body = NotificationContentLocalizer.localizedMaintenanceBody(
        rawBody: 'Pulizia muri esterni - Completato',
        forPush: false,
      );
      expect(body, 'Pulizia muri esterni\nStato: Completato');
    });
  });

  group('English display formatting', () {
    setUp(() {
      NotificationContentLocalizer.debugIsItalianOverride = false;
    });

    test('ticket title and status localize to English', () {
      final localized = NotificationContentLocalizer.localize(
        type: 'support_ticket',
        title: 'Ticket di supporto aggiornato',
        body:
            'Il ticket "Impianti idraulici e idrici\n" è stato aggiornato. Stato: In Corso.',
      );
      expect(localized.title, 'Support ticket updated');
      expect(
        localized.body,
        'Impianti idraulici e idrici — Status: In Progress',
      );
    });

    test('maintenance pending stays Pending in English', () {
      final localized = NotificationContentLocalizer.localize(
        type: 'maintenance_residence',
        title: 'Aggiornamento manutenzione',
        body: 'Verifica lucernari - pending',
      );
      expect(localized.title, 'Maintenance update');
      expect(localized.body, 'Verifica lucernari — Status: Pending');
    });

    test('In Attesa normalizes to Pending', () {
      expect(
        NotificationContentLocalizer.localizeNotificationStatus('In Attesa'),
        'Pending',
      );
    });
  });

  group('safe fallbacks', () {
    test('unknown type keeps original title and body', () {
      final localized = NotificationContentLocalizer.localize(
        type: 'announcement',
        title: 'Community note',
        body: 'Welcome to the residence.',
      );
      expect(localized.title, 'Community note');
      expect(localized.body, 'Welcome to the residence.');
    });

    test('empty ticket body does not crash', () {
      NotificationContentLocalizer.debugIsItalianOverride = true;
      final localized = NotificationContentLocalizer.localize(
        type: 'support_ticket',
        title: 'Ticket di supporto aggiornato',
        body: '',
      );
      expect(localized.title, isNotEmpty);
      expect(localized.body, isNotEmpty);
    });

    test('does not replace ticket content with generic when structured', () {
      NotificationContentLocalizer.debugIsItalianOverride = true;
      final body = NotificationContentLocalizer.localizedTicketBody(
        rawBody:
            'Il ticket "Impianti idraulici e idrici" è stato aggiornato. Stato: In Corso.',
        forPush: false,
      );
      expect(body.contains('Il tuo ticket è stato aggiornato'), isFalse);
      expect(body.contains('Impianti idraulici e idrici'), isTrue);
      expect(body.contains('In Corso'), isTrue);
    });
  });
}
