import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class GemmaRemoteService {
  static final _client = http.Client();
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  String _endpoint(String model) =>
      '$_baseUrl/$model:generateContent?key=${AppConstants.geminiApiKey}';

  String _extractText(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) throw Exception('No candidates in response');
    final parts = (candidates[0]['content']['parts'] as List<dynamic>? ?? []);
    for (final part in parts) {
      if (part['thought'] != true) {
        return (part['text'] ?? '') as String;
      }
    }
    return '';
  }

  Future<String> chat({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    String? model,
  }) async {
    final useModel = model ?? AppConstants.remoteModelId;
    final contents = messages.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content']}],
    }).toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': AppConstants.maxTokensRemote,
        'temperature': 0.7,
      },
    });

    final response = await _client.post(
      Uri.parse(_endpoint(useModel)),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return _extractText(jsonDecode(response.body));
    } else {
      throw Exception('Gemini error: ${response.statusCode} ${response.body}');
    }
  }

  /// Stream chat response token by token
  Stream<String> chatStream({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    String? model,
  }) async* {
    final useModel = model ?? AppConstants.remoteModelId;
    final contents = messages.map((m) => {
      'role': m['role'] == 'assistant' ? 'model' : 'user',
      'parts': [{'text': m['content']}],
    }).toList();

    final body = jsonEncode({
      'system_instruction': {
        'parts': [{'text': systemPrompt}]
      },
      'contents': contents,
      'generationConfig': {
        'maxOutputTokens': AppConstants.maxTokensRemote,
        'temperature': 0.7,
      },
    });

    final request = http.Request(
      'POST',
      Uri.parse(_endpoint(useModel).replaceAll(':generateContent', ':streamGenerateContent') + '&alt=sse'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = body;

    final streamedResponse = await _client.send(request)
        .timeout(const Duration(seconds: 120));

    await for (final chunk in streamedResponse.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final jsonStr = chunk.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
        try {
          final data = jsonDecode(jsonStr);
          final parts = (data['candidates']?[0]?['content']?['parts'] as List?) ?? [];
          for (final part in parts) {
            if (part['thought'] != true) {
              final text = (part['text'] ?? '') as String;
              if (text.isNotEmpty) yield text;
            }
          }
        } catch (_) {}
      }
    }
  }

  /// Stream image analysis token by token
  Stream<String> analyzeImageStream({
    required String systemPrompt,
    required String base64Image,
    required String mimeType,
    String? model,
  }) async* {
    final useModel = model ?? AppConstants.remoteModelId;

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': systemPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            },
          ],
        }
      ],
      'generationConfig': {
        'maxOutputTokens': AppConstants.maxTokensRemote,
      },
    });

    final request = http.Request(
      'POST',
      Uri.parse(_endpoint(useModel).replaceAll(':generateContent', ':streamGenerateContent') + '&alt=sse'),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = body;

    final streamedResponse = await _client.send(request)
        .timeout(const Duration(seconds: 120));

    await for (final chunk in streamedResponse.stream
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final jsonStr = chunk.substring(6).trim();
        if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
        try {
          final data = jsonDecode(jsonStr);
          final parts = (data['candidates']?[0]?['content']?['parts'] as List?) ?? [];
          for (final part in parts) {
            if (part['thought'] != true) {
              final text = (part['text'] ?? '') as String;
              if (text.isNotEmpty) yield text;
            }
          }
        } catch (_) {}
      }
    }
  }

  Future<String> analyzeImage({
    required String systemPrompt,
    required String base64Image,
    required String mimeType,
    String? model,
  }) async {
    final useModel = model ?? AppConstants.remoteModelId;
    // gemma models don't support system_instruction - embed in user message
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': systemPrompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            },
          ],
        }
      ],
      'generationConfig': {
        'maxOutputTokens': AppConstants.maxTokensRemote,
      },
    });

    final response = await _client.post(
      Uri.parse(_endpoint(useModel)),
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      return _extractText(jsonDecode(response.body));
    } else {
      throw Exception('Gemini error: ${response.statusCode} ${response.body}');
    }
  }
}
