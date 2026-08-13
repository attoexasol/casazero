import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/repositories/ai_repository.dart';
import '../../../core/controllers/message_popup_controller.dart';

class Message {
  final String? id; // Nullable for pending messages
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? imageUrl; // For future image support
  final int? remainingAiCredit; // AI credits left after this response
  /// When true, [content] is a translation key resolved at display time.
  final bool isTranslationKey;

  Message({
    this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.imageUrl,
    this.remainingAiCredit,
    this.isTranslationKey = false,
  });

  String get displayContent => isTranslationKey ? content.tr : content;

  /// Create message from API response
  factory Message.fromApiResponse({
    required int? chatId,
    required String userMessage,
    String? aiMessage,
    String? image,
    required String createdAt,
    bool isUser = false,
    int? remainingAiCredit,
  }) {
    return Message(
      id: chatId?.toString(),
      role: isUser ? 'user' : 'assistant',
      content: isUser ? userMessage : (aiMessage ?? ''),
      timestamp: Message._parseDateTime(createdAt),
      imageUrl: image,
      remainingAiCredit: remainingAiCredit,
    );
  }

  static DateTime _parseDateTime(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }
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
  final AiRepository _aiRepository = AiRepository();
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // Reactive state
  final RxList<Message> messages = <Message>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isLoadingHistory = false.obs;
  final RxBool showAssistance = true.obs;
  final RxString inputText = ''.obs; // Reactive input text for send button state
  final RxString errorMessage = ''.obs; // Empty string means no error

  @override
  void onInit() {
    super.onInit();
    
    // Listen to input changes for reactive send button state
    inputController.addListener(() {
      inputText.value = inputController.text; // Update reactive variable
    });
    
    // Load chat history on init
    loadChatHistory();
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

  /// Load chat history from API
  Future<void> loadChatHistory() async {
    try {
      isLoadingHistory.value = true;
      errorMessage.value = ''; // Clear error

      print('🤖 [AiController] Loading chat history...');
      final result = await _aiRepository.getMessageHistory();

      if (result['success'] == true) {
        final List<dynamic> historyData = result['data'] ?? [];
        print('📊 [AiController] Received ${historyData.length} chat messages from API');

        // Clear existing messages
        messages.clear();

        // If no history, show greeting message
        if (historyData.isEmpty) {
          messages.add(_greetingMessage());
          showAssistance.value = true;
        } else {
          // Parse and add messages from history
          // Each API item contains both user_message and ai_message
          // We need to create two separate UI messages
          final List<Message> parsedMessages = [];

          for (var item in historyData) {
            final userMsg = item['user_message']?.toString() ?? '';
            final aiMsg = item['ai_message']?.toString();
            final chatId = item['id'];
            final createdAt = item['created_at']?.toString() ?? DateTime.now().toIso8601String();
            final image = item['image'];

            // Add user message
            if (userMsg.isNotEmpty) {
              parsedMessages.add(Message.fromApiResponse(
                chatId: chatId,
                userMessage: userMsg,
                createdAt: createdAt,
                isUser: true,
              ));
            }

            // Add AI message (if exists and not empty/null)
            if (aiMsg != null && aiMsg.isNotEmpty && aiMsg.toLowerCase() != 'no response from ai') {
              parsedMessages.add(Message.fromApiResponse(
                chatId: chatId,
                userMessage: userMsg,
                aiMessage: aiMsg,
                image: image,
                createdAt: createdAt,
                isUser: false,
              ));
            }
          }

          // Sort by timestamp (oldest first)
          parsedMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          messages.addAll(parsedMessages);
          showAssistance.value = messages.length <= 1; // Show assistance only if no chat started

          print('✅ [AiController] Loaded ${messages.length} messages from history');
        }

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          scrollToBottom();
        });
      } else {
        // On error, show greeting message
        final error = result['error'] ?? 'Failed to load chat history';
        errorMessage.value = error;
        messages.add(_greetingMessage());
        showAssistance.value = true;
        print('⚠️ [AiController] Failed to load history: ${errorMessage.value}');
      }
    } catch (e) {
      print('❌ [AiController] Error loading chat history: $e');
      final error = 'Failed to load chat history. Please try again.';
      errorMessage.value = error;
      // Show greeting message on error
      messages.add(_greetingMessage());
      showAssistance.value = true;
    } finally {
      isLoadingHistory.value = false;
    }
  }

  /// Send a message to AI
  Future<void> sendMessage() async {
    final text = inputController.text.trim();
    if (text.isEmpty || isSending.value) return;

    try {
      isSending.value = true;
      errorMessage.value = ''; // Clear error

      // ============================================
      // STEP 1: VALIDATE INPUT IS STRING
      // ============================================
      // Ensure text is a STRING (should always be from TextField, but validate anyway)
      final String messageText;
      if (text is String) {
        messageText = text;
      } else {
        // Force conversion if somehow not a string
        messageText = text.toString();
        print('⚠️ [AiController] WARNING: Input text was not a String, converted: ${text.runtimeType} -> String');
      }

      // Validate message is not empty after conversion
      if (messageText.isEmpty) {
        isSending.value = false;
        return;
      }

      // ============================================
      // STEP 2: OPTIMISTIC UPDATE - ADD USER MESSAGE
      // ============================================
      // Optimistic update: Add user message immediately
      final userMessage = Message(
        id: null, // Will be updated when API responds
        role: 'user',
        content: messageText, // Use validated string
        timestamp: DateTime.now(),
      );

      messages.add(userMessage);
      inputController.clear();
      inputText.value = '';
      showAssistance.value = false;

      // Scroll to bottom after user message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

      // Show thinking indicator
      isLoading.value = true;

      print('🤖 [AiController] Sending message to AI:');
      print('   - Type: ${messageText.runtimeType}');
      print('   - Length: ${messageText.length}');
      print('   - Preview: ${messageText.substring(0, messageText.length > 50 ? 50 : messageText.length)}...');

      // ============================================
      // STEP 3: CALL API WITH VALIDATED STRING
      // ============================================
      // Call API with explicitly validated string
      final result = await _aiRepository.sendMessage(messageText);

      // Remove thinking indicator
      isLoading.value = false;

      if (result['success'] == true) {
        final aiReply = result['reply']?.toString() ?? '';
        final chatId = result['chat_id'];
        final image = result['image'];
        final rawCredit = result['remaining_ai_credit'];
        final remainingAiCredit = rawCredit is int
            ? rawCredit
            : (rawCredit is num ? rawCredit.toInt() : null);

        if (aiReply.isNotEmpty) {
          // Add AI response
          final aiMessage = Message(
            id: chatId?.toString(),
            role: 'assistant',
            content: aiReply,
            timestamp: DateTime.now(),
            imageUrl: image,
            remainingAiCredit: remainingAiCredit,
          );

          messages.add(aiMessage);

          // Update user message ID if we got chat_id
          if (chatId != null && messages.isNotEmpty) {
            final lastUserMsgIndex = messages.lastIndexWhere((m) => m.role == 'user' && m.id == null);
            if (lastUserMsgIndex != -1) {
              messages[lastUserMsgIndex] = Message(
                id: chatId.toString(),
                role: messages[lastUserMsgIndex].role,
                content: messages[lastUserMsgIndex].content,
                timestamp: messages[lastUserMsgIndex].timestamp,
              );
            }
          }

          print('✅ [AiController] AI response received: ${aiReply.substring(0, aiReply.length > 50 ? 50 : aiReply.length)}...');

          // Scroll to bottom after AI response
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
        } else {
          // Empty response - show fallback
          messages.add(Message(
            id: chatId?.toString(),
            role: 'assistant',
            content: 'aiProcessingResponse',
            timestamp: DateTime.now(),
            imageUrl: image,
            remainingAiCredit: remainingAiCredit,
            isTranslationKey: true,
          ));
        }
      } else {
        // API error - show error message
        final error = result['error'] ?? 'Failed to send message. Please try again.';
        errorMessage.value = error;
        
        // Show error popup (use generic error message key)
        MessagePopupController.showError(
          messageKey: 'aiSendError',
          titleKey: 'error',
        );

        print('❌ [AiController] Failed to send message: $error');
      }
    } catch (e) {
      print('❌ [AiController] Error sending message: $e');
      isLoading.value = false;
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      
        MessagePopupController.showError(
          messageKey: 'aiSendError',
          titleKey: 'error',
        );
    } finally {
      isSending.value = false;
    }
  }

  /// Handle prompt click - fill input field
  void handlePromptClick(String prompt) {
    inputController.text = prompt;
    inputText.value = prompt; // Update reactive variable
  }

  Message _greetingMessage() {
    return Message(
      id: null,
      role: 'assistant',
      content: 'aiGreeting',
      timestamp: DateTime.now(),
      isTranslationKey: true,
    );
  }

  /// Get suggested prompts (keys are translated at display time)
  List<SuggestedPrompt> getSuggestedPrompts() {
    return [
      SuggestedPrompt(
        icon: Icons.description,
        text: 'documentLocation',
        category: 'documentsCategory',
      ),
      SuggestedPrompt(
        icon: Icons.build,
        text: 'maintenanceSchedule',
        category: 'maintenanceCategory',
      ),
      SuggestedPrompt(
        icon: Icons.bolt,
        text: 'energyUsage',
        category: 'energyCategory',
      ),
      SuggestedPrompt(
        icon: Icons.description,
        text: 'taxDocuments',
        category: 'documentsCategory',
      ),
    ];
  }

}
