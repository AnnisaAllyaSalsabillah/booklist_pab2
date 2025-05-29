import 'package:flutter/material.dart';

class ProfileProvider with ChangeNotifier {
  String _profileImage = '';

  String get profileImage => _profileImage;

  void setProfileImage(String imagePath) {
    _profileImage = imagePath;
    notifyListeners();
  }
}
