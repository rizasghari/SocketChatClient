import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api/v1';

  static Future<LoginResponse?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['success']) {
        return LoginResponse.fromJson(responseData['data']);
      }
    }

    return null;
  }
}
