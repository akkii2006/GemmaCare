import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';

class SerperResult {
  final String title;
  final String snippet;
  final String link;
  final double? rating;

  const SerperResult({
    required this.title,
    required this.snippet,
    required this.link,
    this.rating,
  });
}

class SerperService {
  static final _client = http.Client();
  static const String _endpoint = 'https://google.serper.dev/search';

  Future<List<SerperResult>> search(String query, {int num = 6}) async {
    try {
      final response = await _client.post(
        Uri.parse(_endpoint),
        headers: {
          'X-API-KEY': AppConstants.serperApiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'q': query, 'num': num}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      final organic = data['organic'] as List<dynamic>? ?? [];

      return organic.map((r) => SerperResult(
        title: r['title'] ?? '',
        snippet: r['snippet'] ?? '',
        link: r['link'] ?? '',
        rating: r['rating'] != null ? (r['rating'] as double?) ?? double.tryParse(r['rating'].toString()) : null,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// Search for a place by name + location to get web reviews
  Future<String> getWebReviews(String placeName, String city) async {
    final results = await search(
      '$placeName $city reviews site:reddit.com OR site:mouthshut.com OR site:justdial.com OR site:practo.com',
      num: 6,
    );
    if (results.isEmpty) return '';
    return results.map((r) {
      final rating = r.rating != null ? ' [${r.rating}★]' : '';
      return '${r.title}$rating: ${r.snippet}';
    }).join('\n\n');
  }

  /// Smart search: find hospitals/doctors/pharmacies by query near a location
  Future<List<SerperResult>> smartSearch({
    required String query,
    required String city,
    required String type, // hospital, doctor, pharmacy
  }) async {
    return search('$query $type near $city India', num: 8);
  }
}
