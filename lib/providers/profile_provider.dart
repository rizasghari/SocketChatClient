import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/api_service.dart';

class ProfileProvider extends ChangeNotifier {
  Profile? _profile;
  Profile? get profile => _profile;

  Future<bool> fetchProfile(String token) async {
    _profile = await ApiService.fetchProfile(token);
    if (_profile != null) {
      return true;
    } else {
      return false;
    }
  }
}