import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hospital_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';

class HospitalService {
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

  Future<List<Hospital>> getNearbyHospitals(double lat, double lng, {double radius = 5.0}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/hospitals/nearby/?lat=$lat&lng=$lng&radius=$radius');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Hospital.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load hospitals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<List<ApprovedHospital>> getApprovedHospitals() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/hospitals/hospitals/');
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ApprovedHospital.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load approved hospitals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<ApprovedHospital?> getHospitalById(int hospitalId) async {
    try {
      final hospitals = await getApprovedHospitals();
      try {
        return hospitals.firstWhere((h) => h.id == hospitalId);
      } catch (e) {
        return null;
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
