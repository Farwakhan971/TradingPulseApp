import 'package:intl/intl.dart';

class Comment {
  String userId;
  String text;
  int timestamp;
  List<Comment> replies;

  Comment({required this.userId, required this.text, required this.timestamp, this.replies = const []});

  factory Comment.fromMap(Map<dynamic, dynamic> map, String userEmail) {
    String userId = map['userId'] as String? ?? userEmail; // Changed line
    return Comment(
      userId: userId,
      text: map['text'] as String,
      timestamp: map['timestamp'] as int,
    );
  }
  // Updated method to match the formatTimeAgo method
  String get formattedTimestamp => _formatTimeAgo(timestamp);

  static String _formatTimeAgo(int timestamp) {
    DateTime commentDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    Duration difference = DateTime.now().difference(commentDate);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return DateFormat('MMM d, yyyy').format(commentDate);
    }
  }
}