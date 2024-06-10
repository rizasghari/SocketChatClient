import 'package:flutter/material.dart';
import '../models/login_response.dart';
import '../utils/api_service.dart';

class AuthProvider extends ChangeNotifier {
  LoginResponse? _loginResponse;

  LoginResponse? get loginResponse => _loginResponse;

  Future<bool> login(String email, String password) async {
    final loginResponse = await ApiService.login(email, password);
    if (loginResponse != null) {
      _loginResponse = loginResponse;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String firstName, String lastName, String password) async {
    return await ApiService.register(email, firstName, lastName, password);
  }
}
