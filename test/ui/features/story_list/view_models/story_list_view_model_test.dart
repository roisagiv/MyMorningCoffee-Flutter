import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_morning_coffee/ui/features/story_list/view_models/story_list_view_model.dart';

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

      final client = MockClient((request) async {
        return http.Response(jsonEncode(mockResponse), 200);
      });

      final viewModel = StoryListViewModel(client: client);

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
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final viewModel = StoryListViewModel(client: client);

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

      final client = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(jsonEncode(responsePage1), 200);
        } else {
          return http.Response(jsonEncode(responsePage2), 200);
        }
      });

      final viewModel = StoryListViewModel(client: client);

      await viewModel.fetchInitialStories();
      expect(viewModel.stories.length, equals(20));

      await viewModel.loadMoreStories();
      // Should now have 21 stories because 'id_0' is filtered as duplicate
      expect(viewModel.stories.length, equals(21));
      expect(viewModel.stories.last.objectId, equals('id_20'));
    });
  });
}
