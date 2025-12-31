import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Create a like notification when someone likes a post
  Future<void> createLikeNotification({
    required String postId,
    required String postOwnerId,
    required String likerId,
    required String likerName,
    String? likerAvatar,
  }) async {
    try {
      // Don't create notification if user is liking their own post
      if (postOwnerId == likerId) return;

      final notificationRef = _notificationsCollection.doc();
      await notificationRef.set({
        'userId': postOwnerId,
        'type': 'like',
        'title': '$likerName liked your post',
        'body': '$likerName liked your post',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'postId': postId,
        'postOwnerId': postOwnerId,
        'likerId': likerId,
        'likerName': likerName,
        'likerAvatar': likerAvatar,
      });
    } catch (e) {
      // Silently fail - notifications are not critical
      print('Error creating like notification: ${e.toString()}');
    }
  }

  /// Create a message notification when someone sends a message
  Future<void> createMessageNotification({
    required String chatId,
    required String recipientId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    required String messageContent,
  }) async {
    try {
      // Don't create notification if user is messaging themselves
      if (recipientId == senderId) return;

      final notificationRef = _notificationsCollection.doc();
      await notificationRef.set({
        'userId': recipientId,
        'type': 'message',
        'title': 'New message from $senderName',
        'body': messageContent.length > 50
            ? '${messageContent.substring(0, 50)}...'
            : messageContent,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'chatId': chatId,
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatar': senderAvatar,
      });
    } catch (e) {
      // Silently fail - notifications are not critical
      print('Error creating message notification: ${e.toString()}');
    }
  }

  /// Create a comment notification when someone comments on a post
  Future<void> createCommentNotification({
    required String postId,
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    String? commenterAvatar,
    required String commentText,
    String? commentId,
  }) async {
    try {
      if (postOwnerId == commenterId) return;

      final notificationRef = _notificationsCollection.doc();
      final summary = commentText.length > 80
          ? '${commentText.substring(0, 80)}...'
          : commentText;

      await notificationRef.set({
        'userId': postOwnerId,
        'type': 'comment',
        'title': '$commenterName commented on your post',
        'body': summary,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'postId': postId,
        'postOwnerId': postOwnerId,
        'commentId': commentId,
        'commenterId': commenterId,
        'commenterName': commenterName,
        'commenterAvatar': commenterAvatar,
        'commentText': commentText,
      });
    } catch (e) {
      print('Error creating comment notification: ${e.toString()}');
    }
  }

  /// Get all notifications for current user
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Error fetching notifications: ${e.toString()}');
    }
  }

  /// Stream of notifications for real-time updates
  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    try {
      return _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => AppNotification.fromFirestore(doc.data(), doc.id))
                .toList(),
          );
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Stream of unread notification count
  Stream<int> getUnreadCountStream(String userId) {
    try {
      return _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: ${e.toString()}');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: ${e.toString()}');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      throw Exception('Error deleting notification: ${e.toString()}');
    }
  }
}
