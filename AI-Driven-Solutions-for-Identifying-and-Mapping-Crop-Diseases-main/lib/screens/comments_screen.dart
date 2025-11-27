import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CommentsScreen extends StatefulWidget {
  final String postId; // We need to know WHICH post we are commenting on

  const CommentsScreen({super.key, required this.postId});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isPosting = true);

    try {
      // Get current user details from Provider
      final user = context.read<AppProvider>().currentUser;
      final userName = user?.name ?? 'Anonymous Farmer';

      // Generate Initials for Avatar
      String userAvatar = "F";
      if (userName.isNotEmpty) {
        userAvatar = userName.length >= 2
            ? userName.substring(0, 2).toUpperCase()
            : userName[0].toUpperCase();
      }

      // 1. Add comment to the 'comments' sub-collection of this specific post
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'content': content,
        'userName': userName,
        'userAvatar': userAvatar,
        'timestamp': FieldValue.serverTimestamp(), // Server time is best
        'userId': user?.id, // Good for tracking who commented
      });

      // 2. Optional: Increment a 'commentCount' on the main post so we can show "5 Comments" in the feed
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update({
        'comments': FieldValue.increment(1),
      });

      _commentController.clear();
      if (mounted) FocusScope.of(context).unfocus(); // Hide keyboard
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Comments")),
      body: Column(
        children: [
          // --- COMMENT LIST ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Listen to the 'comments' sub-collection, ordered by time
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp',
                      descending: false) // Oldest at top (like WhatsApp)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Something went wrong"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("No comments yet. Be the first!",
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;

                    // Handle timestamp conversion safely
                    // (Firestore timestamps can be null for a split second when first created)
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null
                        ? "${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : "Just now";

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            radius: 18,
                            child: Text(
                              data['userAvatar'] ?? '?',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      data['userName'] ?? 'Anonymous',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['content'] ?? '',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // --- INPUT FIELD ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, -2))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: IconButton(
                      onPressed: _isPosting ? null : _postComment,
                      icon: _isPosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send,
                              color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
