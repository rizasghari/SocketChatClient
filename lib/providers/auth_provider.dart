import 'package:flutter/material.dart';
import '../models/login_response.dart';
import '../utils/api_service.dart';

class AuthProvider extends ChangeNotifier {
  LoginResponse? _loginResponse;

  LoginResponse? get user => _loginResponse;

  Future<bool> login(String email, String password) async {
    final user = await ApiService.login(email, password);
    if (user != null) {
      _loginResponse = user;
      notifyListeners();
      return true;
    }
    return false;
  }
}
