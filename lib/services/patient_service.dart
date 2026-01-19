import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';

class PatientService {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();

  bool _isRefreshing = false;

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      var token = await _storage.getAccessToken();
      if (token != null) {
        h['Authorization'] = 'Bearer $token';
      }
    }
    return h;
  }

  Future<http.Response> _executeWithRefresh(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();

    if (response.statusCode == 401) {
      if (_isRefreshing) {
        return response;
      }

      _isRefreshing = true;
      try {
        final newToken = await _auth.refreshAccessToken();
        if (newToken != null) {
          response = await requestFn();
        }
      } finally {
        _isRefreshing = false;
      }
    }

    return response;
  }

  Future<PatientProfile> getProfile() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/patients/api/profile/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      () => http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return PatientProfile.fromJson(data);
    }
    throw Exception('Failed to load profile');
  }

  Future<PatientProfile> updateProfile(Map<String, dynamic> data) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/patients/api/profile/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      () => http.patch(
        uri,
        headers: headers,
        body: jsonEncode(data),
      ),
    );

    if (res.statusCode == 200) {
      final responseData = jsonDecode(res.body) as Map<String, dynamic>;
      return PatientProfile.fromJson(responseData);
    }
    throw Exception('Failed to update profile');
  }

  Future<List<MedicalRecord>> getMedicalHistory() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/patients/api/medical-history/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      () => http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => MedicalRecord.fromJson(e)).toList();
    }
    throw Exception('Failed to load medical history');
  }

  Future<List<PatientNotification>> getNotifications() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/patients/api/notifications/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      () => http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => PatientNotification.fromJson(e)).toList();
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/patients/api/notifications/$notificationId/mark-read/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      () => http.patch(uri, headers: headers),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
