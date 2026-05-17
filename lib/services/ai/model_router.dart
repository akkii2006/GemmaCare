import 'gemma_local_service.dart';
import 'gemma_remote_service.dart';

enum ModelType { local, remote }

class ModelRouter {
  final GemmaLocalService _local = GemmaLocalService();
  final GemmaRemoteService _remote = GemmaRemoteService();

  bool privacyMode = false;

  ModelType routeFor(String task) {
    if (privacyMode) return ModelType.local;
    final complexKeywords = ['xray', 'x-ray', 'mri', 'ct scan', 'ecg', 'complex', 'analyze image'];
    final taskLower = task.toLowerCase();
    if (complexKeywords.any((k) => taskLower.contains(k))) {
      return ModelType.remote;
    }
    return ModelType.local;
  }

  void clearLocalConversation() {
    _local.clearConversationCache();
  }
  Future<void> chatStreaming({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(String error) onError,
    ModelType? forceModel,
  }) async {
    final model = forceModel ?? routeFor(messages.last['content'] ?? '');

    if (model == ModelType.local) {
      try {
        await _local.chatStreaming(
          systemPrompt: systemPrompt,
          messages: messages,
          onToken: onToken,
          onDone: onDone,
          onError: onError,
        );
      } catch (e) {
        try {
          final response = await _remote.chat(
            systemPrompt: systemPrompt,
            messages: messages,
          );
          for (final word in response.split(' ')) {
            onToken('$word ');
            await Future.delayed(const Duration(milliseconds: 10));
          }
          onDone();
        } catch (e2) {
          onError(e2.toString());
        }
      }
    } else {
      try {
        final response = await _remote.chat(
          systemPrompt: systemPrompt,
          messages: messages,
        );
        for (final word in response.split(' ')) {
          onToken('$word ');
          await Future.delayed(const Duration(milliseconds: 10));
        }
        onDone();
      } catch (e) {
        onError(e.toString());
      }
    }
  }

  Future<String> analyzeImage({
    required String systemPrompt,
    required String base64Image,
    required String mimeType,
  }) async {
    if (privacyMode) {
      final buffer = StringBuffer();
      await _local.chatStreaming(
        systemPrompt: systemPrompt,
        messages: [{'role': 'user', 'content': 'Analyze this medical document.'}],
        onToken: (t) => buffer.write(t),
        onDone: () {},
        onError: (_) {},
      );
      return buffer.toString();
    }
    return await _remote.analyzeImage(
      systemPrompt: systemPrompt,
      base64Image: base64Image,
      mimeType: mimeType,
    );
  }
}
