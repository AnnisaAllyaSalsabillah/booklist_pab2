import 'dart:convert';
import 'package:booklist/screens/add_post_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class HomeScreens extends StatefulWidget {
  const HomeScreens({Key? key}) : super(key: key);

  @override
  State<HomeScreens> createState() => _HomeScreensState();
}

class _HomeScreensState extends State<HomeScreens> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.amberAccent[300],
                    child: const Icon(Icons.person, size: 30),

                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentUser?.displayName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${currentUser?.email?.split('@')[0] ?? 'user'}',
                    style: const TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark theme'),
              onTap: () {},
            )
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.amber[200],
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final username = data['username'] ?? 'Unknown';
              final handle = data['handle'] ?? '@unknown';
              final content = data['content'] ?? '';
              final createdAt = (data['createdAt'] as Timestamp).toDate();
              final imageUrls = List<String>.from(data['images'] ?? []);
              final likeCount = data['likes'] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(username, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(handle, style: const TextStyle(color: Colors.grey))
                              ],
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(content),
                        if (imageUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: imageUrls.take(2).map((url) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(url, height: 150, fit: BoxFit.cover),
                                  ),
                                ),
                              );
                            }).toList(),
                          )
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Icon(Icons.favorite_border, size: 20, color: Colors.redAccent),
                            const SizedBox(width: 2),
                            Text('$likeCount')
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber[300],
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPostScreens()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

