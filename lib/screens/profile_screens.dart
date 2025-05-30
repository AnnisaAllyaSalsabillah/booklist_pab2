import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booklist/screens/sign_in_screens.dart';
import 'package:image_picker/image_picker.dart';

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
  String _backgroundImageBase64 = '';
  bool _isLoading = true;
  late TabController _tabController;

  File? _profileImageFile;
  File? _backgroundImageFile;

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
            _profileImageBase64 = data['profileImageBase64'] ?? '';
            _backgroundImageBase64 = data['backgroundImageBase64'] ?? '';
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SignInScreens()),
      (route) => false,
    );
  }

  Future<void> _pickImage({required String type}) async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text("Ambil dari Kamera"),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked != null) {
                if (type == 'profile') {
                  setState(() {
                    _profileImageFile = File(picked.path);
                  });
                } else {
                  setState(() {
                    _backgroundImageFile = File(picked.path);
                  });
                }
                await _saveImageAsBase64(File(picked.path), type);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text("Pilih dari Galeri"),
            onTap: () async {
              Navigator.pop(context);
              final picked =
                  await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                if (type == 'profile') {
                  setState(() {
                    _profileImageFile = File(picked.path);
                  });
                } else {
                  setState(() {
                    _backgroundImageFile = File(picked.path);
                  });
                }
                await _saveImageAsBase64(File(picked.path), type);
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _saveImageAsBase64(File image, String type) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        type == 'profile' ? 'profileImageBase64' : 'backgroundImageBase64': base64Image,
      });

      setState(() {
        if (type == 'profile') {
          _profileImageBase64 = base64Image;
          _profileImageFile = null; // clear preview after saved
        } else {
          _backgroundImageBase64 = base64Image;
          _backgroundImageFile = null;
        }
      });
    } catch (e) {
      _showErrorMessage('Gagal menyimpan gambar: $e');
    }
  }

  ImageProvider _getImageProvider(String base64String, File? file, String fallbackUrl) {
    if (file != null) {
      return FileImage(file);
    } else if (base64String.isNotEmpty) {
      try {
        final bytes = base64Decode(base64String);
        return MemoryImage(bytes);
      } catch (_) {
        return NetworkImage(fallbackUrl);
      }
    } else {
      return NetworkImage(fallbackUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _pickImage(type: 'background'),
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: _getImageProvider(
                                  _backgroundImageBase64,
                                  _backgroundImageFile,
                                  'https://i.imgur.com/zL4Krbz.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => _pickImage(type: 'profile'),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: _profileImageFile != null
                                  ? FileImage(_profileImageFile!)
                                  : (_profileImageBase64.isNotEmpty
                                      ? MemoryImage(base64Decode(_profileImageBase64))
                                      : null),
                              child: (_profileImageFile == null &&
                                      _profileImageBase64.isEmpty)
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
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
                        const SizedBox(width: 80),
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
                              const SizedBox(height: 4),
                              Text(
                                _phone.isNotEmpty ? _phone : '-',
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
    return const Center(child: Text('Belum ada post.'));
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
