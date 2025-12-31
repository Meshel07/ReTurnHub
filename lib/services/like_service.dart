import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class LikeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get likes collection reference
  CollectionReference<Map<String, dynamic>> get _likesCollection =>
      _firestore.collection('likes');

  /// Toggle like on a post (like if not liked, unlike if liked)
  Future<bool> toggleLike(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to like posts');
      }

      final userId = currentUser.uid;

      // Check if already liked
      final existingLike = await _likesCollection
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      final batch = _firestore.batch();
      final postRef = _firestore.collection('posts').doc(postId);

      if (existingLike.docs.isNotEmpty) {
        // Unlike: delete the like document
        batch.delete(existingLike.docs.first.reference);
        batch.update(postRef, {
          'likesCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        return false; // Now unliked
      } else {
        // Like: create the like document
        final likeRef = _likesCollection.doc();
        batch.set(likeRef, {
          'postId': postId,
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        batch.update(postRef, {
          'likesCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await batch.commit();
        
        // Create notification for post owner (if not liking own post)
        final postDoc = await postRef.get();
        if (postDoc.exists) {
          final postData = postDoc.data()!;
          final postOwnerId = postData['userId'] as String? ?? '';
          
          if (postOwnerId != userId) {
            // Get current user data for notification
            final currentUserDoc = await _firestore.collection('users').doc(userId).get();
            final currentUserData = currentUserDoc.data();
            final likerName = currentUserData?['name'] as String? ?? 'Someone';
            final likerAvatar = currentUserData?['profileImage'] as String?;
            
            // Import and use notification service
            final notificationService = NotificationService();
            await notificationService.createLikeNotification(
              postId: postId,
              postOwnerId: postOwnerId,
              likerId: userId,
              likerName: likerName,
              likerAvatar: likerAvatar,
            );
          }
        }
        
        return true; // Now liked
      }
    } catch (e) {
      throw Exception('Error toggling like: ${e.toString()}');
    }
  }

  /// Check if a user has liked a post
  Future<bool> hasLiked(String postId, String userId) async {
    try {
      final snapshot = await _likesCollection
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get like count for a post
  Future<int> getLikeCount(String postId) async {
    try {
      final snapshot = await _likesCollection
          .where('postId', isEqualTo: postId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Get all users who liked a post
  Future<List<String>> getLikedByUsers(String postId) async {
    try {
      final snapshot = await _likesCollection
          .where('postId', isEqualTo: postId)
          .get();
      return snapshot.docs.map((doc) => doc.data()['userId'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}

