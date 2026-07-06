import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:my_morning_coffee/data/services/hn_api_service.dart';

// Simple mock HttpClientAdapter implementation
class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  MockHttpClientAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

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

      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        expect(options.path, equals('/api/v1/search_by_date'));
        expect(options.queryParameters['tags'], equals('story'));
        expect(options.queryParameters['page'], equals('0'));

        final responsePayload = jsonEncode(mockResponse);
        return ResponseBody.fromBytes(
          Uint8List.fromList(utf8.encode(responsePayload)),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final service = HnApiService(dio: dio);
      final stories = await service.fetchStories();

      expect(stories.length, equals(1));
      expect(stories[0].objectId, equals('1'));
      expect(stories[0].title, equals('Flutter Rules'));
    });

    test('fetchStories throws Exception on non-200 response', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          Uint8List.fromList(utf8.encode('Not Found')),
          404,
        );
      });

      final service = HnApiService(dio: dio);

      expect(
        () => service.fetchStories(),
        throwsException,
      );
    });
  });
}
