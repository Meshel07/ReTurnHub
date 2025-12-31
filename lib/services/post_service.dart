import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get collection reference
  CollectionReference<Map<String, dynamic>> get _postsCollection =>
      _firestore.collection('posts');

  /// Create a new post
  Future<String> createPost(Post post) async {
    try {
      final docRef = _postsCollection.doc();
      final postData = post.toFirestore();
      postData['id'] = docRef.id;
      postData['createdAt'] = FieldValue.serverTimestamp();
      postData['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(postData);
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating post: ${e.toString()}');
    }
  }

  /// Get a single post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final doc = await _postsCollection.doc(postId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final post = Post.fromFirestore(data, doc.id);
        
        // Check if current user liked this post
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          final isLiked = await _checkIfLiked(postId, currentUserId);
          return post.copyWith(isLiked: isLiked);
        }
        return post;
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching post: ${e.toString()}');
    }
  }

  /// Get all posts, ordered by creation date (newest first)
  Future<List<Post>> getPosts({int limit = 20, DocumentSnapshot? startAfter}) async {
    try {
      Query<Map<String, dynamic>> query = _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final currentUserId = _auth.currentUser?.uid;

      final posts = <Post>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final post = Post.fromFirestore(data, doc.id);
        
        // Check if current user liked this post
        if (currentUserId != null) {
          final isLiked = await _checkIfLiked(doc.id, currentUserId);
          posts.add(post.copyWith(isLiked: isLiked));
        } else {
          posts.add(post);
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Error fetching posts: ${e.toString()}');
    }
  }

  /// Stream of posts for real-time updates
  Stream<List<Post>> getPostsStream({int limit = 20}) {
    try {
      final currentUserId = _auth.currentUser?.uid;
      
      return _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .asyncMap((snapshot) async {
        final posts = <Post>[];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final post = Post.fromFirestore(data, doc.id);
          
          // Check if current user liked this post
          if (currentUserId != null) {
            final isLiked = await _checkIfLiked(doc.id, currentUserId);
            posts.add(post.copyWith(isLiked: isLiked));
          } else {
            posts.add(post);
          }
        }
        return posts;
      });
    } catch (e) {
      throw Exception('Error streaming posts: ${e.toString()}');
    }
  }

  /// Get posts by user ID
  Future<List<Post>> getPostsByUserId(String userId) async {
    try {
      final snapshot = await _postsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final currentUserId = _auth.currentUser?.uid;
      final posts = <Post>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final post = Post.fromFirestore(data, doc.id);
        
        if (currentUserId != null) {
          final isLiked = await _checkIfLiked(doc.id, currentUserId);
          posts.add(post.copyWith(isLiked: isLiked));
        } else {
          posts.add(post);
        }
      }

      return posts;
    } catch (e) {
      throw Exception('Error fetching user posts: ${e.toString()}');
    }
  }

  /// Search posts by keyword (content, user name, type, location, contact)
  Future<List<Post>> searchPosts(String query, {int limit = 100}) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    try {
      final queryLower = trimmedQuery.toLowerCase();
      final snapshot = await _postsCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final currentUserId = _auth.currentUser?.uid;
      final results = <Post>[];

      bool matches(Post post) {
        final fields = <String>[
          post.content,
          post.userName,
          post.type ?? '',
          post.location ?? '',
          post.contact ?? '',
        ];
        return fields.any((field) => field.toLowerCase().contains(queryLower));
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        var post = Post.fromFirestore(data, doc.id);

        if (!matches(post)) {
          continue;
        }

        if (currentUserId != null) {
          final isLiked = await _checkIfLiked(doc.id, currentUserId);
          post = post.copyWith(isLiked: isLiked);
        }

        results.add(post);
      }

      return results;
    } catch (e) {
      throw Exception('Error searching posts: ${e.toString()}');
    }
  }

  /// Check if current user is admin
  Future<bool> _isAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final role = userData?['role'] as String? ?? '';
        return role.toLowerCase() == 'admin';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update a post
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to update posts');
      }

      // Verify ownership or admin status
      final post = await getPostById(postId);
      if (post == null) {
        throw Exception('Post not found');
      }
      
      final isAdmin = await _isAdmin();
      if (post.userId != currentUser.uid && !isAdmin) {
        throw Exception('You can only update your own posts');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _postsCollection.doc(postId).update(updates);
    } catch (e) {
      throw Exception('Error updating post: ${e.toString()}');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be logged in to delete posts');
      }

      // Verify ownership or admin status
      final post = await getPostById(postId);
      if (post == null) {
        throw Exception('Post not found');
      }
      
      final isAdmin = await _isAdmin();
      if (post.userId != currentUser.uid && !isAdmin) {
        throw Exception('You can only delete your own posts. Admins can delete any post.');
      }

      // Delete post and related data in a batch
      final batch = _firestore.batch();
      
      // Delete post
      batch.delete(_postsCollection.doc(postId));
      
      // Delete comments
      final commentsSnapshot = await _firestore
          .collection('comments')
          .where('postId', isEqualTo: postId)
          .get();
      for (var doc in commentsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete likes
      final likesSnapshot = await _firestore
          .collection('likes')
          .where('postId', isEqualTo: postId)
          .get();
      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting post: ${e.toString()}');
    }
  }

  /// Check if a user has liked a post
  Future<bool> _checkIfLiked(String postId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection('likes')
          .where('postId', isEqualTo: postId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

