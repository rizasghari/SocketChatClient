import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
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
}
