import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/theme/app_colors.dart';

class Message {
  final String id;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class Ticket {
  final String id;
  final String subject;
  final String status; // 'open', 'in-progress', 'resolved'
  final String date;
  final String category;

  Ticket({
    required this.id,
    required this.subject,
    required this.status,
    required this.date,
    required this.category,
  });
}

class SuggestedPrompt {
  final IconData icon;
  final String text;
  final String category;

  SuggestedPrompt({
    required this.icon,
    required this.text,
    required this.category,
  });
}

class AiController extends GetxController {
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Reactive state
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool showAssistance = true.obs;
  final RxString inputText = ''.obs; // Reactive input text for send button state

  @override
  void onInit() {
    super.onInit();
    // Initialize with greeting message
    messages.add(Message(
      id: '1',
      role: 'assistant',
      content: 'aiGreeting'.tr,
      timestamp: DateTime.now(),
    ));
    
    // Listen to input changes for reactive send button state
    inputController.addListener(() {
      inputText.value = inputController.text; // Update reactive variable
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Scroll to bottom of chat
  void scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Send a message
  void sendMessage() {
    final text = inputController.text.trim();
    if (text.isEmpty) return;

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    messages.add(userMessage);
    inputController.clear();
    inputText.value = ''; // Clear reactive variable
    showAssistance.value = false;
    isLoading.value = true;
    
    // Scroll to bottom after message is added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });

    // TODO: Replace mock AI response with API integration
    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      final aiMessage = Message(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: 'assistant',
        content: 'aiMockResponse'.tr.replaceAll('{input}', text),
        timestamp: DateTime.now(),
      );

      messages.add(aiMessage);
      isLoading.value = false;
      
      // Scroll to bottom after AI response is added
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    });
  }

  /// Handle prompt click - fill input field
  void handlePromptClick(String prompt) {
    inputController.text = prompt;
  }

  /// Get suggested prompts
  List<SuggestedPrompt> getSuggestedPrompts() {
    return [
      SuggestedPrompt(
        icon: Icons.description,
        text: 'documentLocation'.tr,
        category: 'Documenti',
      ),
      SuggestedPrompt(
        icon: Icons.build,
        text: 'maintenanceSchedule'.tr,
        category: 'Manutenzione',
      ),
      SuggestedPrompt(
        icon: Icons.bolt,
        text: 'energyUsage'.tr,
        category: 'Energia',
      ),
      SuggestedPrompt(
        icon: Icons.description,
        text: 'taxDocuments'.tr,
        category: 'Documenti',
      ),
    ];
  }

  /// Get recent tickets
  List<Ticket> getRecentTickets() {
    return [
      Ticket(
        id: 'T-001',
        subject: 'ticketNoiseSubject'.tr,
        status: 'in-progress',
        date: '2 Nov 2025',
        category: 'Disturbo',
      ),
      Ticket(
        id: 'T-002',
        subject: 'ticketWaterLeakSubject'.tr,
        status: 'resolved',
        date: '28 Ott 2025',
        category: 'Idraulica',
      ),
    ];
  }

  /// Get status color for ticket badge
  Color getStatusColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning.withOpacity(0.1);
      case 'in-progress':
        return AppColors.info.withOpacity(0.1);
      case 'resolved':
        return AppColors.success.withOpacity(0.1);
      default:
        return AppColors.neutralLine100;
    }
  }

  /// Get status text color for ticket badge
  Color getStatusTextColor(String status) {
    switch (status) {
      case 'open':
        return AppColors.warning;
      case 'in-progress':
        return AppColors.info;
      case 'resolved':
        return AppColors.success;
      default:
        return AppColors.neutralInk700;
    }
  }

  /// Get status text
  String getStatusText(String status) {
    switch (status) {
      case 'open':
        return 'statusOpen'.tr;
      case 'in-progress':
        return 'statusInProgress'.tr;
      case 'resolved':
        return 'statusResolved'.tr;
      default:
        return status;
    }
  }
}
