import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/treatment_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';

class TreatmentService {
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

  Future<List<Treatment>> getTreatments() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/treatments/');
      print('DEBUG: Treatment API URL: $uri');
      
      final headers = await _headers(auth: true);
      print('DEBUG: Treatment API headers: $headers');
      
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      print('DEBUG: Treatment API status: ${response.statusCode}');
      print('DEBUG: Treatment API response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic parsedData = jsonDecode(response.body);
          print('DEBUG: Treatment parsed data type: ${parsedData.runtimeType}');
          print('DEBUG: Treatment parsed data: $parsedData');
          
          List<dynamic> data;
          if (parsedData is Map<String, dynamic>) {
            // Handle case where API returns {"treatments": [...]}
            data = parsedData['treatments'] ?? [];
            print('DEBUG: Extracted treatments from object');
          } else if (parsedData is List) {
            // Handle case where API returns [...] directly
            data = parsedData;
            print('DEBUG: Using direct array response');
          } else {
            print('DEBUG: Unexpected treatment response format');
            data = [];
          }
          
          print('DEBUG: Final treatment data array length: ${data.length}');
          final treatments = data.map((json) => Treatment.fromJson(json)).toList();
          print('DEBUG: Mapped treatments count: ${treatments.length}');
          return treatments;
        } catch (e) {
          print('DEBUG: Treatment JSON parsing error: $e');
          print('DEBUG: Treatment raw response body: ${response.body}');
          return [];
        }
      } else {
        print('DEBUG: Treatment API error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load treatments: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Treatment API exception: $e');
      throw Exception('Network error: $e');
    }
  }

  // New API method to get treatments by department ID
  Future<List<Treatment>> getTreatmentsByDepartment(int departmentId) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/treatments/?department_id=$departmentId');
      print('DEBUG: Treatment by department API URL: $uri');
      
      final headers = await _headers(auth: true);
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      print('DEBUG: Treatment by department API status: ${response.statusCode}');
      print('DEBUG: Treatment by department API response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic parsedData = jsonDecode(response.body);
          print('DEBUG: Department treatments parsed data: $parsedData');
          
          List<dynamic> data;
          if (parsedData is Map<String, dynamic>) {
            data = parsedData['treatments'] ?? parsedData['results'] ?? [];
          } else if (parsedData is List) {
            data = parsedData;
          } else {
            data = [];
          }
          
          final treatments = data.map((json) => Treatment.fromJson(json)).toList();
          print('DEBUG: Department treatments count: ${treatments.length}');
          
          // Filter by department ID on client side since API doesn't seem to filter properly
          final filteredTreatments = treatments.where((treatment) => treatment.departmentId == departmentId).toList();
          print('DEBUG: Filtered treatments for department $departmentId: ${filteredTreatments.length}');
          
          return filteredTreatments;
        } catch (e) {
          print('DEBUG: Department treatments JSON parsing error: $e');
          return [];
        }
      } else {
        print('DEBUG: Department treatments API error - Status: ${response.statusCode}');
        throw Exception('Failed to load department treatments: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Department treatments API exception: $e');
      throw Exception('Network error: $e');
    }
  }
}