import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Real Database
import '../providers/app_provider.dart';
// Ensure this import points to your existing CardWidget
import '../widgets/card_widget.dart'; 

// --- INTERNAL MODEL FOR UI ---
class ForumPost {
  final String id;
  final String userName;
  final String userAvatar;
  final DateTime timestamp; // Changed to DateTime for real sorting
  final String content;
  final String category;
  final int likesCount;
  final List<String> likedBy; // List of User IDs who liked this
  final int comments;

  ForumPost({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.timestamp,
    required this.content,
    required this.category,
    this.likesCount = 0,
    this.likedBy = const [],
    this.comments = 0,
  });

  // Helper to calculate "2 hrs ago" from real timestamp
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userAvatar': userAvatar,
      'timestamp': Timestamp.fromDate(timestamp), // Store as Firestore Timestamp
      'content': content,
      'category': category,
      'likesCount': likesCount,
      'likedBy': likedBy,
      'comments': comments,
    };
  }

  factory ForumPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ForumPost(
      id: doc.id,
      userName: data['userName'] ?? 'Anonymous',
      userAvatar: data['userAvatar'] ?? '?',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      content: data['content'] ?? '',
      category: data['category'] ?? 'General',
      likesCount: data['likesCount'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: data['comments'] ?? 0,
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
  
  // Reference to Firestore Collection
  final CollectionReference _postsRef = FirebaseFirestore.instance.collection('posts');

  // --- RESOURCES DATA (Static) ---
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- FIREBASE ACTIONS ---

  Future<void> _addNewPost(String content, String category) async {
    final appProvider = context.read<AppProvider>();
    final user = appProvider.currentUser;
    final userName = user?.name ?? 'Farmer';
    
    String initials = "ME";
    if (userName.isNotEmpty) {
      initials = userName.length >= 2 
          ? userName.substring(0, 2).toUpperCase() 
          : userName.toUpperCase();
    }

    // Add to Firestore
    await _postsRef.add({
      'userName': userName,
      'userAvatar': initials,
      'timestamp': FieldValue.serverTimestamp(), // Server time is accurate
      'content': content,
      'category': category,
      'likesCount': 0,
      'likedBy': [],
      'comments': 0,
    });
  }

  Future<void> _toggleLike(ForumPost post) async {
    final user = context.read<AppProvider>().currentUser;
    if (user == null) return;
    
    final uid = user.id;
    final isLiked = post.likedBy.contains(uid);

    if (isLiked) {
      // Unlike
      await _postsRef.doc(post.id).update({
        'likesCount': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([uid]),
      });
    } else {
      // Like
      await _postsRef.doc(post.id).update({
        'likesCount': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([uid]),
      });
    }
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
                      const SnackBar(content: Text('Post published!')),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForumTab(theme),
          _buildResourcesTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        label: const Text('Ask Question'),
        icon: const Icon(Icons.edit),
      ),
    );
  }

  // --- TAB 1: LIVE FORUM (REAL-TIME) ---
  Widget _buildForumTab(ThemeData theme) {
    final currentUserId = context.watch<AppProvider>().currentUser?.id;

    // StreamBuilder listens to the database in real-time
    return StreamBuilder<QuerySnapshot>(
      stream: _postsRef.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Something went wrong"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        if (data == null || data.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.forum_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No posts yet. Be the first!", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.docs.length,
          itemBuilder: (context, index) {
            final post = ForumPost.fromFirestore(data.docs[index]);
            final isLikedByMe = currentUserId != null && post.likedBy.contains(currentUserId);

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Header
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
                    // Post Content
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
                          icon: isLikedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                          label: '${post.likesCount} Likes',
                          color: isLikedByMe ? theme.primaryColor : Colors.grey,
                          onTap: () => _toggleLike(post),
                        ),
                        _buildActionButton(
                          icon: Icons.comment_outlined,
                          label: '${post.comments} Comments',
                          color: Colors.grey,
                          onTap: () {
                             ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Comments feature coming soon')),
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