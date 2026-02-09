import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'storage_service.dart';
import '../utils/constants.dart';

class AuthService {
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/token/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      developer.log('Login response: ${response.statusCode}');
      developer.log('Login body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'access': data['access'],
          'refresh': data['refresh'],
        };
      } else if (response.statusCode == 401) {
        try {
          final errorData = jsonDecode(response.body);
          String errorMsg = 'Login failed';

          if (errorData['non_field_errors'] != null) {
            errorMsg = errorData['non_field_errors'][0];
          } else if (errorData['detail'] != null) {
            errorMsg = errorData['detail'];
          }

          return {'success': false, 'error': errorMsg};
        } catch (_) {
          return {'success': false, 'error': 'Invalid credentials'};
        }
      } else {
        return {'success': false, 'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      developer.log('Login error: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/token/refresh/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'access': data['access'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to refresh token',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/accounts/password-reset/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset email sent',
        };
      } else if (response.statusCode == 404) {
        // Email not found/registered
        return {
          'success': false,
          'error': 'This email is not registered. Please check and try again.',
        };
      } else {
        try {
          final data = jsonDecode(response.body);
          String errorMsg = 'Failed to send reset email';
          
          // Check for specific error messages
          if (data['email'] != null) {
            errorMsg = data['email'][0];
          } else if (data['error'] != null) {
            errorMsg = data['error'];
          } else if (data['detail'] != null) {
            errorMsg = data['detail'];
          } else if (data['non_field_errors'] != null) {
            errorMsg = data['non_field_errors'][0];
          }
          
          return {
            'success': false,
            'error': errorMsg,
          };
        } catch (_) {
          return {
            'success': false,
            'error': 'Server error: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String uidb64,
    required String token,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/accounts/password-reset-confirm/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uidb64': uidb64,
          'token': token,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password reset successful',
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<String?> refreshAccessToken() async {
    final refreshTokenStr = await _storage.getRefreshToken();
    if (refreshTokenStr == null) return null;

    final result = await this.refreshToken(refreshTokenStr);
    if (result['success'] == true) {
      final newAccessToken = result['access'] as String?;
      if (newAccessToken != null) {
        await _storage.saveAccessToken(newAccessToken);
        return newAccessToken;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> register(String fullName,
      String email,
      String phoneNumber,
      String address,
      String age,
      String gender,
      String password) async {
    final url = Uri.parse('${ApiConstants.baseUrl}/patients/register/');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'full_name': fullName,
          'email': email,
          'password': password,
          'age': age,
          'gender': gender,
          'phone_number': phoneNumber,
          'address': address,
        }),
      );

      developer.log('Register response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'error': 'Status ${response.statusCode}: ${response.body}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
