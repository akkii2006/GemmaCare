class AppConstants {
  AppConstants._();


  static const String googleMapsApiKey = 'Google api key with maps, place and geocode enabled!';
  static const String huggingFaceApiKey = 'Paste your Hugging Face API key here';
  static const String geminiApiKey = 'Paste your gemini api key here';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  static const String serperApiKey = 'Paste your serper api key here';

  // Models
  static const String remoteModelId = 'gemma-4-31b-it';
  static const String careModelId = 'gemini-2.5-flash-lite';
  static const String localModelFileName = 'gemma-4-E4B-it.litertlm';
  static const String modelDownloadUrl =
      'https://huggingface.co/litert-community/gemma-4-E4B-it-litert-lm/resolve/main/gemma-4-E4B-it.litertlm';

  // HuggingFace API
  static const String hfApiBaseUrl = 'https://api-inference.huggingface.co/models';
  static const String hfChatEndpoint = 'https://router.huggingface.co/v1/chat/completions';

  // Overpass API
  static const String overpassApiUrl = 'https://overpass-api.de/api/interpreter';

  // Google Places
  static const String placesApiUrl = 'https://maps.googleapis.com/maps/api/place';

  // Search radius in meters
  static const int searchRadiusMeters = 10000;
  static const List<int> radiusOptions = [2000, 5000, 10000, 20000, 50000];

  // Max tokens for remote model
  static const int maxTokensRemote = 1024;
  static const int maxTokensLocal = 512;

  // DB
  static const String dbName = 'gemmacare.db';
  static const int dbVersion = 1;
}
