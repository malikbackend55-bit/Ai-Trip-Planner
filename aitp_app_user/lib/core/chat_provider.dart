import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'api_service.dart';

class ChatMessage {
  final String text;
  final bool isAi;

  ChatMessage({required this.text, required this.isAi});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ApiService _apiService;
  bool isTyping = false;

  ChatNotifier(this._apiService) : super([]) {
    // Add initial greeting
    state = [
      ChatMessage(
        text:
            'Hey! I\'m your AI travel assistant 🌍 Tell me where you\'d like to go and I\'ll plan the perfect trip!',
        isAi: true,
      ),
    ];
  }

  Future<void> sendMessage(
    String text, {
    Map<String, dynamic>? contextData,
  }) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message to UI immediately
    state = [...state, ChatMessage(text: text, isAi: false)];
    isTyping = true;
    state = [...state];

    try {
      // The ApiService handles the Authorization header automatically via its interceptor,
      // but we explicitly pass it here for safety or we can rely on the interceptor.
      // Let's rely on the ApiService's dio instance.
      final response = await _apiService.dio.post(
        '/chat',
        data: {'message': text, 'context': contextData},
      );

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final aiMessage = response.data['message'];
        isTyping = false;
        state = [...state, ChatMessage(text: aiMessage, isAi: true)];
      } else {
        throw Exception('Failed to get response');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      isTyping = false;
      state = [...state, ChatMessage(text: _buildErrorMessage(e), isAi: true)];
    }
  }

  String _buildErrorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return 'Your session expired. Please log in again and resend the message.';
      }

      final serverData = error.response?.data;
      if (serverData is Map<String, dynamic>) {
        final message = serverData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return 'Server error: $message';
        }
      }

      if (error.response?.statusCode != null) {
        return 'Server error (${error.response!.statusCode}) while contacting ${ApiService.baseUrl}.';
      }
    }

    return 'Sorry, I am having trouble connecting to ${ApiService.baseUrl}. Please try again.';
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  final apiService =
      ApiService(); // Instantiate directly as there's no provider for it
  return ChatNotifier(apiService);
});
