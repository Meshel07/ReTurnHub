import 'package:flutter/material.dart';
import '../models/post_model.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Post> _posts = [];
  List<Post> _filteredPosts = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterPosts();
    });
  }

  void _filterPosts() {
    if (_searchQuery.isEmpty) {
      _filteredPosts = List.from(_posts);
    } else {
      _filteredPosts = _posts
          .where((post) =>
              post.content.toLowerCase().contains(_searchQuery) ||
              post.userName.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _posts = _getSamplePosts();
      _filterPosts();
      _isLoading = false;
    });
  }

  Future<void> _deletePost(Post post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: Text(
          'Are you sure you want to delete this post by ${post.userName}? This action cannot be undone.',
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

    if (confirmed == true) {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              const Text('Deleting post...'),
            ],
          ),
          duration: const Duration(seconds: 1),
        ),
      );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _posts.removeWhere((p) => p.id == post.id);
        _filterPosts();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Posts',
                    value: _posts.length.toString(),
                    icon: Icons.article,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Filtered',
                    value: _filteredPosts.length.toString(),
                    icon: Icons.filter_list,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search posts by content or author...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Posts List
          Expanded(
            child: _isLoading && _posts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.article_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No posts found'
                                  : 'No posts yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  _searchController.clear();
                                },
                                child: const Text('Clear search'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshPosts,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredPosts.length,
                          itemBuilder: (context, index) {
                            final post = _filteredPosts[index];
                            return _AdminPostCard(
                              post: post,
                              onDelete: () => _deletePost(post),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Post> _getSamplePosts() {
    final now = DateTime.now();
    return [
      Post(
        id: '1',
        userId: 'user1',
        userName: 'John Doe',
        userAvatar: '',
        content:
            'Just finished an amazing project! Excited to share it with everyone. The journey has been incredible and I\'ve learned so much along the way.',
        imageUrl: null,
        createdAt: now.subtract(const Duration(hours: 2)),
        likesCount: 42,
        commentsCount: 8,
        isLiked: false,
      ),
      Post(
        id: '2',
        userId: 'user2',
        userName: 'Jane Smith',
        userAvatar: '',
        content:
            'Beautiful sunset today! 🌅 Sometimes the best moments are the simplest ones.',
        imageUrl: null,
        createdAt: now.subtract(const Duration(hours: 5)),
        likesCount: 128,
        commentsCount: 15,
        isLiked: true,
      ),
      Post(
        id: '3',
        userId: 'user3',
        userName: 'Mike Johnson',
        userAvatar: '',
        content:
            'Working on something exciting! Can\'t wait to reveal it soon. Stay tuned for updates!',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 1)),
        likesCount: 67,
        commentsCount: 12,
        isLiked: false,
      ),
      Post(
        id: '4',
        userId: 'user4',
        userName: 'Sarah Williams',
        userAvatar: '',
        content:
            'Just had the best coffee at the new café downtown. Highly recommend checking it out!',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 2)),
        likesCount: 89,
        commentsCount: 23,
        isLiked: true,
      ),
      Post(
        id: '5',
        userId: 'user5',
        userName: 'David Brown',
        userAvatar: '',
        content:
            'Learning new technologies is always exciting. Today I\'m diving deep into Flutter development. The possibilities are endless!',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 3)),
        likesCount: 156,
        commentsCount: 34,
        isLiked: false,
      ),
      Post(
        id: '6',
        userId: 'user6',
        userName: 'Emily Davis',
        userAvatar: '',
        content:
            'Sharing some thoughts on modern web development. The ecosystem is evolving rapidly!',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 4)),
        likesCount: 203,
        commentsCount: 45,
        isLiked: false,
      ),
      Post(
        id: '7',
        userId: 'user7',
        userName: 'Robert Wilson',
        userAvatar: '',
        content:
            'Great meeting today with the team. We\'re making excellent progress on our goals!',
        imageUrl: null,
        createdAt: now.subtract(const Duration(days: 5)),
        likesCount: 91,
        commentsCount: 18,
        isLiked: true,
      ),
    ];
  }
}

class _AdminPostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onDelete;

  const _AdminPostCard({
    required this.post,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
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
                        post.userName,
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
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete post',
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            // Post stats
            Row(
              children: [
                _StatChip(
                  icon: Icons.favorite_outline,
                  label: '${post.likesCount} likes',
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  icon: Icons.comment_outlined,
                  label: '${post.commentsCount} comments',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

