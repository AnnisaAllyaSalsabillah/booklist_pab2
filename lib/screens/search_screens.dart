import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SearchScreens extends StatefulWidget {
  const SearchScreens({super.key});

  @override
  State<SearchScreens> createState() => _SearchScreensState();
}

class _SearchScreensState extends State<SearchScreens> {
  String searchQuery = '';
  final TextEditingController _controller = TextEditingController();
  List<QueryDocumentSnapshot> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .orderBy('content')
              .startAt([query])
              .endAt(['$query\uf8ff'])
              .get();

      setState(() {
        _searchResults = snapshot.docs;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Error saat search: $e');
      print('📌 StackTrace: $stackTrace');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.trim();
    });

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: 'Telusuri orang atau kata kunci',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    _controller.clear();
                    setState(() {
                      searchQuery = '';
                      _searchResults = [];
                    });
                  },
                  child: const Text(
                    'Batalkan',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : searchQuery.isEmpty
              ? const Center(child: Text('Masukkan kata kunci untuk mencari'))
              : _searchResults.isEmpty
              ? const Center(child: Text('Tidak ada hasil ditemukan'))
              : ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final postData =
                      _searchResults[index].data() as Map<String, dynamic>;
                  final content = postData['content'] ?? '';
                  final imageUrls = List<String>.from(postData['images'] ?? []);
                  final likeCount = postData['likes'] ?? 0;
                  final userId = postData['userId'];

                  return FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const ListTile(
                          title: Text("Pengguna tidak ditemukan"),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final username = userData['userName'] ?? 'Unknown';
                      final email = userData['email'] ?? '';
                      final profileImage = userData['profileImage'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                profileImage.isNotEmpty
                                    ? CircleAvatar(
                                      radius: 20,
                                      backgroundImage: MemoryImage(
                                        base64Decode(profileImage),
                                      ),
                                    )
                                    : const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey,
                                    ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(content),
                            if (imageUrls.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(imageUrls[0]),
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.favorite_border,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('$likeCount'),
                                ],
                              ),
                              const Divider(),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
