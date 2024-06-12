import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:socket_chat_flutter/repositories/local_storage.dart';
import '../models/conversation.dart';
import '../models/login_response.dart';
import '../models/api_reponse.dart';
import '../models/user.dart';

class ApiService {
  static Future<String> _getBaseUrl() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    return "http://$apiHost:8000/api/v1";
  }

  static Logger logger = Logger();
  static Future<LoginResponse?> login(String email, String password) async {
    final baseUrl = await _getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    final APiResponse apiResponse = APiResponse.fromJson(responseData);
    logger.i("Login Response: ${response.body}");
    if (response.statusCode == 200 && apiResponse.success) {
      var loginResponse = LoginResponse.fromJson(apiResponse.data);
      if (await LocalStorage.setString("jwt_token", loginResponse.token)) {
        logger.i("Saved JWT Token in local storage: ${loginResponse.token}");
        return loginResponse;
      } else {
        logger.e("Failed to save JWT Token in local storage");
        return null;
      }
    } else {
      for (final error in apiResponse.errors!) {
        logger.e("Login Error", error);
      }
    }

    return null;
  }

  static Future<bool> register(
      String email, String firstName, String lastName, String password) async {
    final baseUrl = await _getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      return responseData['success'];
    }

    return false;
  }

  static Future<List<Conversation>> fetchConversations(String token) async {
    final baseUrl = await _getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/my?page=1&size=100'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        List<dynamic> data = responseData['data']['conversations'];
        return data.map((json) => Conversation.fromJson(json)).toList();
      }
    }

    return [];
  }

  static Future<List<User>> discoverUsers(String token) async {
    final baseUrl = await _getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/users/discover?page=1&size=100'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        List<dynamic> data = responseData['data']['users'];
        return data.map((json) => User.fromJson(json)).toList();
      }
    }

    return [];
  }
}
