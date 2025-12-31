import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../widgets/post_card.dart';

class UserTimelinePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String userAvatar;

  const UserTimelinePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userAvatar,
  });

  @override
  State<UserTimelinePage> createState() => _UserTimelinePageState();
}

class _UserTimelinePageState extends State<UserTimelinePage> {
  final ApiService _apiService = ApiService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Post> _posts = [];
  bool _isRefreshing = false;
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.uid;
      });
      
      final userData = await _authService.getUserData(currentUser.uid);
      if (mounted) {
        setState(() {
          _isAdmin = userData?.isAdmin ?? false;
        });
      }
    }
  }

  Future<void> _loadPosts() async {
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final posts = await _apiService.getPostsByUserId(widget.userId);
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load posts. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _isRefreshing = true;
    });
    await _loadPosts();
  }

  void _handleLike(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final current = _posts[index];
    final updated = current.copyWith(
      isLiked: !current.isLiked,
      likesCount:
          current.isLiked ? current.likesCount - 1 : current.likesCount + 1,
    );

    setState(() {
      _posts[index] = updated;
    });

    try {
      await _apiService.toggleLike(post.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _posts[index] = current;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildProfileHeader(),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              child: _buildPostsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[300],
            backgroundImage: widget.userAvatar.isNotEmpty
                ? NetworkImage(widget.userAvatar)
                : null,
            child: widget.userAvatar.isEmpty
                ? Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posts by ${widget.userName}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                if (_canMessageUser()) ...[
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _startChatWithUser,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading && _posts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loadPosts,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  const Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        final canDelete = post.userId == _currentUserId || _isAdmin;
        return PostCard(
          post: post,
          onLike: () => _handleLike(post),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/postDetails',
              arguments: post,
            );
          },
          onUserTap: null, // Already on the profile
          onMessageTap: _canMessageUser()
              ? () => _startChatWithUser(post)
              : null,
          onMarkFound: _canManageStatus(post)
              ? () => _markPostStatus(post, 'Found')
              : null,
          onMarkClaimed: _canManageStatus(post)
              ? () => _markPostStatus(post, 'Claimed')
              : null,
          onDelete: canDelete ? () => _handleDeletePost(post) : null,
          canDelete: canDelete,
        );
      },
    );
  }

  Future<void> _handleDeletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text(
          _isAdmin && post.userId != _currentUserId
              ? 'Are you sure you want to delete this post by ${post.userName}? This action cannot be undone.'
              : 'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _apiService.deletePost(post.id);
        
        if (mounted) {
          setState(() {
            _posts.removeWhere((p) => p.id == post.id);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _canManageStatus(Post post) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;
    return currentUserId == post.userId;
  }

  Future<void> _markPostStatus(Post post, String status) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final originalPost = _posts[index];
    setState(() {
      _posts[index] = originalPost.copyWith(resolution: status);
    });

    try {
      await _apiService.updatePost(post.id, {'resolution': status});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Post marked as $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _posts[index] = originalPost;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _canMessageUser() {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;
    return currentUserId != widget.userId;
  }

  Future<void> _startChatWithUser([Post? post]) async {
    if (!_canMessageUser()) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to start a chat.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final chatId = await _chatService.getOrCreateChat(
        widget.userId,
        widget.userName,
        widget.userAvatar.isEmpty ? null : widget.userAvatar,
      );

      // If a post is provided, share it in chat as if the post author sent it
      if (post != null) {
        // Check if chat already exists and has messages
        final existingMessages = await _chatService.getMessages(chatId);
        
        // Only share post if this is a new chat (no messages yet)
        // This makes it appear as if the post author shared their post
        if (existingMessages.isEmpty) {
          await _chatService.sharePostInChat(
            chatId: chatId,
            postId: post.id,
            postUserId: post.userId,
            postUserName: post.userName,
            postUserAvatar: post.userAvatar.isEmpty ? null : post.userAvatar,
            postContent: post.content,
            postImageUrl: post.imageUrl,
            postType: post.type,
            postLocation: post.location,
            postContact: post.contact,
          );
        }
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'recipientId': widget.userId,
          'recipientName': widget.userName,
          'recipientAvatar': widget.userAvatar,
          if (post != null)
            'replyPost': {
              'postId': post.id,
              'postUserId': post.userId,
              'postUserName': post.userName,
              'postUserAvatar': post.userAvatar.isEmpty ? null : post.userAvatar,
              'postContent': post.content,
              'postImageUrl': post.imageUrl,
              'postType': post.type,
              'postLocation': post.location,
              'postContact': post.contact,
            },
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

