import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';

class ModelDownloadService {
  final Dio _dio = Dio();

  Future<String> getModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.localModelFileName}';
  }

  Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    return File(path).existsSync();
  }

  Future<void> downloadModel({
    required void Function(double progress) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    try {
      final savePath = await getModelPath();

      await _dio.download(
        AppConstants.modelDownloadUrl,
        savePath,
        options: Options(
          headers: {'Authorization': 'Bearer ${AppConstants.huggingFaceApiKey}'},
        ),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            onProgress(received / total);
          }
        },
      );

      onComplete();
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> deleteModel() async {
    final path = await getModelPath();
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
