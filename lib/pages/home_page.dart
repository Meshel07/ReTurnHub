import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/post_card.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  String? _errorMessage;
  List<Post> _posts = [];
  int _totalUnreadCount = 0;
  int _totalUnreadNotifications = 0;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<int>? _unreadNotificationSubscription;
  bool _isAdmin = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _subscribeToUnreadCount();
    _subscribeToUnreadNotifications();
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

  @override
  void dispose() {
    _unreadCountSubscription?.cancel();
    _unreadNotificationSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToUnreadCount() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _unreadCountSubscription =
          _chatService.getTotalUnreadCountStream(currentUser.uid).listen(
        (count) {
          if (mounted) {
            setState(() {
              _totalUnreadCount = count;
            });
          }
        },
      );
    }
  }

  void _subscribeToUnreadNotifications() {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      _unreadNotificationSubscription =
          _notificationService.getUnreadCountStream(currentUser.uid).listen(
        (count) {
          if (mounted) {
            setState(() {
              _totalUnreadNotifications = count;
            });
          }
        },
      );
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final posts = await _apiService.getPosts(limit: 50);
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
        });
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  Future<void> _handleLike(Post post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final originalPost = _posts[index];
    final optimisticIsLiked = !originalPost.isLiked;
    final optimisticLikes = optimisticIsLiked
        ? originalPost.likesCount + 1
        : (originalPost.likesCount > 0 ? originalPost.likesCount - 1 : 0);

    setState(() {
      _posts[index] = originalPost.copyWith(
        isLiked: optimisticIsLiked,
        likesCount: optimisticLikes,
      );
    });

    try {
      final isNowLiked = await _apiService.toggleLike(post.id);
      if (!mounted) return;

      final currentIndex = _posts.indexWhere((p) => p.id == post.id);
      if (currentIndex == -1) return;

      final baseLikes = originalPost.likesCount;
      int resolvedLikes = baseLikes;
      if (isNowLiked) {
        resolvedLikes = baseLikes + 1;
      } else if (baseLikes > 0) {
        resolvedLikes = baseLikes - 1;
      } else {
        resolvedLikes = 0;
      }

      setState(() {
        _posts[currentIndex] = _posts[currentIndex].copyWith(
          isLiked: isNowLiked,
          likesCount: resolvedLikes,
        );
      });
    } catch (e) {
      if (!mounted) return;
      final currentIndex = _posts.indexWhere((p) => p.id == post.id);
      if (currentIndex != -1) {
        setState(() {
          _posts[currentIndex] = originalPost;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePostTap(Post post) {
    Navigator.pushNamed(
      context,
      '/postDetails',
      arguments: post,
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

  void _openUserTimeline(Post post) {
    Navigator.pushNamed(
      context,
      '/userTimeline',
      arguments: {
        'userId': post.userId,
        'userName': post.userName,
        'userAvatar': post.userAvatar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ReTurnHub',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            tooltip: 'Search',
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                tooltip: 'Notifications',
              ),
              if (_totalUnreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _totalUnreadNotifications > 99
                          ? '99+'
                          : _totalUnreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {
                  Navigator.pushNamed(context, '/chatList');
                },
                tooltip: 'Messages',
              ),
              if (_totalUnreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _totalUnreadCount > 99 ? '99+' : _totalUnreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuSelection,
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[];
              
              if (_isAdmin) {
                items.add(
                  const PopupMenuItem(
                    value: 'reports',
                    child: Row(
                      children: [
                        Icon(Icons.assessment, size: 18),
                        SizedBox(width: 8),
                        Text('Reports'),
                      ],
                    ),
                  ),
                );
                items.add(
                  const PopupMenuDivider(),
                );
              }
              
              items.add(
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18),
                      SizedBox(width: 8),
                      Text('Logout'),
                    ],
                  ),
                ),
              );
              
              return items;
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _isLoading && _posts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _refreshPosts,
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _posts.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.article_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No posts yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _refreshPosts,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _posts.length,
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          final canDelete = post.userId == _currentUserId || _isAdmin;
                          return PostCard(
                            post: post,
                            onLike: () => _handleLike(post),
                            onTap: () => _handlePostTap(post),
                            onUserTap: () => _openUserTimeline(post),
                            onMessageTap: _canMessageUser(post)
                                ? () => _startChatWithUser(post)
                                : null,
                            onReplyTap: _canMessageUser(post)
                                ? () => _composeReply(post)
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
                      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/createPost');
          if (!mounted) return;
          if (result is Post) {
            setState(() {
              _posts.insert(0, result);
            });
          } else if (result == true) {
            await _refreshPosts();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Post',
      ),
    );
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'logout') {
      try {
        await _authService.signOut();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (value == 'reports') {
      Navigator.pushNamed(context, '/reports');
    }
  }

  bool _canMessageUser(Post post) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;
    return currentUserId != post.userId;
  }

  bool _canManageStatus(Post post) {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return false;
    return currentUserId == post.userId;
  }

  Future<void> _markPostStatus(Post post, String status) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    // Optimistic UI update
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
      // Revert on error
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

  Future<void> _composeReply(Post post) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to reply.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final controller = TextEditingController();
    final result = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Reply to ${post.userName}'s post",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.content.split('\n').first,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: null,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type your reply…',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  Navigator.pop(context, value.trim().isEmpty ? null : value.trim());
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send'),
                  onPressed: () {
                    final text = controller.text.trim();
                    Navigator.pop(context, text.isEmpty ? null : text);
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    await _sendReplyToChat(post, result);
  }

  Future<void> _sendReplyToChat(Post post, String messageText) async {
    try {
      final chatId = await _chatService.getOrCreateChat(
        post.userId,
        post.userName,
        post.userAvatar.isEmpty ? null : post.userAvatar,
      );

      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userData = await _authService.getUserData(currentUser.uid);
      final senderName = userData?.name ?? currentUser.displayName ?? 'You';
      final senderAvatar = userData?.profileImage ?? currentUser.photoURL;

      await _chatService.sendMessage(
        chatId: chatId,
        senderId: currentUser.uid,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: messageText,
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

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'recipientId': post.userId,
          'recipientName': post.userName,
          'recipientAvatar': post.userAvatar,
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
          content: Text('Failed to send reply: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startChatWithUser(Post post, {bool asReply = false}) async {
    if (!_canMessageUser(post)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot message yourself.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
        post.userId,
        post.userName,
        post.userAvatar.isEmpty ? null : post.userAvatar,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'recipientId': post.userId,
          'recipientName': post.userName,
          'recipientAvatar': post.userAvatar,
          if (asReply)
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

