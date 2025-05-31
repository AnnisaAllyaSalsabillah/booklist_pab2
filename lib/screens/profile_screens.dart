import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booklist/screens/sign_in_screens.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
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
  bool _isLoading = true;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  File? _profileImageFile;

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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
        ],
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
