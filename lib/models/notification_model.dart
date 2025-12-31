class AppNotification {
  final String id;
  final String userId; // User who receives the notification
  final String type; // 'like' or 'message'
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  // For like notifications
  final String? postId;
  final String? postOwnerId;
  final String? likerId;
  final String? likerName;
  final String? likerAvatar;

  // For message notifications
  final String? chatId;
  final String? senderId;
  final String? senderName;
  final String? senderAvatar;

  // For comment notifications
  final String? commentId;
  final String? commenterId;
  final String? commenterName;
  final String? commenterAvatar;
  final String? commentText;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.isRead = false,
    required this.createdAt,
    this.postId,
    this.postOwnerId,
    this.likerId,
    this.likerName,
    this.likerAvatar,
    this.chatId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.commentId,
    this.commenterId,
    this.commenterName,
    this.commenterAvatar,
    this.commentText,
  });

  factory AppNotification.fromFirestore(Map<String, dynamic> json, String id) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      } else if (value.toString().contains('Timestamp')) {
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    return AppNotification(
      id: id,
      userId: json['userId'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: parseTimestamp(json['createdAt']),
      postId: json['postId'] as String?,
      postOwnerId: json['postOwnerId'] as String?,
      likerId: json['likerId'] as String?,
      likerName: json['likerName'] as String?,
      likerAvatar: json['likerAvatar'] as String?,
      chatId: json['chatId'] as String?,
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatar: json['senderAvatar'] as String?,
      commentId: json['commentId'] as String?,
      commenterId: json['commenterId'] as String?,
      commenterName: json['commenterName'] as String?,
      commenterAvatar: json['commenterAvatar'] as String?,
      commentText: json['commentText'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': isRead,
      'createdAt': createdAt,
      if (postId != null) 'postId': postId,
      if (postOwnerId != null) 'postOwnerId': postOwnerId,
      if (likerId != null) 'likerId': likerId,
      if (likerName != null) 'likerName': likerName,
      if (likerAvatar != null) 'likerAvatar': likerAvatar,
      if (chatId != null) 'chatId': chatId,
      if (senderId != null) 'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      if (senderAvatar != null) 'senderAvatar': senderAvatar,
      if (commentId != null) 'commentId': commentId,
      if (commenterId != null) 'commenterId': commenterId,
      if (commenterName != null) 'commenterName': commenterName,
      if (commenterAvatar != null) 'commenterAvatar': commenterAvatar,
      if (commentText != null) 'commentText': commentText,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
