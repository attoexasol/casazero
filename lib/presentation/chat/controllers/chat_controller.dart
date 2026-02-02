import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/chat_message_model.dart';

class ChatController extends GetxController {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final RxList<ChatMessage> messages = <ChatMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialMessages();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void onClose() {
    messageController.removeListener(_onMessageChanged);
    messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void _onMessageChanged() => update(['input']);

  void _loadInitialMessages() {
    final nov1 = DateTime(2025, 11, 1);
    final nov2 = DateTime(2025, 11, 2);
    messages.addAll([
      ChatMessage(
        id: '1',
        sender: 'Building Administrator',
        senderRole: 'admin',
        content:
            'Important: Elevator maintenance scheduled for November 8-9. Please use the stairs during this period.',
        timestamp: nov1,
        type: 'announcement',
      ),
      ChatMessage(
        id: '2',
        sender: 'Marco R.',
        senderRole: 'resident',
        content: 'Will the water be shut off during the maintenance?',
        timestamp: DateTime(2025, 11, 1, 11, 15),
        type: 'message',
      ),
      ChatMessage(
        id: '3',
        sender: 'Building Administrator',
        senderRole: 'admin',
        content:
            'No, only elevator service will be affected. Water and all other utilities will operate normally.',
        timestamp: DateTime(2025, 11, 1, 11, 20),
        type: 'message',
      ),
      ChatMessage(
        id: '4',
        sender: 'Sofia M.',
        senderRole: 'resident',
        content: 'Thank you for the update!',
        timestamp: DateTime(2025, 11, 1, 14, 45),
        type: 'message',
      ),
      ChatMessage(
        id: '5',
        sender: 'Building Administrator',
        senderRole: 'admin',
        content:
            'Reminder: Monthly condominium meeting this Friday at 6 PM in the community room.',
        timestamp: nov2,
        type: 'announcement',
      ),
      ChatMessage(
        id: '6',
        sender: 'Luca P.',
        senderRole: 'resident',
        content: 'Can we join online?',
        timestamp: DateTime(2025, 11, 2, 9, 30),
        type: 'message',
      ),
    ]);
  }

  String formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  void handleSend() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    messages.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: 'You',
      senderRole: 'resident',
      content: text,
      timestamp: DateTime.now(),
      type: 'message',
    ));
    messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool get hasMessageText => messageController.text.trim().isNotEmpty;
}
