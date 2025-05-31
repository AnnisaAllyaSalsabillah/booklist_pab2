import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _controller = TextEditingController();
  File? _selectedImage;
  String? _base64Image;
  String _location = "";
  String? _profileImageBase64; // Simpan profile image user base64

  @override
  void initState() {
    super.initState();
    _loadUserProfileImage();
  }

  Future<void> _loadUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data['profileImage'] != null && data['profileImage'] is String && data['profileImage'].isNotEmpty) {
        setState(() {
          _profileImageBase64 = data['profileImage'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile;
      });
      await _compressAndEncodeImage(imageFile);
    }
  }

  Future<void> _compressAndEncodeImage(File image) async {
    final compressed = await FlutterImageCompress.compressWithFile(
      image.path,
      quality: 50,
    );
    if (compressed != null) {
      setState(() {
        _base64Image = base64Encode(compressed);
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks[0];
    setState(() {
      _location = "${place.locality}, ${place.country}";
    });
  }

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _base64Image == null) return;

    final user = FirebaseAuth.instance.currentUser!;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    final username = userData?['username'] ?? 'Unknown';
    final handle = userData?['handle'] ?? '@unknown';
    final email = userData?['email'] ?? '';
    final profileImage = userData?['profileImage'] ?? '';

    final post = {
      'userId': user.uid,
      'username': username,
      'email': email,
      'profileImage': profileImage, // base64 string
      'content': text,
      'images': _base64Image != null ? [_base64Image] : [],
      'location': _location,
      'createdAt': Timestamp.now(),
      'likes': 0,
    };

    await FirebaseFirestore.instance.collection('posts').add(post);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  onPressed: _submitPost,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD580),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    "Post",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          ListTile(
            leading: _profileImageBase64 != null && _profileImageBase64!.isNotEmpty
                ? CircleAvatar(
                    radius: 20,
                    backgroundImage: MemoryImage(base64Decode(_profileImageBase64!)),
                  )
                : const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                    child: Icon(Icons.person),
                  ),
            title: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Apa yang sedang terjadi?",
                border: InputBorder.none,
              ),
              maxLines: null,
            ),
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (_location.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(_location, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                ),
                IconButton(
                  onPressed: _getLocation,
                  icon: const Icon(Icons.location_on_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
