import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if the user is currently logged in
  static Future<bool> isLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  /// Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        // Get user data from Firestore
        return await getUserData(userCredential.user!.uid);
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred during sign in: ${e.toString()}');
    }
  }

  /// Register with email and password
  Future<UserModel?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? profileImage,
    String role = UserRole.user,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final user = userCredential.user!;

        // Update display name
        await user.updateDisplayName(name);

        // Create user document in Firestore
        final userModel = UserModel(
          id: user.uid,
          name: name,
          email: email.trim(),
          profileImage: profileImage,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore.collection('users').doc(user.uid).set(
              userModel.toJson(),
            );

        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('An error occurred during registration: ${e.toString()}');
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: ${e.toString()}');
    }
  }

  /// Search users by name (prefix match, case-sensitive on stored value)
  Future<List<UserModel>> searchUsersByName(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final currentUserId = _auth.currentUser?.uid;
      final snapshot = await _firestore
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: trimmed)
          .where('name', isLessThanOrEqualTo: '$trimmed\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] ??= doc.id;
            return UserModel.fromJson(data);
          })
          .where((user) => user.id.isNotEmpty && user.id != currentUserId)
          .toList();
    } catch (e) {
      throw Exception('Error searching users: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Error signing out: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Error sending password reset email: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? profileImage,
    String? role, // Admin only - to change user role
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Check if trying to update role - only admins can do this
      if (role != null) {
        final isAdmin = await isCurrentUserAdmin();
        if (!isAdmin) {
          throw Exception('Only admins can update user roles');
        }
      }

      // Update Firestore
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      if (role != null) updateData['role'] = role.toLowerCase(); // Normalize to lowercase

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updateData);
      }

      // Update Auth display name
      if (name != null) {
        await user.updateDisplayName(name);
      }
    } catch (e) {
      throw Exception('Error updating profile: ${e.toString()}');
    }
  }

  /// Update any user's profile (admin only)
  Future<void> updateUserProfileById({
    required String userId,
    String? name,
    String? profileImage,
    String? role,
  }) async {
    try {
      final isAdmin = await isCurrentUserAdmin();
      if (!isAdmin) {
        throw Exception('Only admins can update other users\' profiles');
      }

      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (profileImage != null) updateData['profileImage'] = profileImage;
      if (role != null) updateData['role'] = role.toLowerCase(); // Normalize to lowercase

      if (updateData.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updateData);
      }
    } catch (e) {
      throw Exception('Error updating user profile: ${e.toString()}');
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final userData = await getUserData(currentUser.uid);
      return userData?.isAdmin ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Delete a user account
  /// Admins can delete any user, regular users can only delete themselves
  Future<void> deleteUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete accounts');
      }

      // Check if current user is admin
      final isAdmin = await isCurrentUserAdmin();
      
      // Regular users can only delete themselves
      if (!isAdmin && currentUser.uid != userId) {
        throw Exception('You can only delete your own account. Admins can delete any account.');
      }

      // Prevent admin from deleting themselves (optional safety check)
      if (isAdmin && currentUser.uid == userId) {
        throw Exception('For safety reasons, admins cannot delete their own account. Please contact support.');
      }

      final batch = _firestore.batch();

      // Delete user document from Firestore
      final userRef = _firestore.collection('users').doc(userId);
      batch.delete(userRef);

      // Delete user's posts
      final postsSnapshot = await _firestore
          .collection('posts')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in postsSnapshot.docs) {
        batch.delete(doc.reference);
        
        // Delete comments on this post
        final commentsSnapshot = await _firestore
            .collection('comments')
            .where('postId', isEqualTo: doc.id)
            .get();
        for (var commentDoc in commentsSnapshot.docs) {
          batch.delete(commentDoc.reference);
        }
        
        // Delete likes on this post
        final likesSnapshot = await _firestore
            .collection('likes')
            .where('postId', isEqualTo: doc.id)
            .get();
        for (var likeDoc in likesSnapshot.docs) {
          batch.delete(likeDoc.reference);
        }
      }

      // Delete user's comments
      final userCommentsSnapshot = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in userCommentsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete user's likes
      final userLikesSnapshot = await _firestore
          .collection('likes')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in userLikesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete chats where user is a participant
      final chatsSnapshot = await _firestore
          .collection('chats')
          .where('participants', arrayContains: userId)
          .get();
      for (var doc in chatsSnapshot.docs) {
        // Delete all messages in the chat
        final messagesSnapshot = await doc.reference
            .collection('messages')
            .get();
        for (var msgDoc in messagesSnapshot.docs) {
          batch.delete(msgDoc.reference);
        }
        // Delete the chat
        batch.delete(doc.reference);
      }

      // Commit all deletions
      await batch.commit();

      // Delete the Firebase Auth user (only if deleting another user, or if non-admin deleting themselves)
      if (currentUser.uid != userId) {
        // Admin deleting another user - we can't delete their Auth account from here
        // This would require Admin SDK, so just log a note
        // For now, we'll only delete the Firestore data
      } else {
        // User deleting themselves - delete Auth account
        await currentUser.delete();
        await _auth.signOut();
      }
    } catch (e) {
      throw Exception('Error deleting user: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with that email address.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}
