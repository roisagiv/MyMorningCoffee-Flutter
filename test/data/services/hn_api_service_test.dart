import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_morning_coffee/data/services/hn_api_service.dart';

void main() {
  group('HnApiService', () {
    test('fetchStories returns parsed list of stories on 200 OK', () async {
      final mockResponse = {
        'hits': [
          {
            'objectID': '1',
            'title': 'Flutter Rules',
            'url': 'https://flutter.dev',
            'author': 'dash',
            'points': 100,
            'num_comments': 10,
            'created_at': '2026-07-06T20:00:00Z',
          },
          {
            'objectID': '2',
            'title': '', // Empty title - should be filtered out
            'url': 'https://invalid.dev',
            'author': 'ghost',
            'points': 0,
            'num_comments': 0,
            'created_at': '2026-07-06T20:00:00Z',
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.url.path, equals('/api/v1/search_by_date'));
        expect(request.url.queryParameters['tags'], equals('story'));
        expect(request.url.queryParameters['page'], equals('0'));
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final service = HnApiService(client: client);
      final stories = await service.fetchStories();

      expect(stories.length, equals(1));
      expect(stories[0].objectId, equals('1'));
      expect(stories[0].title, equals('Flutter Rules'));
    });

    test('fetchStories throws Exception on non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      final service = HnApiService(client: client);

      expect(
        () => service.fetchStories(),
        throwsException,
      );
    });
  });
}
