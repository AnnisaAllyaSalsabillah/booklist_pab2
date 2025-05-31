import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

        setState(() {
          _post = postData;
          _user = userData;
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
            // TODO: Tambahkan komentar & like di bawah ini
          ],
        ),
      ),
    );
  }
}