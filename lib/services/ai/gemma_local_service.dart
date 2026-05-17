import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';

class GemmaLocalService {
  static const MethodChannel _methodChannel =
  MethodChannel('com.example.gemma_care/litert');

  static const EventChannel _eventChannel =
  EventChannel('com.example.gemma_care/litert_stream');

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  StreamSubscription? _streamSubscription;

  Future<String> get modelPath async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.localModelFileName}';
  }

  Future<bool> get isModelAvailable async {
    final path = await modelPath;
    return File(path).existsSync();
  }

  Future<void> loadModel() async {
    if (_isLoaded) return;

    final available = await isModelAvailable;
    if (!available) {
      throw Exception('Model file not found. Please download it first.');
    }

    final path = await modelPath;

    print('==============================');
    print('Loading LiteRT model');
    print('Model path: $path');

    try {
      final success = await _methodChannel.invokeMethod<bool>(
        'loadModel',
        {'modelPath': path},
      );

      if (success == true) {
        _isLoaded = true;
        print('Load success: true');
      } else {
        throw Exception('Failed to load model');
      }
    } on PlatformException catch (e) {
      print('LOAD ERROR: ${e.message}');
      throw Exception('LiteRT load error: ${e.message}');
    }
  }

  /// Stream chat response token by token
  Future<void> chatStreaming({
    required String systemPrompt,
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    if (!_isLoaded) await loadModel();

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    print('==============================');
    print('Starting chat stream');

    final completer = Completer<void>();

    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        final token = event as String;
        if (token == '__DONE__') {
          onDone();
          if (!completer.isCompleted) completer.complete();
        } else {
          onToken(token);
        }
      },
      onError: (dynamic error) {
        final msg = error is PlatformException
            ? error.message ?? 'Unknown error'
            : error.toString();
        onError(msg);
        if (!completer.isCompleted) completer.completeError(msg);
      },
      cancelOnError: true,
    );

    try {
      await _methodChannel.invokeMethod('startChatStream', {
        'systemPrompt': systemPrompt,
        'messages': messages,
      });
    } on PlatformException catch (e) {
      onError(e.message ?? 'Failed to start stream');
      return;
    }

    await completer.future;
  }

  /// Stream single image analysis token by token
  Future<void> imageStreaming({
    required String prompt,
    required String imagePath,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    if (!_isLoaded) await loadModel();

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    print('==============================');
    print('Starting image stream: $imagePath');

    final completer = Completer<void>();

    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        final token = event as String;
        if (token == '__DONE__') {
          onDone();
          if (!completer.isCompleted) completer.complete();
        } else {
          onToken(token);
        }
      },
      onError: (dynamic error) {
        final msg = error is PlatformException
            ? error.message ?? 'Unknown error'
            : error.toString();
        onError(msg);
        if (!completer.isCompleted) completer.completeError(msg);
      },
      cancelOnError: true,
    );

    try {
      await _methodChannel.invokeMethod('startImageStream', {
        'prompt': prompt,
        'imagePath': imagePath,
      });
    } on PlatformException catch (e) {
      onError(e.message ?? 'Failed to start image stream');
      return;
    }

    await completer.future;
  }

  /// Stream multi-image (PDF pages) analysis — all pages sent at once
  Future<void> imageListStreaming({
    required String prompt,
    required List<String> imagePaths,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    if (!_isLoaded) await loadModel();

    await _streamSubscription?.cancel();
    _streamSubscription = null;

    print('==============================');
    print('Starting multi-image stream: ${imagePaths.length} pages');

    final completer = Completer<void>();

    _streamSubscription = _eventChannel.receiveBroadcastStream().listen(
          (dynamic event) {
        final token = event as String;
        if (token == '__DONE__') {
          onDone();
          if (!completer.isCompleted) completer.complete();
        } else {
          onToken(token);
        }
      },
      onError: (dynamic error) {
        final msg = error is PlatformException
            ? error.message ?? 'Unknown error'
            : error.toString();
        onError(msg);
        if (!completer.isCompleted) completer.completeError(msg);
      },
      cancelOnError: true,
    );

    try {
      await _methodChannel.invokeMethod('startImageListStream', {
        'prompt': prompt,
        'imagePaths': imagePaths,
      });
    } on PlatformException catch (e) {
      onError(e.message ?? 'Failed to start multi-image stream');
      return;
    }

    await completer.future;
  }

  /// Non-streaming image analysis (kept for compatibility)
  Future<String> analyzeImage({
    required String prompt,
    required String imagePath,
  }) async {
    if (!_isLoaded) await loadModel();

    print('==============================');
    print('Running image inference (blocking)');

    try {
      final response = await _methodChannel.invokeMethod<String>(
        'runImageInference',
        {'prompt': prompt, 'imagePath': imagePath},
      );
      return response ?? 'No response from model.';
    } on PlatformException catch (e) {
      throw Exception('Image inference error: ${e.message}');
    }
  }

  Future<void> clearConversationCache() async {
    try {
      await _methodChannel.invokeMethod('clearConversationCache');
    } catch (_) {}
  }

  Future<void> unload() async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    try {
      await _methodChannel.invokeMethod('unloadModel');
      _isLoaded = false;
    } catch (_) {}
  }
}

extension on String {
  String take(int n) => length <= n ? this : substring(0, n);
}