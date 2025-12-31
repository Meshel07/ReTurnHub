class Post {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String? type; // "lost" or "found"
  final String? location;
  final String? contact;
  final String? resolution; // e.g., "Found" for lost items, "Claimed" for found items

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.updatedAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.type,
    this.location,
    this.contact,
    this.resolution,
  });

  /// Factory constructor to create Post from Firestore document
  factory Post.fromFirestore(Map<String, dynamic> json, String id) {
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

    return Post(
      id: id,
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userAvatar: json['userAvatar'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      createdAt: parseTimestamp(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? parseTimestamp(json['updatedAt']) : null,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
      type: json['type'] as String?,
      location: json['location'] as String?,
      contact: json['contact'] as String?,
      resolution: json['resolution'] as String?,
    );
  }

  /// Convert Post to Firestore document
  /// Note: Timestamps will be converted to Firestore Timestamp by FieldValue.serverTimestamp()
  /// in the service layer, or use Timestamp.fromDate() if needed
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? createdAt,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      if (type != null) 'type': type,
      if (location != null) 'location': location,
      if (contact != null) 'contact': contact,
      if (resolution != null) 'resolution': resolution,
    };
  }

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    String? type,
    String? location,
    String? contact,
    String? resolution,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      type: type ?? this.type,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      resolution: resolution ?? this.resolution,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
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

