import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Post> _allPosts = [];
  Map<String, List<Post>> _postsByUser = {};

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get all posts
      final posts = await _apiService.getPosts(limit: 1000);
      
      // Group posts by user
      final Map<String, List<Post>> grouped = {};
      for (var post in posts) {
        final userId = post.userId;
        if (!grouped.containsKey(userId)) {
          grouped[userId] = [];
        }
        grouped[userId]!.add(post);
      }

      if (mounted) {
        setState(() {
          _allPosts = posts;
          _postsByUser = grouped;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load reports: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  String _getPostDescription(Post post) {
    // Extract description from post content
    final lines = post.content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('description:')) {
        return line.substring('description:'.length).trim();
      }
    }
    // Fallback to first line or content
    return post.content.split('\n').first.trim();
  }

  String _getPostItem(Post post) {
    final lines = post.content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('item:')) {
        return line.substring('item:'.length).trim();
      }
    }
    return 'Unknown Item';
  }

  String _getPostType(Post post) {
    final lines = post.content.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('type:')) {
        return line.substring('type:'.length).trim();
      }
    }
    return post.type ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
            tooltip: 'Refresh',
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadReports,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _postsByUser.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.article_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No posts found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReports,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _postsByUser.length,
                        itemBuilder: (context, index) {
                          final userId = _postsByUser.keys.elementAt(index);
                          final userPosts = _postsByUser[userId]!;
                          final firstPost = userPosts.first;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: firstPost.userAvatar.isNotEmpty
                                    ? NetworkImage(firstPost.userAvatar)
                                    : null,
                                child: firstPost.userAvatar.isEmpty
                                    ? Text(
                                        firstPost.userName.isNotEmpty
                                            ? firstPost.userName[0].toUpperCase()
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                firstPost.userName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${userPosts.length} post${userPosts.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              children: userPosts.map((post) {
                                final item = _getPostItem(post);
                                final description = _getPostDescription(post);
                                final postType = _getPostType(post);
                                final status = post.resolution ?? 'Active';
                                final isResolved = post.resolution != null;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Post Type and Status
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: postType.toLowerCase() == 'lost'
                                                  ? Colors.red[100]
                                                  : Colors.green[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              postType.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: postType.toLowerCase() == 'lost'
                                                    ? Colors.red[700]
                                                    : Colors.green[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isResolved
                                                  ? Colors.green[100]
                                                  : Colors.orange[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isResolved
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Item Name
                                      Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Description
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      if (post.location != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              post.location!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      // Date
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            post.timeAgo,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

