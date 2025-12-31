import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../widgets/comment_title.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class PostDetailsPage extends StatefulWidget {
  final Post post;

  const PostDetailsPage({super.key, required this.post});

  @override
  State<PostDetailsPage> createState() => _PostDetailsPageState();
}

class _PostDetailsPageState extends State<PostDetailsPage> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<CommentData> _comments = [];
  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;

  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();

  // Parse post content to extract details
  Map<String, String> get _parsedContent {
    final content = widget.post.content;
    final Map<String, String> parsed = {};

    // Parse the content string
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

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoadingComments = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample comments - Replace with actual API call
    setState(() {
      _comments.addAll(_getSampleComments());
      _isLoadingComments = false;
    });
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      // Get current user
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to comment');
      }

      // Get user data
      final userData = await _authService.getUserData(currentUser.uid);
      if (userData == null) {
        throw Exception('User data not found');
      }

      // Submit comment
      await _apiService.submitComment(
        postId: widget.post.id,
        userId: currentUser.uid,
        userName: userData.name,
        userAvatar: userData.profileImage,
        comment: commentText,
      );

      // Add comment to list
      final newComment = CommentData(
        userName: userData.name,
        userAvatar: userData.profileImage ?? '',
        comment: commentText,
        timestamp: DateTime.now(),
      );

      setState(() {
        _comments.add(newComment);
        _commentController.clear();
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting comment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  Future<void> _navigateToChat() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to start a chat.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentUser.uid == widget.post.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot chat with yourself.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final chatId = await _chatService.getOrCreateChat(
        widget.post.userId,
        widget.post.userName,
        widget.post.userAvatar.isEmpty ? null : widget.post.userAvatar,
      );

      // Check if chat already exists and has messages
      final existingMessages = await _chatService.getMessages(chatId);
      
      // Only share post if this is a new chat (no messages yet)
      // This makes it appear as if the post author shared their post
      if (existingMessages.isEmpty) {
        await _chatService.sharePostInChat(
          chatId: chatId,
          postId: widget.post.id,
          postUserId: widget.post.userId,
          postUserName: widget.post.userName,
          postUserAvatar: widget.post.userAvatar.isEmpty ? null : widget.post.userAvatar,
          postContent: widget.post.content,
          postImageUrl: widget.post.imageUrl,
          postType: widget.post.type,
          postLocation: widget.post.location,
          postContact: widget.post.contact,
        );
      }

      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/chat',
        arguments: {
          'chatId': chatId,
          'recipientId': widget.post.userId,
          'recipientName': widget.post.userName,
          'recipientAvatar': widget.post.userAvatar,
          'replyPost': {
            'postId': widget.post.id,
            'postUserId': widget.post.userId,
            'postUserName': widget.post.userName,
            'postUserAvatar': widget.post.userAvatar.isEmpty ? null : widget.post.userAvatar,
            'postContent': widget.post.content,
            'postImageUrl': widget.post.imageUrl,
            'postType': widget.post.type,
            'postLocation': widget.post.location,
            'postContact': widget.post.contact,
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

  void _openUserTimeline() {
    Navigator.pushNamed(
      context,
      '/userTimeline',
      arguments: {
        'userId': widget.post.userId,
        'userName': widget.post.userName,
        'userAvatar': widget.post.userAvatar,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsedContent;
    final postType = parsed['type'] ?? 'Lost';
    final isLost = postType.toLowerCase() == 'lost';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              if (widget.post.imageUrl != null &&
                  widget.post.imageUrl!.isNotEmpty)
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  child: Image.network(
                    widget.post.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                ),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isLost ? Colors.red[100] : Colors.green[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        postType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isLost ? Colors.red[700] : Colors.green[700],
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      parsed['item'] ?? 'Unknown Item',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (parsed['description'] != null) ...[
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        parsed['description']!,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (parsed['date'] != null)
                            _DetailRow(
                              icon: Icons.calendar_today,
                              label: 'Date Lost/Found',
                              value: parsed['date']!,
                            ),
                          if (parsed['location'] != null) ...[
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.location_on,
                              label: 'Location',
                              value: parsed['location']!,
                            ),
                          ],
                          if (parsed['contact'] != null) ...[
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.contact_phone,
                              label: 'Contact',
                              value: parsed['contact']!,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _openUserTimeline,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: widget.post.userAvatar.isNotEmpty
                                ? NetworkImage(widget.post.userAvatar)
                                : null,
                            child: widget.post.userAvatar.isEmpty
                                ? Text(
                                    widget.post.userName.isNotEmpty
                                        ? widget.post.userName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 14,
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
                                const Text(
                                  'Posted by',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  widget.post.userName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            widget.post.timeAgo,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  onPressed: _navigateToChat,
                  icon: const Icon(Icons.message),
                  label: const Text('Message Owner'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_comments.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoadingComments)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.comment_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No comments yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._comments.map(
                        (comment) => CommentTile(
                          userName: comment.userName,
                          userAvatar: comment.userAvatar,
                          comment: comment.comment,
                          timestamp: comment.timestamp,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a comment',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            maxLines: null,
                            textCapitalization:
                                TextCapitalization.sentences,
                            onSubmitted: (_) => _submitComment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: _isSubmittingComment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white),
                            onPressed: _isSubmittingComment
                                ? null
                                : _submitComment,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  List<CommentData> _getSampleComments() {
    final now = DateTime.now();
    return [
      CommentData(
        userName: 'John Doe',
        userAvatar: '',
        comment:
            'I think I saw something similar near the park yesterday. Let me check!',
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      CommentData(
        userName: 'Jane Smith',
        userAvatar: '',
        comment: 'Hope you find it soon!',
        timestamp: now.subtract(const Duration(hours: 1)),
      ),
    ];
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class CommentData {
  final String userName;
  final String userAvatar;
  final String comment;
  final DateTime timestamp;

  CommentData({
    required this.userName,
    this.userAvatar = '',
    required this.comment,
    required this.timestamp,
  });
}
