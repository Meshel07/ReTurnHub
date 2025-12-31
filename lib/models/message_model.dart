class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final DateTime timestamp;
  final bool isSentByMe;
  // Message type: 'normal', 'post_reply' (system message indicating post reply)
  final String? messageType;
  // Post information (optional - for messages that reference a post)
  final String? postId;
  final String? postUserId;
  final String? postUserName;
  final String? postUserAvatar;
  final String? postContent;
  final String? postImageUrl;
  final String? postType;
  final String? postLocation;
  final String? postContact;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.timestamp,
    required this.isSentByMe,
    this.messageType,
    this.postId,
    this.postUserId,
    this.postUserName,
    this.postUserAvatar,
    this.postContent,
    this.postImageUrl,
    this.postType,
    this.postLocation,
    this.postContact,
  });

  /// Factory constructor to create Message from Firestore document
  factory Message.fromFirestore(Map<String, dynamic> json, String id, String currentUserId) {
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is DateTime) {
        return value;
      } else if (value.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        return (value as dynamic).toDate();
      }
      return DateTime.now();
    }

    final senderId = json['senderId'] as String? ?? '';
    return Message(
      id: id,
      senderId: senderId,
      senderName: json['senderName'] as String? ?? '',
      senderAvatar: json['senderAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      timestamp: parseTimestamp(json['timestamp']),
      isSentByMe: senderId == currentUserId,
      messageType: json['messageType'] as String?,
      postId: json['postId'] as String?,
      postUserId: json['postUserId'] as String?,
      postUserName: json['postUserName'] as String?,
      postUserAvatar: json['postUserAvatar'] as String?,
      postContent: json['postContent'] as String?,
      postImageUrl: json['postImageUrl'] as String?,
      postType: json['postType'] as String?,
      postLocation: json['postLocation'] as String?,
      postContact: json['postContact'] as String?,
    );
  }

  /// Convert Message to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'timestamp': timestamp,
      if (messageType != null) 'messageType': messageType,
      if (postId != null) 'postId': postId,
      if (postUserId != null) 'postUserId': postUserId,
      if (postUserName != null) 'postUserName': postUserName,
      if (postUserAvatar != null) 'postUserAvatar': postUserAvatar,
      if (postContent != null) 'postContent': postContent,
      if (postImageUrl != null) 'postImageUrl': postImageUrl,
      if (postType != null) 'postType': postType,
      if (postLocation != null) 'postLocation': postLocation,
      if (postContact != null) 'postContact': postContact,
    };
  }

  String get timeString {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  bool isSameDay(Message other) {
    return timestamp.year == other.timestamp.year &&
        timestamp.month == other.timestamp.month &&
        timestamp.day == other.timestamp.day;
  }

  bool shouldShowTimestamp(Message? previousMessage) {
    if (previousMessage == null) return true;
    
    final difference = timestamp.difference(previousMessage.timestamp);
    return difference.inMinutes >= 5 || !isSameDay(previousMessage);
  }
}

