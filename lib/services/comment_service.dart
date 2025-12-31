import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromFirestore(Map<String, dynamic> json, String id) {
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

    return Comment(
      id: id,
      postId: json['postId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userAvatar: json['userAvatar'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: parseTimestamp(json['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

class CommentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Get comments collection reference
  CollectionReference<Map<String, dynamic>> get _commentsCollection =>
      _firestore.collection('comments');

  /// Add a comment to a post
  Future<String> addComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String content,
  }) async {
    try {
      final trimmedContent = content.trim();

      if (trimmedContent.isEmpty) {
        throw Exception('Comment cannot be empty');
      }

      final postRef = _firestore.collection('posts').doc(postId);
      final postSnapshot = await postRef.get();
      if (!postSnapshot.exists) {
        throw Exception('Post not found');
      }
      final postOwnerId = postSnapshot.data()?['userId'] as String? ?? '';

      final batch = _firestore.batch();

      // Create comment document
      final commentRef = _commentsCollection.doc();
      final commentData = {
        'postId': postId,
        'userId': userId,
        'userName': userName,
        'userAvatar': userAvatar,
        'content': trimmedContent,
        'createdAt': FieldValue.serverTimestamp(),
      };
      batch.set(commentRef, commentData);

      // Update post comments count
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (postOwnerId.isNotEmpty && postOwnerId != userId) {
        await _notificationService.createCommentNotification(
          postId: postId,
          postOwnerId: postOwnerId,
          commenterId: userId,
          commenterName: userName,
          commenterAvatar: userAvatar,
          commentText: trimmedContent,
          commentId: commentRef.id,
        );
      }

      return commentRef.id;
    } catch (e) {
      throw Exception('Error adding comment: ${e.toString()}');
    }
  }

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId, {int limit = 50}) async {
    try {
      final snapshot = await _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching comments: ${e.toString()}');
    }
  }

  /// Stream of comments for real-time updates
  Stream<List<Comment>> getCommentsStream(String postId, {int limit = 50}) {
    try {
      return _commentsCollection
          .where('postId', isEqualTo: postId)
          .orderBy('createdAt', descending: false)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
                .toList(),
          );
    } catch (e) {
      throw Exception('Error streaming comments: ${e.toString()}');
    }
  }

  /// Update a comment
  Future<void> updateComment(String commentId, String newContent) async {
    try {
      if (newContent.trim().isEmpty) {
        throw Exception('Comment cannot be empty');
      }

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to update comments');
      }

      // Verify ownership
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }
      final comment = Comment.fromFirestore(commentDoc.data()!, commentId);
      if (comment.userId != currentUser.uid) {
        throw Exception('You can only update your own comments');
      }

      await _commentsCollection.doc(commentId).update({
        'content': newContent.trim(),
      });
    } catch (e) {
      throw Exception('Error updating comment: ${e.toString()}');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete comments');
      }

      // Verify ownership
      final commentDoc = await _commentsCollection.doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }
      final comment = Comment.fromFirestore(commentDoc.data()!, commentId);
      if (comment.userId != currentUser.uid) {
        throw Exception('You can only delete your own comments');
      }

      final batch = _firestore.batch();

      // Delete comment
      batch.delete(_commentsCollection.doc(commentId));

      // Update post comments count
      final postRef = _firestore.collection('posts').doc(comment.postId);
      batch.update(postRef, {
        'commentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting comment: ${e.toString()}');
    }
  }
}
