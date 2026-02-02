/// Chat message model matching React ChatMessage structure.
class ChatMessage {
  final String id;
  final String sender;
  final String senderRole; // 'admin' | 'resident'
  final String content;
  final DateTime timestamp;
  final String type; // 'message' | 'announcement'

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.senderRole,
    required this.content,
    required this.timestamp,
    required this.type,
  });
}
