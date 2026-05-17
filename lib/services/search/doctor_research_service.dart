import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/constants/prompt_constants.dart';
import '../../data/models/doctor_model.dart';

class DoctorResearchService {
  /// Searches for top doctors in a city using Google Custom Search
  /// and synthesizes results using the remote AI model.
  Future<List<Doctor>> researchDoctors({
    required String specialty,
    required String city,
    required double lat,
    required double lng,
  }) async {
    final searchResults = await _webSearch('best $specialty doctor in $city India reviews');
    final synthesized = await _synthesizeResults(
      specialty: specialty,
      city: city,
      searchResults: searchResults,
    );
    return _parseDoctors(synthesized, lat, lng);
  }

  Future<String> _webSearch(String query) async {
    // Using Google Custom Search API
    final url = Uri.parse(
      'https://www.googleapis.com/customsearch/v1'
      '?key=${AppConstants.googleMapsApiKey}'
      '&cx=017576662512468239146:omuauf10dwe'
      '&q=${Uri.encodeComponent(query)}'
      '&num=10',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((i) => '${i['title']}: ${i['snippet']}').join('\n');
      }
    } catch (_) {}
    return '';
  }

  Future<String> _synthesizeResults({
    required String specialty,
    required String city,
    required String searchResults,
  }) async {
    if (searchResults.isEmpty) return '';

    final prompt = PromptConstants.doctorResearchPrompt(specialty, city);
    final body = jsonEncode({
      'model': AppConstants.remoteModelId,
      'messages': [
        {'role': 'system', 'content': prompt},
        {'role': 'user', 'content': 'Search results:\n$searchResults\n\nProvide structured JSON list of top 5 doctors.'},
      ],
      'max_tokens': AppConstants.maxTokensRemote,
    });

    final response = await http.post(
      Uri.parse(AppConstants.hfChatEndpoint),
      headers: {
        'Authorization': 'Bearer ${AppConstants.huggingFaceApiKey}',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String;
    }
    return '';
  }

  List<Doctor> _parseDoctors(String aiResponse, double lat, double lng) {
    if (aiResponse.isEmpty) return [];

    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(aiResponse);
      if (jsonMatch == null) return [];

      final list = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
      return list.map((d) {
        return Doctor(
          name: d['name'] ?? '',
          specialty: d['specialty'] ?? '',
          hospital: d['hospital'] ?? '',
          address: d['address'] ?? '',
          latitude: lat,
          longitude: lng,
          rating: (d['rating'] ?? 4.5).toDouble(),
          reviewCount: d['reviewCount'] ?? 0,
          phone: d['phone'] ?? '',
          appointmentProcess: d['appointmentProcess'] ?? '',
          peopleSay: d['peopleSay'] ?? '',
          consultationFee: d['consultationFee'] ?? 500,
          sources: ['Web Search'],
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}
