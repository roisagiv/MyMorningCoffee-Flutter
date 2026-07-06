import 'package:dio/dio.dart';
import '../models/hn_story.dart';

class HnApiService {
  final Dio _dio;

  HnApiService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://hn.algolia.com'));

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

    try {
      final response = await _dio.get(
        '/api/v1/search_by_date',
        queryParameters: queryParams,
      );

      final parsedJson = response.data as Map<String, dynamic>;
      final hits = parsedJson['hits'] as List<dynamic>? ?? [];
      return hits
          .map((hit) => HnStory.fromJson(hit as Map<String, dynamic>))
          .where((story) => story.title.isNotEmpty) // Filter out empty stories
          .toList();
    } on DioException catch (e) {
      throw Exception(
        'Failed to fetch stories from Hacker News API (Status: ${e.response?.statusCode})',
      );
    } catch (e) {
      throw Exception('Failed to fetch stories: $e');
    }
  }
}
