import 'package:flutter/material.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onLike;
  final VoidCallback? onTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onReplyTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkFound;
  final VoidCallback? onMarkClaimed;
  final bool canDelete; // True if current user can delete this post (own post or admin)

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onTap,
    this.onUserTap,
    this.onMessageTap,
    this.onReplyTap,
    this.onDelete,
    this.onMarkFound,
    this.onMarkClaimed,
    this.canDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: onUserTap,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: post.userAvatar.isNotEmpty
                                ? NetworkImage(post.userAvatar)
                                : null,
                            child: post.userAvatar.isEmpty
                                ? Text(
                                    post.userName.isNotEmpty
                                        ? post.userName[0].toUpperCase()
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
                                Text(
                                  post.userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  post.timeAgo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (post.resolution != null) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      post.resolution!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (onMessageTap != null)
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      tooltip: 'Message',
                      onPressed: onMessageTap,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    color: Colors.grey[600],
                    onSelected: (value) {
                      if (value == 'delete' && onDelete != null) {
                        onDelete!();
                      } else if (value == 'found' && onMarkFound != null) {
                        onMarkFound!();
                      } else if (value == 'claimed' && onMarkClaimed != null) {
                        onMarkClaimed!();
                      }
                    },
                    itemBuilder: (context) {
                      final items = <PopupMenuEntry<String>>[];
                      
                      if (post.type?.toLowerCase() == 'lost' && onMarkFound != null) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'found',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, size: 20, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Mark as Found'),
                              ],
                            ),
                          ),
                        );
                      }
                      if (post.type?.toLowerCase() == 'found' && onMarkClaimed != null) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'claimed',
                            child: Row(
                              children: [
                                Icon(Icons.verified, size: 20, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Mark as Claimed'),
                              ],
                            ),
                          ),
                        );
                      }
                      if (canDelete && onDelete != null) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Post',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      if (items.isEmpty) {
                        items.add(
                          const PopupMenuItem<String>(
                            value: 'none',
                            enabled: false,
                            child: Text('No options available'),
                          ),
                        );
                      }
                      
                      return items;
                    },
                  ),
                ],
              ),
            ),
            // Content
            if (post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            // Image if available
            if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // Like button only
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _ActionButton(
                    icon:
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                    label: post.likesCount > 0
                        ? _formatCount(post.likesCount)
                        : 'Like',
                    color: post.isLiked ? Colors.red : Colors.grey[700]!,
                    onPressed: onLike ?? () {},
                  ),
                  const SizedBox(width: 12),
                  if (onReplyTap != null)
                    _ActionButton(
                      icon: Icons.reply,
                      label: 'Reply',
                      color: Colors.grey[700]!,
                      onPressed: onReplyTap!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 14),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

