import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/storage_service.dart';

class AiRepository {
  final ApiService _apiService = Get.find();
  final StorageService _storageService = Get.find();

  /// Send a message to AI
  /// POST /casazero-ai/send-message
  /// Request: { "token": "<USER_API_TOKEN>", "message": "<USER_MESSAGE>" }
  /// Response: { "success": true, "chat_id": 10, "reply": "<AI_REPLY>", "image": null }
  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      print('🤖 [AiRepository] Starting sendMessage()...');
      
      final token = _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ [AiRepository] Token is null or empty');
        return {
          'success': false,
          'error': 'User token not found. Please login again.',
        };
      }

      // ============================================
      // STEP 1: VALIDATE AND ENFORCE STRING TYPES
      // ============================================
      // Ensure message is a STRING, not array/object
      final String messageText;
      if (message is String) {
        messageText = message.trim();
      } else {
        // Force conversion to string if somehow not a string
        messageText = message.toString().trim();
        print('⚠️ [AiRepository] WARNING: Message was not a String, converted: ${message.runtimeType} -> String');
      }

      // Ensure token is a STRING
      final String tokenString = token.toString();

      // Validate message is not empty
      if (messageText.isEmpty) {
        print('❌ [AiRepository] Message is empty after trim');
        return {
          'success': false,
          'error': 'Message cannot be empty.',
        };
      }

      // ============================================
      // STEP 2: CREATE PAYLOAD WITH EXPLICIT STRING TYPES
      // ============================================
      // Create request body with EXPLICIT string types
      // This ensures no arrays or objects accidentally get sent
      final Map<String, dynamic> requestBody = <String, dynamic>{
        'token': tokenString,  // Explicitly string
        'message': messageText, // Explicitly string
      };

      // ============================================
      // STEP 3: VALIDATE PAYLOAD BEFORE SENDING
      // ============================================
      // Runtime type checking to catch any issues before API call
      if (requestBody['token'] is! String) {
        print('❌ [AiRepository] CRITICAL: token is not a String! Type: ${requestBody['token'].runtimeType}');
        return {
          'success': false,
          'error': 'Invalid token format.',
        };
      }

      if (requestBody['message'] is! String) {
        print('❌ [AiRepository] CRITICAL: message is not a String! Type: ${requestBody['message'].runtimeType}');
        return {
          'success': false,
          'error': 'Invalid message format.',
        };
      }

      // ============================================
      // STEP 4: LOG PAYLOAD DETAILS FOR DEBUGGING
      // ============================================
      print('═══════════════════════════════════════════════════════════');
      print('📤 [AiRepository] SEND MESSAGE REQUEST');
      print('═══════════════════════════════════════════════════════════');
      print('📡 Endpoint: ${ApiConstants.AI_SEND_MESSAGE}');
      print('🔑 Token type: ${requestBody['token'].runtimeType}');
      print('🔑 Token length: ${tokenString.length}');
      print('💬 Message type: ${requestBody['message'].runtimeType}');
      print('💬 Message length: ${messageText.length}');
      print('💬 Message preview: ${messageText.substring(0, messageText.length > 50 ? 50 : messageText.length)}...');
      print('📦 Request body keys: ${requestBody.keys.toList()}');
      print('✅ Payload validation: PASSED (all fields are strings)');
      print('═══════════════════════════════════════════════════════════');

      // ============================================
      // STEP 5: MAKE API CALL
      // ============================================
      final response = await _apiService.post(
        ApiConstants.AI_SEND_MESSAGE,
        data: requestBody,
      );

      print('✅ [AiRepository] API Response received');
      print('📊 [AiRepository] Status Code: ${response.statusCode}');
      print('📊 [AiRepository] Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // ============================================
        // STEP 6: VALIDATE AND SANITIZE RESPONSE
        // ============================================
        // Ensure reply is a string (not array)
        final dynamic replyRaw = response.data['reply'];
        final String replyText;
        if (replyRaw == null) {
          replyText = '';
        } else if (replyRaw is String) {
          replyText = replyRaw;
        } else if (replyRaw is List) {
          // If backend accidentally returns array, join it
          print('⚠️ [AiRepository] WARNING: Reply is an array, converting to string');
          replyText = replyRaw.join(' ');
        } else {
          replyText = replyRaw.toString();
        }

        // Ensure image is null or string (not array)
        final dynamic imageRaw = response.data['image'];
        final String? imageUrl;
        if (imageRaw == null) {
          imageUrl = null;
        } else if (imageRaw is String) {
          imageUrl = imageRaw;
        } else if (imageRaw is List && imageRaw.isNotEmpty) {
          // If backend returns array, take first element if string
          print('⚠️ [AiRepository] WARNING: Image is an array, taking first element');
          imageUrl = imageRaw.first is String ? imageRaw.first as String : null;
        } else {
          imageUrl = imageRaw.toString();
        }

        // Ensure chat_id is int or null
        final dynamic chatIdRaw = response.data['chat_id'];
        final int? chatId;
        if (chatIdRaw == null) {
          chatId = null;
        } else if (chatIdRaw is int) {
          chatId = chatIdRaw;
        } else if (chatIdRaw is String) {
          chatId = int.tryParse(chatIdRaw);
        } else {
          chatId = null;
        }

        // Extract remaining_ai_credit (int or null)
        final dynamic remainingCreditRaw = response.data['remaining_ai_credit'];
        final int? remainingAiCredit;
        if (remainingCreditRaw == null) {
          remainingAiCredit = null;
        } else if (remainingCreditRaw is int) {
          remainingAiCredit = remainingCreditRaw;
        } else if (remainingCreditRaw is num) {
          remainingAiCredit = remainingCreditRaw.toInt();
        } else {
          remainingAiCredit = int.tryParse(remainingCreditRaw.toString());
        }

        print('✅ [AiRepository] Response validated:');
        print('   - chat_id: $chatId (type: ${chatId.runtimeType})');
        print('   - reply: ${replyText.length} chars (type: ${replyText.runtimeType})');
        print('   - image: ${imageUrl ?? 'null'} (type: ${imageUrl?.runtimeType ?? 'null'})');
        print('   - remaining_ai_credit: $remainingAiCredit (type: ${remainingAiCredit.runtimeType})');

        return {
          'success': true,
          'chat_id': chatId,
          'reply': replyText,
          'image': imageUrl,
          'remaining_ai_credit': remainingAiCredit,
        };
      } else {
        // Extract error message from various possible response formats
        String errorMessage = 'Failed to send message. Please try again.';
        
        if (response.data is Map) {
          errorMessage = response.data['message'] ?? 
                        response.data['error'] ?? 
                        response.data['errors']?.toString() ??
                        errorMessage;
        } else if (response.data is String) {
          errorMessage = response.data as String;
        }
        
        print('❌ [AiRepository] API returned error: $errorMessage');
        print('📊 [AiRepository] Full response data: ${response.data}');
        return {
          'success': false,
          'error': errorMessage,
        };
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [AiRepository] DioException in sendMessage: $e');
      print('📚 [AiRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to send message. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        
        if (responseData is Map) {
          errorMessage = responseData['message'] ?? 
                        responseData['error'] ?? 
                        responseData['errors']?.toString() ??
                        errorMessage;
        } else if (responseData is String) {
          // Check if it's a database error or similar
          if (responseData.contains('Array to string conversion') ||
              responseData.contains('SQL') ||
              responseData.contains('database')) {
            errorMessage = 'Server error occurred. Please try again later.';
          } else {
            errorMessage = responseData;
          }
        }
        
        print('📊 [AiRepository] Error response data: $responseData');
        print('📊 [AiRepository] Extracted error message: $errorMessage');
      } else {
        // Network or connection error
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Connection error. Please check your internet connection.';
        }
      }

      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ [AiRepository] Error in sendMessage: $e');
      
      // Try to extract error message from exception
      String errorMessage = 'An unexpected error occurred. Please try again.';
      final errorString = e.toString();
      
      // Check if error contains useful information
      if (errorString.contains('Array to string conversion') || 
          errorString.contains('SQL') ||
          errorString.contains('database')) {
        errorMessage = 'Server error occurred. Please try again later.';
      } else if (errorString.isNotEmpty) {
        // Try to extract meaningful error from exception
        final match = RegExp(r'(message|error|exception):\s*(.+?)(?:\n|$)').firstMatch(errorString);
        if (match != null && match.group(2) != null) {
          errorMessage = match.group(2)!.trim();
        }
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    }
  }

  /// Get AI message history
  /// POST /casazero-ai/get-message
  /// Request: { "token": "<USER_API_TOKEN>" }
  /// Response: { "success": true, "data": { "data": [...] } }
  Future<Map<String, dynamic>> getMessageHistory() async {
    try {
      print('🤖 [AiRepository] Starting getMessageHistory()...');
      
      final token = _storageService.getAccessToken();
      if (token == null || token.isEmpty) {
        print('❌ [AiRepository] Token is null or empty');
        return {
          'success': false,
          'error': 'User token not found. Please login again.',
          'data': [],
        };
      }

      print('📡 [AiRepository] Making POST request to: ${ApiConstants.AI_GET_MESSAGE_HISTORY}');
      print('📦 [AiRepository] Request data: {"token": "${token.substring(0, 10)}..."}');

      final response = await _apiService.post(
        ApiConstants.AI_GET_MESSAGE_HISTORY,
        data: {
          'token': token,
        },
      );

      print('✅ [AiRepository] API Response received');
      print('📊 [AiRepository] Status Code: ${response.statusCode}');
      print('📊 [AiRepository] Response Data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Extract data array from nested structure: response.data.data.data
        final data = response.data['data'];
        final messagesData = data is Map && data['data'] != null 
            ? data['data'] as List<dynamic>
            : (data is List ? data : []);
        
        print('📊 [AiRepository] Parsing ${messagesData.length} chat messages');
        
        return {
          'success': true,
          'data': messagesData,
        };
      } else {
        final errorMessage = response.data['message'] ?? 
                            response.data['error'] ?? 
                            'Failed to load chat history. Please try again.';
        print('❌ [AiRepository] API returned error: $errorMessage');
        return {
          'success': false,
          'error': errorMessage,
          'data': [],
        };
      }
    } on DioException catch (e, stackTrace) {
      print('❌ [AiRepository] DioException in getMessageHistory: $e');
      print('📚 [AiRepository] Stack trace: $stackTrace');

      String errorMessage = 'Failed to load chat history. Please try again.';
      if (e.response != null && e.response!.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map) {
          errorMessage = responseData['message'] ?? 
                        responseData['error'] ?? 
                        errorMessage;
        }
        print('📊 [AiRepository] Error response data: $responseData');
      }

      return {
        'success': false,
        'error': errorMessage,
        'data': [],
      };
    } catch (e) {
      print('❌ [AiRepository] Error in getMessageHistory: $e');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
        'data': [],
      };
    }
  }
}
