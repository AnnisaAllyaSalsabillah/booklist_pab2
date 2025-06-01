import 'dart:convert';
import 'dart:io';
import 'package:booklist/screens/detail_screens.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booklist/screens/sign_in_screens.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:booklist/screens/home_screens.dart';

class ProfileScreens extends StatefulWidget {
  const ProfileScreens({super.key});

  @override
  State<ProfileScreens> createState() => _ProfileScreensState();
}

class _ProfileScreensState extends State<ProfileScreens>
    with SingleTickerProviderStateMixin {
  String _userName = '';
  String _email = '';
  String _phone = '';
  String _profileImageBase64 = '';
  bool _isLoading = true;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  File? _profileImageFile;

  String _formatTime(DateTime dateTime) {
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final data = doc.data();
        if (data != null) {
          setState(() {
            _userName = data['userName'] ?? '';
            _email = data['email'] ?? '';
            _phone = data['phone'] ?? '';
            _profileImageBase64 = data['profileImage'] ?? '';
          });
        }
      }
    } catch (e) {
      _showErrorMessage('Failed to load user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreens()),
      (route) => false,
    );
  }

  Future<void> _compressAndEncodeImageProfile() async {
    if (_profileImageFile == null) return;
    try {
      final compressedImage = await FlutterImageCompress.compressWithFile(
        _profileImageFile!.path,
        quality: 50,
      );

      if (compressedImage == null) return;

      setState(() {
        _profileImageBase64 = base64Encode(compressedImage);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
      }
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _profileImageFile = File(pickedFile.path);
        });
        await _compressAndEncodeImageProfile();
        await _saveImageAsBase64();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _saveImageAsBase64() async {
    if (_profileImageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add an image and description.')),
      );
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'profileImage': _profileImageBase64,
    });

    if (!mounted) return;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget =
        _profileImageFile != null
            ? Image.file(_profileImageFile!, fit: BoxFit.cover)
            : (_profileImageBase64.isNotEmpty
                ? Image.memory(
                  base64Decode(_profileImageBase64),
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.person, size: 100, color: Colors.grey));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreens()),
            );
          },
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: imageWidget,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          // SizedBox dihapus supaya tidak mendorong ke kanan
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _email,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.orange,
                      unselectedLabelColor: Colors.black,
                      indicatorColor: Colors.orange,
                      tabs: const [Tab(text: 'Post'), Tab(text: 'Likes')],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildPostList(), _buildLikesList()],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPostList() {
    final currentUser = FirebaseAuth.instance.currentUser!;
    print("akuuu ${currentUser.uid}");

    if (currentUser == null) {
      return const Center(child: Text('User tidak ditemukan.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('posts')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Tidak ada data.'));
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return const Center(child: Text('Belum ada post.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;

            final content = data['content'] ?? '';
            final location = data['location'] ?? '';
            final createdAt = (data['createdAt'] as Timestamp).toDate();
            final imageBase64List = List<String>.from(data['images'] ?? []);
            final likeCount = data['likes'] ?? 0;

            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailScreen(postId: posts[index].id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _profileImageBase64.isNotEmpty
                                ? CircleAvatar(
                                  radius: 20,
                                  backgroundImage: MemoryImage(
                                    base64Decode(_profileImageBase64),
                                  ),
                                )
                                : const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey,
                                  child: Icon(Icons.person, size: 20),
                                ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _email,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(createdAt),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(content),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                location,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                        if (imageBase64List.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(imageBase64List[0]),
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.favorite_border,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 2),
                            Text('$likeCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLikesList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nadh', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('@bomgyune', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'It has been a really a while since I picked up Miss Daws book. Nine Month Contract is fun read. Really fun read. I like Triśta very much. I think Triśta is the alter ego of Miss Daws herself',
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.mode_comment_outlined, size: 20),
            SizedBox(width: 16),
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 4),
            Text('5k', style: TextStyle(color: Colors.black)),
          ],
        ),
        SizedBox(height: 10),
        Text('Show more', style: TextStyle(color: Colors.orange)),
      ],
    );
  }
}
