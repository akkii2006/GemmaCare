import 'package:flutter/material.dart';
import '../services/model_download_service.dart';
import '../data/local/preferences/app_preferences.dart';

class ModelDownloadProvider extends ChangeNotifier {
  final ModelDownloadService _service = ModelDownloadService();

  double _progress = 0;
  bool _isDownloading = false;
  bool _isDownloaded = false;
  String? _error;

  double get progress => _progress;
  bool get isDownloading => _isDownloading;
  bool get isDownloaded => _isDownloaded;
  String? get error => _error;

  Future<void> checkDownloaded() async {
    _isDownloaded = await _service.isModelDownloaded();
    notifyListeners();
  }

  Future<void> startDownload() async {
    _isDownloading = true;
    _progress = 0;
    _error = null;
    notifyListeners();

    await _service.downloadModel(
      onProgress: (p) {
        _progress = p;
        notifyListeners();
      },
      onComplete: () async {
        _isDownloaded = true;
        _isDownloading = false;
        final prefs = await AppPreferences.getInstance();
        await prefs.setModelDownloaded(true);
        notifyListeners();
      },
      onError: (e) {
        _error = e;
        _isDownloading = false;
        notifyListeners();
      },
    );
  }
}
