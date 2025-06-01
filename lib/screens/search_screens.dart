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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Row(
              children: [
                Icon(Icons.search, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onSearchChanged,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Telusuri orang atau kata kunci',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
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
                  child: Text(
                    'Batalkan',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : searchQuery.isEmpty
              ? Center(
                child: Text(
                  'Masukkan kata kunci untuk mencari',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              )
              : _searchResults.isEmpty
              ? Center(
                child: Text(
                  'Tidak ada hasil ditemukan',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              )
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
                        return ListTile(
                          title: Text(
                            "Pengguna tidak ditemukan",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.error,
                            ),
                          ),
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
                                    : CircleAvatar(
                                      radius: 20,
                                      backgroundColor: colorScheme.primary
                                          .withOpacity(0.3),
                                    ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      username,
                                      style: textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onBackground,
                                      ),
                                    ),
                                    Text(
                                      email,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onBackground
                                            .withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              content,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onBackground,
                              ),
                            ),
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
                                  Icon(
                                    Icons.favorite_border,
                                    size: 20,
                                    color: colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$likeCount',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onBackground,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: colorScheme.outline),
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
