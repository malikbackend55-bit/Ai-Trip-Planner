import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_service.dart';
import 'app_localization.dart';
import 'language_provider.dart';

class ChatMessage {
  final String text;
  final bool isAi;

  ChatMessage({required this.text, required this.isAi});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier(this._apiService) : super([]) {
    _seedGreeting();
  }

  final ApiService _apiService;
  bool isTyping = false;

  void _seedGreeting() {
    state = [
      ChatMessage(
        text: AppStrings.current.tr('chat.initialGreeting'),
        isAi: true,
      ),
    ];
  }

  void resetConversation() {
    isTyping = false;
    _seedGreeting();
  }

  Future<void> sendMessage(
    String text, {
    Map<String, dynamic>? contextData,
  }) async {
    if (text.trim().isEmpty) return;

    state = [...state, ChatMessage(text: text, isAi: false)];
    isTyping = true;
    state = [...state];

    try {
      final context = <String, dynamic>{
        ...?contextData,
        'language': AppStrings.current.languageCode,
      };

      final response = await _apiService.sendChat(text, context: context);

      if (response.statusCode == 200 && response.data['status'] == 'success') {
        isTyping = false;
        state = [
          ...state,
          ChatMessage(text: response.data['message'], isAi: true),
        ];
      } else {
        throw Exception(AppStrings.current.tr('chat.failedResponse'));
      }
    } catch (error) {
      debugPrint('Error sending message: $error');
      isTyping = false;
      state = [
        ...state,
        ChatMessage(text: _buildErrorMessage(error), isAi: true),
      ];
    }
  }

  String _buildErrorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 401) {
        return AppStrings.current.tr('chat.sessionExpired');
      }

      final serverData = error.response?.data;
      if (serverData is Map<String, dynamic>) {
        final message = serverData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return AppStrings.current.tr(
            'chat.serverError',
            params: {'message': message},
          );
        }
      }

      if (error.response?.statusCode != null) {
        return AppStrings.current.tr(
          'chat.serverStatusError',
          params: {
            'status': '${error.response!.statusCode}',
            'url': ApiService.baseUrl,
          },
        );
      }
    }

    return AppStrings.current.tr(
      'chat.connectionError',
      params: {'url': ApiService.baseUrl},
    );
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  ref.watch(languageProvider);
  return ChatNotifier(ApiService());
});
