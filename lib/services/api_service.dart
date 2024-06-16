import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/profile.dart';
import '../services/local_storage_service.dart';
import '../models/conversation.dart';
import '../models/login_response.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'package:path/path.dart' as path;

class ApiService {
  static Future<String> getBaseUrl() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    var baseUrl = "http://$apiHost:8000/api/v1";
    logger.i("API Base URL: $baseUrl");
    return baseUrl;
  }

  static Logger logger = Logger();
  static Future<LoginResponse?> login(String email, String password) async {
    final baseUrl = await getBaseUrl();
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
      var saveToken = await LocalStorage.setString("jwt_token", loginResponse.token);
      var saveUserID = await LocalStorage.setInt("user_id", loginResponse.user.id);

      if (saveToken && saveUserID) {
        logger.i("Saved JWT token and user id in local storage: ${loginResponse.token}");
        return loginResponse;
      } else {
        logger.e("Failed to save JWT Token or user id in local storage");
        return null;
      }
    } else {
      for (final error in apiResponse.errors!) {
        logger.e("Login Error", error: error);
      }
    }
    return null;
  }

  static Future<bool> register(
      String email, String firstName, String lastName, String password) async {
    final baseUrl = await getBaseUrl();
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
    logger.i(
        '########################## Fetching conversations ##########################');
    logger.i('Fetching conversations with token: $token');
    final baseUrl = await getBaseUrl();
    logger.i('API Base URL: $baseUrl');
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
    final baseUrl = await getBaseUrl();
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

  static Future<Profile?> fetchProfile(String token) async {
    final baseUrl = await getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return Profile.fromJson(responseData['data']);
      }
    }

    return null;
  }

  static
  Future<bool> uploadProfilePhoto(String token, File file) async {
    final baseUrl = await getBaseUrl();
    final uri = Uri.parse('$baseUrl/users/upload-profile-photo');

    var request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';

    // Add the file to the request
    var fileStream = http.ByteStream(file.openRead());
    var length = await file.length();
    var multipartFile = http.MultipartFile(
      'profile_photo',
      fileStream,
      length,
      filename: path.basename(file.path),
    );
    request.files.add(multipartFile);

    var response = await request.send();

    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }
}

