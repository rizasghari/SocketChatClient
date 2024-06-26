import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:http_interceptor/http/intercepted_client.dart';
import 'package:logger/logger.dart';
import 'package:socket_chat_client/main.dart';
import 'package:socket_chat_client/models/message.dart';
import 'package:socket_chat_client/models/whiteboard/api/whiteboard_request.dart';
import 'package:socket_chat_client/models/whiteboard/api/whiteboard.dart';
import 'package:socket_chat_client/services/auth_interceptor.dart';
import '../models/profile.dart';
import '../services/local_storage_service.dart';
import '../models/conversation.dart';
import '../models/login_response.dart';
import '../models/api_response.dart';
import '../models/user.dart';
import 'package:path/path.dart' as path;

class ApiService {
  static InterceptedClient authHttpClient =
      InterceptedClient.build(interceptors: [
    AuthInterceptor(),
  ]);

  static Future<String> getBaseUrl() async {
    String? apiHost = await LocalStorage.getString('api_host')
        .then((value) => value == null ? '10.0.2.2' : value.trim());
    var baseUrl = "http://$apiHost:8000/api/v1";
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
      var saveToken =
          await LocalStorage.setString("jwt_token", loginResponse.token);
      var saveUserID =
          await LocalStorage.setInt("user_id", loginResponse.user.id);

      if (saveToken && saveUserID) {
        logger.i(
            "Saved JWT token and user id in local storage: ${loginResponse.token}");
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
    try {
      final baseUrl = await getBaseUrl();
      final response = await authHttpClient.get(
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
    } catch (e) {
      logger.e(e);
      if (e is ClientException) {
        LocalStorage.clear();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil("/env", (route) => false);
      }
    }
    return [];
  }

  static Future<List<User>> discoverUsers(String token) async {
    try {
      final baseUrl = await getBaseUrl();
      final response = await authHttpClient.get(
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
    } catch (e) {
      logger.e(e);
      if (e is ClientException) {
        LocalStorage.clear();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil("/env", (route) => false);
      }
    }
    return [];
  }

  static Future<Profile?> fetchProfile(String token) async {
    final baseUrl = await getBaseUrl();
    final response = await authHttpClient.get(
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

  static Future<String?> uploadProfilePhoto(String token, File file) async {
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
      var responseString = await response.stream.bytesToString();
      final responseData = json.decode(responseString);
      if (responseData['success']) {
        String newProfilePhoto = responseData['data'];
        return newProfilePhoto;
      }
    }
    return null;
  }

  static Future<Profile?> updateProfile(
      String token, String firstName, String lastName) async {
    final baseUrl = await getBaseUrl();
    final response = await authHttpClient.put(
      Uri.parse('$baseUrl/users'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return Profile.fromJson(responseData['data']);
      }
    }
    return null;
  }

  static Future<Conversation?> createConversation(
      String token, List<int> users) async {
    final baseUrl = await getBaseUrl();
    final response = await authHttpClient.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({"type": "CONVERSATION_TYPE_PRIVATE", "users": users}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return Conversation.fromJson(responseData['data']);
      }
    }
    return null;
  }

  static Future<Whiteboard?> createWhiteboard(String token, WhiteboardRequest request) async {
    final baseUrl = await getBaseUrl();
    final response = await authHttpClient.post(
      Uri.parse('$baseUrl/whiteboards'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(request.toMap()),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return Whiteboard.fromJson(responseData['data']);
      }
    }
    return null;
  }

  static Future<List<Message>?> fetchConversationMessages(
      String token, int conversationId) async {
    final baseUrl = await getBaseUrl();
    final response = await authHttpClient.get(
      Uri.parse(
          '$baseUrl/messages/conversation/$conversationId?page=1&size=500'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        List<dynamic> data = responseData['data']['messages'];
        return data.map((json) => Message.fromJson(json)).toList();
      }
    }
    return [];
  }
}
