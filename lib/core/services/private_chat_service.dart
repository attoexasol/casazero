import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/private_chat_conversation.dart';
import '../../data/models/private_chat_message.dart';
import '../utils/firebase_error_handler.dart';

/// Firestore operations for private (resident ↔ admin) chat.
class PrivateChatService {
  static const String logTag = 'ConversationService';
  static const String messageLogTag = 'MessageService';
  static const String conversationsCollection = 'conversations';

  final FirebaseFirestore _firestore;

  PrivateChatService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String conversationIdFor({
    required int adminId,
    required int residentId,
  }) {
    return PrivateChatConversation.buildId(
      adminId: adminId,
      residentId: residentId,
    );
  }

  DocumentReference<Map<String, dynamic>> _conversationRef(String id) {
    return _firestore.collection(conversationsCollection).doc(id);
  }

  CollectionReference<Map<String, dynamic>> _messagesRef(String conversationId) {
    return _conversationRef(conversationId).collection('messages');
  }

  String _messagesPath(String conversationId) =>
      '$conversationsCollection/$conversationId/messages';

  /// Returns existing conversation or creates one (never duplicates).
  Future<PrivateChatConversation> getOrCreateConversation({
    required int adminId,
    required int residentId,
    required String residentName,
    required int residenceId,
    required String residenceName,
    required String adminName,
  }) async {
    final id = conversationIdFor(adminId: adminId, residentId: residentId);
    final ref = _conversationRef(id);

    debugPrint('[PrivateChat] Conversation ID: $id');

    try {
      final snap = await ref.get();
      final exists = snap.exists && snap.data() != null;

      debugPrint('[PrivateChat] Conversation Exists: $exists');

      if (exists) {
        debugPrint('[PrivateChat] Conversation Created: false');
        return PrivateChatConversation.fromFirestore(snap);
      }

      final conversation = PrivateChatConversation(
        id: id,
        adminId: adminId,
        residentId: residentId,
        adminName: adminName,
        residentName: residentName,
        residenceId: residenceId,
        residenceName: residenceName,
        participants: [adminId, residentId],
      );

      await ref.set(conversation.toCreateMap());
      debugPrint('[PrivateChat] Conversation Created: true');
      return conversation;
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: logTag,
        error: e,
        firestorePath: '$conversationsCollection/$id',
        conversationId: id,
        userId: residentId.toString(),
      );
      rethrow;
    }
  }

  Stream<List<PrivateChatMessage>> streamMessages(String conversationId) {
    return _resilientStream<List<PrivateChatMessage>>(
      tag: messageLogTag,
      firestorePath: _messagesPath(conversationId),
      conversationId: conversationId,
      factory: () => _messagesRef(conversationId)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(PrivateChatMessage.fromFirestore)
                .toList(),
          ),
    );
  }

  Future<void> sendResidentMessage({
    required String conversationId,
    required int residentId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final batch = _firestore.batch();
    final messageRef = _messagesRef(conversationId).doc();

    batch.set(messageRef, {
      'senderId': residentId,
      'senderType': 'resident',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });

    batch.update(_conversationRef(conversationId), {
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'unreadAdmin': FieldValue.increment(1),
    });

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: messageLogTag,
        error: e,
        firestorePath: _messagesPath(conversationId),
        conversationId: conversationId,
        userId: residentId.toString(),
      );
      rethrow;
    }
  }

  Future<void> markResidentConversationRead({
    required String conversationId,
    required int residentId,
  }) async {
    try {
      final convRef = _conversationRef(conversationId);
      await convRef.update({'unreadResident': 0});

      final unreadAdminMessages = await _messagesRef(conversationId)
          .where('senderType', isEqualTo: 'admin')
          .where('read', isEqualTo: false)
          .get();

      if (unreadAdminMessages.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadAdminMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      FirebaseErrorHandler.log(
        tag: logTag,
        error: e,
        firestorePath: '$conversationsCollection/$conversationId',
        conversationId: conversationId,
        userId: residentId.toString(),
      );
    }
  }

  Stream<T> _resilientStream<T>({
    required String tag,
    required Stream<T> Function() factory,
    String? firestorePath,
    String? conversationId,
    String? userId,
  }) {
    late StreamController<T> controller;
    StreamSubscription<T>? subscription;
    Timer? retryTimer;
    var disposed = false;
    var retryAttempt = 0;

    void logError(Object error) {
      FirebaseErrorHandler.log(
        tag: tag,
        error: error,
        firestorePath: firestorePath,
        conversationId: conversationId,
        userId: userId,
      );
    }

    void cancelRetry() {
      retryTimer?.cancel();
      retryTimer = null;
    }

    void listen() {
      subscription?.cancel();
      cancelRetry();

      subscription = factory().listen(
        (data) {
          retryAttempt = 0;
          if (!controller.isClosed) controller.add(data);
        },
        onError: (Object error) {
          final info = FirebaseErrorHandler.parse(error);
          logError(error);

          if (!info.isRetryable || disposed) {
            if (!controller.isClosed) controller.addError(error);
            return;
          }

          retryAttempt++;
          final delay = Duration(
            seconds: (2 * retryAttempt).clamp(2, 30),
          );
          debugPrint(
            '[$tag] Retrying stream in ${delay.inSeconds}s '
            '(attempt=$retryAttempt code=${info.code})',
          );
          cancelRetry();
          retryTimer = Timer(delay, () {
            if (!disposed) listen();
          });
        },
        cancelOnError: false,
      );
    }

    controller = StreamController<T>(
      onListen: listen,
      onCancel: () async {
        disposed = true;
        cancelRetry();
        await subscription?.cancel();
      },
    );

    return controller.stream;
  }
}
