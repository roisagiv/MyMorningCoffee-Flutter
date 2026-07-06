import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/hn_story.dart';

/// Top-level function for background isolate parsing of stories.
List<HnStory> _parseStories(String responseBody) {
  final parsedJson = jsonDecode(responseBody) as Map<String, dynamic>;
  final hits = parsedJson['hits'] as List<dynamic>? ?? [];
  return hits
      .map((hit) => HnStory.fromJson(hit as Map<String, dynamic>))
      .where((story) => story.title.isNotEmpty) // Filter out empty stories
      .toList();
}

class HnApiService {
  static const String _baseUrl = 'https://hn.algolia.com';

  /// Fetches stories from the Algolia Hacker News search_by_date API.
  Future<List<HnStory>> fetchStories({
    int page = 0,
    int hitsPerPage = 20,
    String? query,
  }) async {
    final queryParams = {
      'tags': 'story',
      'page': page.toString(),
      'hitsPerPage': hitsPerPage.toString(),
    };
    
    if (query != null && query.isNotEmpty) {
      queryParams['query'] = query;
    }

    final uri = Uri.parse('$_baseUrl/api/v1/search_by_date').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Offload heavy JSON parsing to a background isolate
      return compute(_parseStories, response.body);
    } else {
      throw Exception('Failed to fetch stories from Hacker News API (Status: ${response.statusCode})');
    }
  }
}
