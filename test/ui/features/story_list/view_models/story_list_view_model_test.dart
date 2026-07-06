import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:my_morning_coffee/ui/features/story_list/view_models/story_list_view_model.dart';

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
  group('StoryListViewModel', () {
    test('fetchInitialStories updates stories and loading state on success', () async {
      final mockResponse = {
        'hits': [
          {
            'objectID': '123',
            'title': 'Test Story',
            'url': 'https://example.com',
            'author': 'tester',
            'points': 10,
            'num_comments': 5,
            'created_at': '2026-07-06T20:00:00Z',
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(mockResponse))),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final viewModel = StoryListViewModel(dio: dio);

      // Verify initial states
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.stories, isEmpty);
      expect(viewModel.errorMessage, isNull);

      // Start fetching
      final future = viewModel.fetchInitialStories();
      expect(viewModel.isLoading, isTrue);

      await future;

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.stories.length, equals(1));
      expect(viewModel.stories[0].objectId, equals('123'));
      expect(viewModel.errorMessage, isNull);
    });

    test('fetchInitialStories updates error message on failure', () async {
      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        return ResponseBody.fromBytes(
          Uint8List.fromList(utf8.encode('Internal Server Error')),
          500,
        );
      });

      final viewModel = StoryListViewModel(dio: dio);

      await viewModel.fetchInitialStories();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.stories, isEmpty);
      expect(viewModel.errorMessage, contains('Failed to fetch stories'));
    });

    test('loadMoreStories appends new stories without duplicate objectIds', () async {
      int requestCount = 0;
      final responsePage1 = {
        'hits': List.generate(
          20,
          (i) => {
            'objectID': 'id_$i',
            'title': 'Story $i',
            'url': 'https://example.com/$i',
            'author': 'author',
            'points': 10,
            'num_comments': 5,
            'created_at': '2026-07-06T20:00:00Z',
          },
        ),
      };
      
      // Page 2 includes one duplicate ('id_0') and one new story ('id_20')
      final responsePage2 = {
        'hits': [
          {
            'objectID': 'id_0',
            'title': 'Story 0',
            'url': 'https://example.com/0',
            'author': 'author',
            'points': 10,
            'num_comments': 5,
            'created_at': '2026-07-06T20:00:00Z',
          },
          {
            'objectID': 'id_20',
            'title': 'Story 20',
            'url': 'https://example.com/20',
            'author': 'author',
            'points': 10,
            'num_comments': 5,
            'created_at': '2026-07-06T20:00:00Z',
          }
        ]
      };

      final dio = Dio();
      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        requestCount++;
        final payload = requestCount == 1 ? responsePage1 : responsePage2;
        return ResponseBody.fromBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(payload))),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final viewModel = StoryListViewModel(dio: dio);

      await viewModel.fetchInitialStories();
      expect(viewModel.stories.length, equals(20));

      await viewModel.loadMoreStories();
      // Should now have 21 stories because 'id_0' is filtered as duplicate
      expect(viewModel.stories.length, equals(21));
      expect(viewModel.stories.last.objectId, equals('id_20'));
    });
  });
}
