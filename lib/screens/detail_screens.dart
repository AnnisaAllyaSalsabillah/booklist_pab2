import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final String postId;

  const DetailScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Map<String, dynamic>? _post;
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  bool _isLiked = false;
  int _likeCount = 0;
  TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    fetchPostAndUser();
  }

  Future<void> fetchPostAndUser() async {
    try {
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      final postData = postDoc.data();
      if (postData != null) {
        final userId = postData['userId'];
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final userData = userDoc.data();

        final currentUser = FirebaseAuth.instance.currentUser;

        final likedBy = List<String>.from(postData['likedBy'] ?? []);
        final isLiked = currentUser != null && likedBy.contains(currentUser.uid);

        final comments = (postData['comments'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        comments.sort((a, b) {
          final tsA = a['createdAt'] as Timestamp?;
          final tsB = b['createdAt'] as Timestamp?;
          return tsB?.compareTo(tsA ?? Timestamp(0, 0)) ?? 0;
        });

        setState(() {
          _post = postData;
          _user = userData;
          _likeCount = postData['likes'] ?? 0;
          _isLiked = isLiked;
          _comments = comments;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching post/user data: $e');
      setState(() => _isLoading = false);
    }
  }


  void toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    final postDoc = await postRef.get();
    final postData = postDoc.data();
    if (postData == null) return;

    final likedBy = List<String>.from(postData['likedBy'] ?? []);
    int currentLikes = postData['likes'] ?? 0;

    if (_isLiked) {
      // unlike
      likedBy.remove(currentUser.uid);
      currentLikes--;
    } else {
      // like
      likedBy.add(currentUser.uid);
      currentLikes++;
    }

    await postRef.update({
      'likedBy': likedBy,
      'likes': currentLikes,
    });

    setState(() {
      _isLiked = !_isLiked;
      _likeCount = currentLikes;
    });
  }


  void addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) return;

    final comment = {
      'userId': currentUser.uid,
      'username': userData['userName'] ?? 'Unknown',
      'content': content,
      'createdAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .update({
      'comments': FieldValue.arrayUnion([comment])
    });

    _commentController.clear();
    fetchPostAndUser();
  }


  Widget buildImageList(List<dynamic> images) {
    return Column(
      children: images.map((img) {
        try {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Image.memory(
              base64Decode(img),
              fit: BoxFit.cover,
            ),
          );
        } catch (_) {
          return const SizedBox();
        }
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return const Scaffold(
        body: Center(child: Text("Post not found")),
      );
    }

    final username = _user?['userName'] ?? 'Unknown';
    final profileImage = _user?['profileImage'];
    final content = _post!['content'] ?? '';
    final images = List<String>.from(_post!['images'] ?? []);
    final location = _post!['location'] ?? '';
    final timestamp = _post!['createdAt'] != null
        ? (_post!['createdAt'] as Timestamp).toDate()
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Post'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                profileImage != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: MemoryImage(base64Decode(profileImage)),
                      )
                    : const CircleAvatar(radius: 24, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Text(
                  username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (images.isNotEmpty) buildImageList(images),
            if (location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Text(location),
                  ],
                ),
              ),
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Posted on ${timestamp.toLocal().toString().split('.').first}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                GestureDetector(
                  onTap: toggleLike,
                  child: Icon(
                    Icons.favorite,
                    color: _isLiked ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text('$_likeCount'),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: 'Write a comment ...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: addComment,
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _comments.map((comment) {
                final createdAt = comment['createdAt'] as Timestamp?;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                          radius: 14, child: Icon(Icons.person, size: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment['username'] ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(comment['content'] ?? ''),
                            if (createdAt != null)
                              Text(
                                createdAt.toDate().toString().split('.').first,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
