import '../models/post_model.dart';
import 'post_service.dart';
import 'comment_service.dart' show Comment, CommentService;
import 'like_service.dart';
import 'supabase_config.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

class ApiService {
  final PostService _postService = PostService();
  final CommentService _commentService = CommentService();
  final LikeService _likeService = LikeService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Submit a new post
  Future<String> submitPost(Post post) async {
    try {
      return await _postService.createPost(post);
    } catch (e) {
      throw Exception('Failed to submit post: ${e.toString()}');
    }
  }

  /// Get all posts
  Future<List<Post>> getPosts({int limit = 20}) async {
    try {
      return await _postService.getPosts(limit: limit);
    } catch (e) {
      throw Exception('Failed to get posts: ${e.toString()}');
    }
  }

  /// Get a single post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      return await _postService.getPostById(postId);
    } catch (e) {
      throw Exception('Failed to get post: ${e.toString()}');
    }
  }

  /// Get posts by user ID
  Future<List<Post>> getPostsByUserId(String userId) async {
    try {
      return await _postService.getPostsByUserId(userId);
    } catch (e) {
      throw Exception('Failed to get user posts: ${e.toString()}');
    }
  }

  /// Search posts by keyword
  Future<List<Post>> searchPosts(String query) async {
    try {
      return await _postService.searchPosts(query);
    } catch (e) {
      throw Exception('Failed to search posts: ${e.toString()}');
    }
  }

  /// Update a post
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    try {
      await _postService.updatePost(postId, updates);
    } catch (e) {
      throw Exception('Failed to update post: ${e.toString()}');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
    } catch (e) {
      throw Exception('Failed to delete post: ${e.toString()}');
    }
  }

  /// Submit a comment on a post
  Future<String> submitComment({
    required String postId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String comment,
  }) async {
    try {
      return await _commentService.addComment(
        postId: postId,
        userId: userId,
        userName: userName,
        userAvatar: userAvatar,
        content: comment,
      );
    } catch (e) {
      throw Exception('Failed to submit comment: ${e.toString()}');
    }
  }

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId) async {
    try {
      return await _commentService.getComments(postId);
    } catch (e) {
      throw Exception('Failed to get comments: ${e.toString()}');
    }
  }

  /// Toggle like on a post
  Future<bool> toggleLike(String postId) async {
    try {
      return await _likeService.toggleLike(postId);
    } catch (e) {
      throw Exception('Failed to toggle like: ${e.toString()}');
    }
  }

  /// Check if user has liked a post
  Future<bool> hasLiked(String postId, String userId) async {
    try {
      return await _likeService.hasLiked(postId, userId);
    } catch (e) {
      return false;
    }
  }

  /// Upload an image to Firebase Storage from a File (mobile/desktop)
  Future<String> uploadImage(File imageFile, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('posts').child(userId).child(fileName);
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload an image to Firebase Storage from raw bytes (web)
  Future<String> uploadImageBytes(Uint8List imageBytes, String userId) async {
    try {
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('posts').child(userId).child(fileName);

      await ref.putData(imageBytes);
      final downloadUrl = await ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  /// Upload a profile image to Firebase Storage
  Future<String> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('profiles').child(userId).child(fileName);
      
      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: ${e.toString()}');
    }
  }

  /// Delete an image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: ${e.toString()}');
    }
  }

  /// Upload an image to Supabase Storage from a File (mobile/desktop)
  Future<String> uploadImageToSupabase(File imageFile, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      // Policy requires files to be in 'public' folder: public/userId/filename
      final filePath = 'public/$userId/$fileName';
      
      // Upload to Supabase Storage
      await supabase.storage
          .from('post-images')
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      
      // Get public URL
      final imageUrl = supabase.storage
          .from('post-images')
          .getPublicUrl(filePath);
      
      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload image to Supabase: ${e.toString()}');
    }
  }

  /// Upload an image to Supabase Storage from raw bytes (web)
  Future<String> uploadImageBytesToSupabase(Uint8List imageBytes, String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'post_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Policy requires files to be in 'public' folder: public/userId/filename
      final filePath = 'public/$userId/$fileName';
      
      // For web, use Supabase Storage REST API with proper authentication
      // The path needs to be properly encoded for the URL
      final pathSegments = filePath.split('/');
      final encodedPath = pathSegments.map((s) => Uri.encodeComponent(s)).join('/');
      
      // Construct the full URL for Supabase Storage API
      final url = '${SupabaseConfig.supabaseUrl}/storage/v1/object/post-images/$encodedPath';
      
      // Make the PUT request with proper authentication
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
          'Content-Type': 'image/jpeg',
          'x-upsert': 'false',
          'Prefer': 'return=minimal',
        },
        body: imageBytes,
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Get public URL using Supabase client
        final imageUrl = supabase.storage
            .from('post-images')
            .getPublicUrl(filePath);
        
        return imageUrl;
      } else {
        final errorBody = response.body;
        // Parse error message for better debugging
        String errorMessage = errorBody;
        try {
          final errorJson = json.decode(errorBody);
          if (errorJson is Map && errorJson.containsKey('message')) {
            errorMessage = errorJson['message'] as String;
          }
        } catch (_) {
          // If parsing fails, use the raw body
        }
        
        // Provide more helpful error message
        if (response.statusCode == 403 || errorMessage.contains('signature verification')) {
          throw Exception(
            'Upload failed: Authentication error (403). This usually means:\n'
            '1. Your Supabase anon key might be incorrect or expired\n'
            '2. Go to Supabase Dashboard → Settings → API and verify your anon key\n'
            '3. Make sure the key in supabase_config.dart matches exactly\n'
            '4. Check that your storage policy allows "public" role (not "authenticated")\n'
            '5. Policy should allow INSERT operations\n'
            'Error: $errorMessage'
          );
        } else if (response.statusCode == 400) {
          throw Exception(
            'Upload failed: Bad request (400). Please check:\n'
            '1. File path format is correct (public/userId/filename.jpg)\n'
            '2. Content-Type header is set correctly\n'
            '3. File size is within limits\n'
            'Error: $errorMessage'
          );
        }
        throw Exception('Upload failed with status ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to upload image to Supabase: ${e.toString()}');
    }
  }
}
