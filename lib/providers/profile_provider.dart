import 'dart:io';

import 'package:flutter/material.dart';
import 'package:socket_chat_client/services/local_storage_service.dart';
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

  Future<String?> uploadProfilePhoto(String token, File file) async {
    await Future.delayed(const Duration(seconds: 3));
    return await ApiService.uploadProfilePhoto(token, file);
  }

  Future<bool> updateProfile(
      String token, String firstName, String lastName) async {
    await Future.delayed(const Duration(seconds: 3));
    _profile = await ApiService.updateProfile(token, firstName, lastName);
    if (_profile != null) {
      return true;
    }
    return false;
  }

  Future<bool> logout() async {
    _profile = null;
    return LocalStorage.clear();
  }
}
