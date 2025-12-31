import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final List<ChatPreview> _chats = [];
  StreamSubscription<List<Map<String, dynamic>>>? _chatSubscription;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initChats();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  void _initChats() {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'You must be logged in to view messages.';
      });
      return;
    }

    _loadInitialChats(currentUser.uid);

    _chatSubscription =
        _chatService.getChatListStream(currentUser.uid).listen((chatMaps) {
      final chats =
          chatMaps.map((map) => ChatPreview.fromMap(map)).toList();
      if (mounted) {
        setState(() {
          _chats
            ..clear()
            ..addAll(chats);
          _isLoading = false;
          _errorMessage = null;
        });
      }
    }, onError: (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
    });
  }

  Future<void> _loadInitialChats(String userId) async {
    try {
      final chatMaps = await _chatService.getChatList(userId);
      final chats = chatMaps.map((map) => ChatPreview.fromMap(map)).toList();
      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(chats);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _openUserSearch();
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
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
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
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
              : _chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        final chat = _chats[index];
                        return ListTile(
                          leading: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[300],
                                backgroundImage:
                                    (chat.recipientAvatar ?? '').isNotEmpty
                                        ? NetworkImage(
                                            chat.recipientAvatar!,
                                          )
                                        : null,
                                child: (chat.recipientAvatar ?? '').isEmpty
                                    ? Text(
                                        chat.recipientName.isNotEmpty
                                            ? chat.recipientName[0]
                                                .toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              if (chat.unreadCount > 0)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: chat.unreadCount > 9
                                        ? const Text(
                                            '9+',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                        : Text(
                                            chat.unreadCount.toString(),
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
                          title: Text(
                            chat.recipientName,
                            style: TextStyle(
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            chat.lastMessage ?? 'No messages yet',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: chat.unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontWeight: chat.unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _getTimeLabel(chat.lastMessageTime),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: chat.unreadCount > 0
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey[600],
                                      fontWeight: chat.unreadCount > 0
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  if (chat.unreadCount > 0)
                                    const SizedBox(height: 4),
                                ],
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _handleDeleteChat(chat);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 20, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () async {
                            // Mark chat as read when opening
                            await _chatService.markChatAsRead(chat.chatId);
                            
                            if (!mounted) return;
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: {
                                'chatId': chat.chatId,
                                'recipientId': chat.recipientId,
                                'recipientName': chat.recipientName,
                                'recipientAvatar': chat.recipientAvatar ?? '',
                              },
                            );
                          },
                        );
                      },
                    ),
    );
  }

  Future<void> _handleDeleteChat(ChatPreview chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete this conversation with ${chat.recipientName}? This action cannot be undone.',
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
        await _chatService.deleteChat(chat.chatId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chat deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete chat: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openUserSearch() async {
    final selectedUser = await showSearch<UserModel?>(
      context: context,
      delegate: UserSearchDelegate(authService: _authService),
    );

    if (selectedUser != null) {
      await _startChatWithUser(selectedUser);
    }
  }

  Future<void> _startChatWithUser(UserModel user) async {
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

    if (user.id == currentUser.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot start a chat with yourself.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final chatId = await _chatService.getOrCreateChat(
        user.id,
        user.name,
        user.profileImage,
      );

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'recipientId': user.id,
          'recipientName': user.name,
          'recipientAvatar': user.profileImage ?? '',
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open chat: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTimeLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

class ChatPreview {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;

  ChatPreview({
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory ChatPreview.fromMap(Map<String, dynamic> map) {
    return ChatPreview(
      chatId: map['chatId'] as String,
      recipientId: map['recipientId'] as String,
      recipientName: map['recipientName'] as String? ?? 'User',
      recipientAvatar: map['recipientAvatar'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] as DateTime?,
      unreadCount: (map['unreadCount'] as int?) ?? 0,
    );
  }
}

class UserSearchDelegate extends SearchDelegate<UserModel?> {
  final AuthService authService;

  UserSearchDelegate({required this.authService});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: 'Clear search',
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Search by username to start a chat'),
        ),
      );
    }

    return FutureBuilder<List<UserModel>>(
      future: authService.searchUsersByName(trimmed),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to search users: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No users found. Try a different name.'),
            ),
          );
        }

        return ListView.separated(
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final user = results[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.grey[300],
                backgroundImage: (user.profileImage ?? '').isNotEmpty
                    ? NetworkImage(user.profileImage!)
                    : null,
                child: (user.profileImage ?? '').isEmpty
                    ? Text(
                        user.initials,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              onTap: () => close(context, user),
            );
          },
        );
      },
    );
  }
}

