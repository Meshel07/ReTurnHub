import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String recipientName;
  final String recipientAvatar;
  final Map<String, dynamic>? initialReplyPost;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar = '',
    this.initialReplyPost,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final List<Message> _messages = [];
  StreamSubscription<List<Message>>? _messageSubscription;
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  Map<String, dynamic>? _replyingPost;

  @override
  void initState() {
    super.initState();
    _replyingPost = widget.initialReplyPost;
    _subscribeToMessages();
    _markChatAsRead();
  }

  Future<void> _markChatAsRead() async {
    try {
      await _chatService.markChatAsRead(widget.chatId);
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMessages() {
    try {
      _messageSubscription =
          _chatService.getMessagesStream(widget.chatId).listen((messages) {
        if (!mounted) return;
        setState(() {
          _messages
            ..clear()
            ..addAll(messages);
          _isLoading = false;
          _errorMessage = null;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }, onError: (error) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to send messages.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final userData = await _authService.getUserData(currentUser.uid);
      final senderName =
          userData?.name ?? currentUser.displayName ?? 'You';
      final senderAvatar =
          userData?.profileImage ?? currentUser.photoURL;

      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: senderName,
        senderAvatar: senderAvatar,
        content: text,
        postId: _replyingPost?['postId'] as String?,
        postUserId: _replyingPost?['postUserId'] as String?,
        postUserName: _replyingPost?['postUserName'] as String?,
        postUserAvatar: _replyingPost?['postUserAvatar'] as String?,
        postContent: _replyingPost?['postContent'] as String?,
        postImageUrl: _replyingPost?['postImageUrl'] as String?,
        postType: _replyingPost?['postType'] as String?,
        postLocation: _replyingPost?['postLocation'] as String?,
        postContact: _replyingPost?['postContact'] as String?,
      );

      _messageController.clear();
      // Clear reply context after sending
      if (_replyingPost != null) {
        setState(() {
          _replyingPost = null;
        });
      }
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.recipientAvatar.isNotEmpty
                  ? NetworkImage(widget.recipientAvatar)
                  : null,
              child: widget.recipientAvatar.isEmpty
                  ? Text(
                      widget.recipientName.isNotEmpty
                          ? widget.recipientName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 16,
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
                  Text(
                    widget.recipientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Private chat',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show more options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_replyingPost != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.reply, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Replying to ${_replyingPost?['postUserName'] ?? widget.recipientName}'s post",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if ((_replyingPost?['postContent'] as String? ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              (_replyingPost?['postContent'] as String?)!.split('\n').first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyingPost = null;
                      });
                    },
                    child: const Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    : _messages.isEmpty
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
                                  'No messages yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start the conversation!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final previousMessage =
                                  index > 0 ? _messages[index - 1] : null;
                              final showTimestamp = message
                                  .shouldShowTimestamp(previousMessage);

                              // Handle system messages (post replies) differently
                              if (message.messageType == 'post_reply') {
                                return _PostReplySystemMessage(
                                  message: message,
                                  showTimestamp: showTimestamp,
                                );
                              }

                              return _MessageBubble(
                                message: message,
                                showTimestamp: showTimestamp,
                              );
                            },
                          ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: () {
                        // TODO: Show attachment options
                      },
                      color: Colors.grey[600],
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: _replyingPost != null
                                ? "Reply to ${_replyingPost?['postUserName'] ?? widget.recipientName}'s post..."
                                : 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            hintStyle: TextStyle(color: Colors.grey[600]),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {
                        // TODO: Show emoji picker
                      },
                      color: Colors.grey[600],
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: _isSending
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _isSending ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool showTimestamp;

  const _MessageBubble({
    required this.message,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isSent = message.isSentByMe;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment:
          isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDateLabel(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment:
                isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isSent) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: (message.senderAvatar ?? '').isNotEmpty
                      ? NetworkImage(message.senderAvatar!)
                      : null,
                  child: (message.senderAvatar ?? '').isEmpty
                      ? Text(
                          message.senderName.isNotEmpty
                              ? message.senderName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSent
                        ? theme.colorScheme.primary
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isSent ? 18 : 4),
                      bottomRight: Radius.circular(isSent ? 4 : 18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show post card if message contains post information
                      if (message.postId != null) ...[
                        _PostPreviewCard(
                          postId: message.postId!,
                          postUserId: message.postUserId ?? '',
                          postUserName: message.postUserName ?? '',
                          postUserAvatar: message.postUserAvatar ?? '',
                          postContent: message.postContent ?? '',
                          postImageUrl: message.postImageUrl,
                          postType: message.postType,
                          postLocation: message.postLocation,
                          postContact: message.postContact,
                          isSent: isSent,
                        ),
                        // Only show message text if it's not just "Shared a post"
                        if (message.content != 'Shared a post') ...[
                          const SizedBox(height: 8),
                          Text(
                            message.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSent ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ] else
                        // Regular message without post
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 15,
                            color: isSent ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        message.timeString,
                        style: TextStyle(
                          fontSize: 11,
                          color: isSent
                              ? Colors.white70
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _PostReplySystemMessage extends StatelessWidget {
  final Message message;
  final bool showTimestamp;

  const _PostReplySystemMessage({
    required this.message,
    required this.showTimestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTimestamp)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getDateLabel(message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        // System message text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Center(
            child: Text(
              message.content, // "You replied to [username]'s post"
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        // Post preview
        if (message.postId != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Center(
              child: _PostPreviewCard(
                postId: message.postId!,
                postUserId: message.postUserId ?? '',
                postUserName: message.postUserName ?? '',
                postUserAvatar: message.postUserAvatar ?? '',
                postContent: message.postContent ?? '',
                postImageUrl: message.postImageUrl,
                postType: message.postType,
                postLocation: message.postLocation,
                postContact: message.postContact,
                isSent: false, // Post preview always appears as received
              ),
            ),
          ),
      ],
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
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
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }
}

class _PostPreviewCard extends StatelessWidget {
  final String postId;
  final String postUserId;
  final String postUserName;
  final String postUserAvatar;
  final String postContent;
  final String? postImageUrl;
  final String? postType;
  final String? postLocation;
  final String? postContact;
  final bool isSent;

  const _PostPreviewCard({
    required this.postId,
    required this.postUserId,
    required this.postUserName,
    required this.postUserAvatar,
    required this.postContent,
    this.postImageUrl,
    this.postType,
    this.postLocation,
    this.postContact,
    required this.isSent,
  });

  @override
  Widget build(BuildContext context) {
    // Parse post content to extract details
    Map<String, String> parseContent(String content) {
      final Map<String, String> parsed = {};
      final lines = content.split('\n');
      for (var line in lines) {
        if (line.contains('Type:')) {
          parsed['type'] = line.split('Type:')[1].trim();
        } else if (line.contains('Item:')) {
          parsed['item'] = line.split('Item:')[1].trim();
        } else if (line.contains('Description:')) {
          parsed['description'] = line.split('Description:')[1].trim();
        } else if (line.contains('Location:')) {
          parsed['location'] = line.split('Location:')[1].trim();
        } else if (line.contains('Date:')) {
          parsed['date'] = line.split('Date:')[1].trim();
        } else if (line.contains('Contact:')) {
          parsed['contact'] = line.split('Contact:')[1].trim();
        }
      }
      return parsed;
    }

    final parsed = parseContent(postContent);
    final postTypeDisplay = postType ?? parsed['type'] ?? 'Post';
    final isLost = postTypeDisplay.toLowerCase() == 'lost';

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isSent ? Colors.white.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSent ? Colors.white.withOpacity(0.3) : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: postUserAvatar.isNotEmpty
                      ? NetworkImage(postUserAvatar)
                      : null,
                  child: postUserAvatar.isEmpty
                      ? Text(
                          postUserName.isNotEmpty
                              ? postUserName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postUserName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSent ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (postTypeDisplay.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isLost
                                ? Colors.red.withOpacity(isSent ? 0.3 : 0.2)
                                : Colors.green.withOpacity(isSent ? 0.3 : 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            postTypeDisplay.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSent
                                  ? Colors.white
                                  : (isLost ? Colors.red[700] : Colors.green[700]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Post image if available
          if (postImageUrl != null && postImageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Image.network(
                postImageUrl!,
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 32),
                  );
                },
              ),
            )
          else if (parsed['item'] != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                parsed['item']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSent ? Colors.white : Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

