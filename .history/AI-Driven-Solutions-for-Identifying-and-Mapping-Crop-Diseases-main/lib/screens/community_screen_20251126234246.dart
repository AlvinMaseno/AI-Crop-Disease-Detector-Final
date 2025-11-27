import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/app_provider.dart';
// Ensure this import points to your existing CardWidget
import '../widgets/card_widget.dart'; 

// --- INTERNAL MODELS FOR UI ---
class ForumPost {
  final String id;
  final String userName;
  final String userAvatar; // Initials
  final String timeAgo;
  final String content;
  final String category; // e.g., "Question", "Success Story", "Market"
  int likes;
  int comments;
  bool isLiked;

  ForumPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.timeAgo,
    required this.content,
    required this.category,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });

  // Serialization for saving to phone storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userName': userName,
      'userAvatar': userAvatar,
      'timeAgo': timeAgo,
      'content': content,
      'category': category,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
    };
  }

  factory ForumPost.fromMap(Map<String, dynamic> map) {
    return ForumPost(
      id: map['id'],
      userName: map['userName'],
      userAvatar: map['userAvatar'],
      timeAgo: map['timeAgo'],
      content: map['content'],
      category: map['category'],
      likes: map['likes'],
      comments: map['comments'],
      isLiked: map['isLiked'] ?? false,
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ForumPost> _posts = [];
  bool _isLoading = true;

  // --- EXISTING RESOURCES DATA ---
  final List<Map<String, dynamic>> _agriculturalTips = [
    {'title': 'Soil Health', 'desc': 'Test soil pH every 2 years.', 'icon': Icons.grass, 'color': Colors.green},
    {'title': 'Watering', 'desc': 'Drip irrigation saves 40% water.', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'title': 'Pest Control', 'desc': 'Use marigolds to repel nematodes.', 'icon': Icons.bug_report, 'color': Colors.orange},
    {'title': 'Rotation', 'desc': 'Rotate Maize with Beans.', 'icon': Icons.autorenew, 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _usefulLinks = [
    {'title': 'Ministry of Agriculture', 'url': 'https://kilimo.go.ke', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'title': 'KALRO Research', 'url': 'https://kalro.org', 'icon': Icons.science, 'color': Colors.green},
    {'title': 'Market Prices', 'url': 'https://sokopepe.co.ke', 'icon': Icons.trending_up, 'color': Colors.orange},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPosts();
  }

  // Load posts from storage
  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? postsJson = prefs.getString('community_posts');

    if (postsJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(postsJson);
        setState(() {
          _posts = decodedList.map((item) => ForumPost.fromMap(item)).toList();
          _isLoading = false;
        });
      } catch (e) {
        _initializeDummyPosts();
      }
    } else {
      _initializeDummyPosts();
    }
  }

  void _initializeDummyPosts() {
    setState(() {
      _posts = [
        ForumPost(
          id: '1',
          userName: 'Sarah Wanjiku',
          userAvatar: 'SW',
          timeAgo: '2 hrs ago',
          category: 'Question',
          content: 'I noticed these yellow spots on my Maize leaves this morning. Is this Nitrogen deficiency or a disease? I applied DAP last week.',
          likes: 12,
          comments: 4,
        ),
        ForumPost(
          id: '2',
          userName: 'David Ochieng',
          userAvatar: 'DO',
          timeAgo: '5 hrs ago',
          category: 'Success Story',
          content: 'Finally managed to control the Fall Armyworm infestation! The Neem oil mixture worked wonders. Harvest looking good this season! 🌽',
          likes: 45,
          comments: 18,
        ),
        ForumPost(
          id: '3',
          userName: 'Grace M.',
          userAvatar: 'GM',
          timeAgo: '1 day ago',
          category: 'Market',
          content: 'Does anyone know the current buying price for Tomatoes in Nairobi Marikiti market?',
          likes: 8,
          comments: 23,
        ),
      ];
      _isLoading = false;
    });
    _savePosts();
  }

  // Save posts to storage
  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(
      _posts.map((post) => post.toMap()).toList()
    );
    await prefs.setString('community_posts', encodedData);
  }

  // Add a new post
  void _addNewPost(String content, String category) {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    final userName = user?.name ?? 'Me';
    final initials = userName.isNotEmpty ? userName.substring(0, 2).toUpperCase() : 'ME';

    final newPost = ForumPost(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userName: userName,
      userAvatar: initials,
      timeAgo: 'Just now',
      content: content,
      category: category,
    );

    setState(() {
      _posts.insert(0, newPost);
    });
    _savePosts();
  }

  // Show dialog to create post
  void _showCreatePostDialog() {
    String selectedCategory = 'Question';
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Create Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  items: ['Question', 'Success Story', 'Market']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedCategory = val!),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'What\'s on your mind?',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (contentController.text.trim().isNotEmpty) {
                    _addNewPost(contentController.text.trim(), selectedCategory);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Post published successfully!')),
                    );
                  }
                },
                child: const Text('Post'),
              ),
            ],
          );
        }
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Community'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.primaryColor,
          labelColor: theme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Discussion Forum', icon: Icon(Icons.forum_outlined)),
            Tab(text: 'Resources & Tips', icon: Icon(Icons.library_books_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : TabBarView(
            controller: _tabController,
            children: [
              _buildForumTab(theme),
              _buildResourcesTab(theme),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog, // NOW FUNCTIONAL
        label: const Text('Ask Question'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  // --- TAB 1: DISCUSSION FORUM ---
  Widget _buildForumTab(ThemeData theme) {
    if (_posts.isEmpty) {
      return Center(child: Text("No posts yet. Be the first to ask!", style: TextStyle(color: Colors.grey[600])));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primaryColor.withOpacity(0.2),
                      child: Text(
                        post.userAvatar,
                        style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            post.timeAgo,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Chip(
                      label: Text(post.category),
                      labelStyle: const TextStyle(fontSize: 10, color: Colors.white),
                      backgroundColor: _getCategoryColor(post.category),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                Text(
                  post.content,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Divider(),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                      label: '${post.likes} Likes',
                      color: post.isLiked ? theme.primaryColor : Colors.grey,
                      onTap: () {
                        setState(() {
                          post.isLiked = !post.isLiked;
                          post.isLiked ? post.likes++ : post.likes--;
                        });
                        _savePosts(); // Save like state
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.comment_outlined,
                      label: '${post.comments} Comments',
                      color: Colors.grey,
                      onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comments feature coming in V2')),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      color: Colors.grey,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Question': return Colors.orange;
      case 'Success Story': return Colors.green;
      case 'Market': return Colors.blue;
      default: return Colors.grey;
    }
  }

  // --- TAB 2: RESOURCES ---
  Widget _buildResourcesTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Agricultural Tips", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _agriculturalTips.length,
            itemBuilder: (context, index) {
              final tip = _agriculturalTips[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tip['icon'], color: tip['color'], size: 32),
                      const Spacer(),
                      Text(tip['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(tip['desc'], style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          const Text("External Resources", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ..._usefulLinks.map((link) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (link['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(link['icon'], color: link['color']),
            ),
            title: Text(link['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
            trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Opening ${link['url']}")));
            },
          )),
        ],
      ),
    );
  }
}