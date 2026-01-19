import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/doctor_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';

class DoctorService {
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

  Future<List<Doctor>> getDoctors() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/doctors/');
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Doctor> getDoctorById(int id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/doctors/$id/');
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return Doctor.fromJson(data);
      } else {
        throw Exception('Failed to load doctor: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Doctor>> getDoctorsByHospital(int hospitalId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/doctors/?hospital_id=$hospitalId');
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<Doctor>> getDoctorsByDepartment(int departmentId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/doctors/?department_id=$departmentId');
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Doctor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load doctors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}