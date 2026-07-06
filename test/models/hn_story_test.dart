import 'package:flutter_test/flutter_test.dart';
import 'package:my_morning_coffee/data/models/hn_story.dart';

void main() {
  group('HnStory Model', () {
    test('should parse story from json correctly with all fields populated', () {
      final json = {
        'objectID': '12345',
        'title': 'Test Story Title',
        'url': 'https://github.com/test/repo',
        'author': 'john_doe',
        'points': 42,
        'num_comments': 10,
        'created_at': '2026-07-06T20:00:00Z',
      };

      final story = HnStory.fromJson(json);

      expect(story.objectId, equals('12345'));
      expect(story.title, equals('Test Story Title'));
      expect(story.url, equals('https://github.com/test/repo'));
      expect(story.domain, equals('github.com'));
      expect(story.author, equals('john_doe'));
      expect(story.points, equals(42));
      expect(story.numComments, equals(10));
      expect(story.createdAt, equals(DateTime.parse('2026-07-06T20:00:00Z')));
    });

    test('should parse story from json with fallbacks for null or missing fields', () {
      final json = <String, dynamic>{};

      final story = HnStory.fromJson(json);

      expect(story.objectId, equals(''));
      expect(story.title, equals('Untitled'));
      expect(story.url, isNull);
      expect(story.domain, isNull);
      expect(story.author, equals('unknown'));
      expect(story.points, equals(0));
      expect(story.numComments, equals(0));
      expect(story.createdAt, isNotNull);
    });

    test('should handle nested/sub-domains correctly in domain getter', () {
      final storyWithWww = HnStory(
        objectId: '1',
        title: 'Title',
        url: 'https://www.google.com/search?q=test',
        author: 'author',
        points: 0,
        numComments: 0,
        createdAt: DateTime.now(),
      );

      final storyWithoutWww = HnStory(
        objectId: '2',
        title: 'Title',
        url: 'https://subdomain.google.com/search?q=test',
        author: 'author',
        points: 0,
        numComments: 0,
        createdAt: DateTime.now(),
      );

      expect(storyWithWww.domain, equals('google.com'));
      expect(storyWithoutWww.domain, equals('subdomain.google.com'));
    });
  });
}
