import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/post_service.dart';
import '../models/post_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final List<AppNotification> _notifications = [];
  StreamSubscription<List<AppNotification>>? _notificationSubscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _initNotifications() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You must be logged in to view notifications.';
      });
      return;
    }

    _loadInitialNotifications(currentUser.uid);

    _notificationSubscription = _notificationService
        .getNotificationsStream(currentUser.uid)
        .listen(
          (notifications) {
            if (mounted) {
              setState(() {
                _notifications
                  ..clear()
                  ..addAll(notifications);
                _isLoading = false;
                _errorMessage = null;
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.toString();
              });
            }
          },
        );
  }

  Future<void> _loadInitialNotifications(String userId) async {
    try {
      final notifications = await _notificationService.getNotifications(userId);
      if (!mounted) return;
      setState(() {
        _notifications
          ..clear()
          ..addAll(notifications);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    try {
      await _notificationService.markAllAsRead(currentUser.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark all as read: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotification notification) async {
    // Mark as read
    if (!notification.isRead) {
      await _notificationService.markAsRead(notification.id);
    }

    if (!mounted) return;

    if ((notification.type == 'like' || notification.type == 'comment') &&
        notification.postId != null) {
      // Navigate to post details
      final postService = PostService();
      try {
        final post = await postService.getPostById(notification.postId!);
        if (!mounted) return;
        if (post != null) {
          Navigator.pushNamed(context, '/postDetails', arguments: post);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading post: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (notification.type == 'message' && notification.chatId != null) {
      // Navigate to chat
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': notification.chatId,
          'recipientId': notification.senderId ?? '',
          'recipientName': notification.senderName ?? 'User',
          'recipientAvatar': notification.senderAvatar ?? '',
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _NotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                );
              },
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isLike = notification.type == 'like';
    final isComment = notification.type == 'comment';

    String? avatarUrl;
    String? avatarName;
    if (isLike) {
      avatarUrl = notification.likerAvatar;
      avatarName = notification.likerName;
    } else if (isComment) {
      avatarUrl = notification.commenterAvatar;
      avatarName = notification.commenterName;
    } else {
      avatarUrl = notification.senderAvatar;
      avatarName = notification.senderName;
    }

    IconData icon;
    Color iconColor;
    if (isLike) {
      icon = Icons.favorite;
      iconColor = Colors.red;
    } else if (isComment) {
      icon = Icons.comment;
      iconColor = Colors.deepPurple;
    } else {
      icon = Icons.message;
      iconColor = Colors.blue;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[300],
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      avatarName?.isNotEmpty == true
                          ? avatarName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: iconColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
