import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/conversation.dart';
import '../models/login_response.dart';
import '../models/api_reponse.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';
  static Logger logger = Logger();
  static Future<LoginResponse?> login(String email, String password) async {
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
      logger.i("Login Success");
      return LoginResponse.fromJson(apiResponse.data);
    } else {
      for (final error in apiResponse.errors!) {
        logger.e("Login Error", error);
      }
    }

    return null;
  }

  static Future<bool> register(String email, String firstName, String lastName, String password) async {
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


  /// Fetches a list of conversations for the authenticated user.
  ///
  /// The [token] parameter is the authentication token for the user.
  ///
  /// Returns a [Future] that completes with a [List] of [Conversation] objects.
  /// If the request is successful, the list will contain the conversations for the user.
  /// If the request fails, an empty list is returned.
   static Future<List<Conversation>> fetchConversations(String token) async {
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
}
