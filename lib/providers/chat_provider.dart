// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../data/models/chat_message_model.dart';
import '../data/models/user_profile_model.dart';
import '../services/ai/model_router.dart';
import '../core/constants/prompt_constants.dart';

class ChatProvider extends ChangeNotifier {
  final ModelRouter _router = ModelRouter();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;
  bool _isStreaming = false;
  String? _currentMode;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isStreaming => _isStreaming;
  String? get currentMode => _currentMode;

  void setMode(String mode) {
    if (_currentMode != mode) {
      _messages.clear();
      _error = null;
      _isLoading = false;
      _isStreaming = false;
      _currentMode = mode;
      _router.clearLocalConversation();
      notifyListeners();
    }
  }

  Future<void> sendMessage(
      String mode,
      String text, {
        UserProfile? profile,
      }) async {
    if (text.trim().isEmpty) return;

    if (_currentMode != mode) setMode(mode);

    _error = null;
    _messages.add(ChatMessage.user(text));
    _isLoading = true;
    _isStreaming = false;
    notifyListeners();

    _messages.add(ChatMessage.assistant(''));

    // Pass profile so system prompt is personalised
    final systemPrompt = PromptConstants.chatSystemPrompt(
      mode,
      profile: profile,
    );

    final history = _messages
        .where((m) => !m.isLoading && (m.isUser || m.content.isNotEmpty))
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    await _router.chatStreaming(
      systemPrompt: systemPrompt,
      messages: history,
      onToken: (token) {
        _isStreaming = true;
        _isLoading = false;
        final last = _messages.last;
        _messages[_messages.length - 1] = last.copyWith(
          content: last.content + token,
        );
        notifyListeners();
      },
      onDone: () {
        _isStreaming = false;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isStreaming = false;
        _isLoading = false;
        _error = error;
        if (_messages.isNotEmpty && _messages.last.content.isEmpty) {
          _messages.removeLast();
        }
        notifyListeners();
      },
    );
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    _isLoading = false;
    _isStreaming = false;
    _router.clearLocalConversation();
    notifyListeners();
  }
}