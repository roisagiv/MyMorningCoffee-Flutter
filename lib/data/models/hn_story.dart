class HnStory {
  final String objectId;
  final String title;
  final String? url;
  final String author;
  final int points;
  final int numComments;
  final DateTime createdAt;

  HnStory({
    required this.objectId,
    required this.title,
    this.url,
    required this.author,
    required this.points,
    required this.numComments,
    required this.createdAt,
  });

  /// Factory constructor to parse a story from a JSON map.
  factory HnStory.fromJson(Map<String, dynamic> json) {
    return HnStory(
      objectId: json['objectID'] as String? ?? json['story_id']?.toString() ?? '',
      title: json['title'] as String? ?? json['story_title'] as String? ?? 'Untitled',
      url: json['url'] as String? ?? json['story_url'] as String?,
      author: json['author'] as String? ?? 'unknown',
      points: json['points'] as int? ?? 0,
      numComments: json['num_comments'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  /// Extracts the base domain name from the story's URL.
  String? get domain {
    if (url == null || url!.isEmpty) return null;
    try {
      final uri = Uri.parse(url!);
      final host = uri.host;
      return host.startsWith('www.') ? host.substring(4) : host;
    } catch (_) {
      return null;
    }
  }

  /// Formats the difference between the creation time and the current time
  /// in a concise, human-readable format.
  String get relativeTime {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays >= 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays >= 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  /// Returns the standard Hacker News thread URL for comments.
  String get commentsUrl => 'https://news.ycombinator.com/item?id=$objectId';
}
