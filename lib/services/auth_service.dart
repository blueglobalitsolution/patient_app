import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class AuthService {
  static const String _baseUrl = 'http://192.168.1.208:8000';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/token/');
    developer.log('Login request: $email to $url'); // Debug log

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,  // Try 'email' if username fails
          'password': password,
        }),
      );

      developer.log('Login response: ${response.statusCode}');
      developer.log('Login body: ${response.body}'); // See exact error

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'access': data['access'],
          'refresh': data['refresh'],
        };
      } else {
        return {
          'success': false,
          'error': 'Status ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      developer.log('Login error: $e');
      return {
        'success': false,
        'error': 'Network error: $e',
      };
    }
  }

  Future<bool> register(String name, String email, String phone, String city, String password) async {
    final url = Uri.parse('$_baseUrl/patients/register/');
    developer.log('Register request to $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'city': city,
          'password': password,
        }),
      );

      developer.log('Register response: ${response.statusCode} ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      developer.log('Register error: $e');
      return false;
    }
  }
}
