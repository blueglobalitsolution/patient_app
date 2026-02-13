import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department_models.dart';
import '../models/doctor_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import 'doctor_service.dart';
import '../utils/constants.dart';

class DepartmentService {
  final StorageService _storage = StorageService();
  final AuthService _auth = AuthService();
  final DoctorService _doctorService = DoctorService();

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

  Future<List<Department>> getDepartments() async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/departments/');
      print('DEBUG: Department API URL: $uri');
      
      final headers = await _headers(auth: true);
      print('DEBUG: Department API headers: $headers');
      
      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      print('DEBUG: Department API status: ${response.statusCode}');
      print('DEBUG: Department API response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic parsedData = jsonDecode(response.body);
          print('DEBUG: Parsed JSON data: $parsedData');
          print('DEBUG: Parsed data type: ${parsedData.runtimeType}');
          
          List<dynamic> data;
          if (parsedData is Map<String, dynamic>) {
            // Handle case where API returns {"departments": [...]}
            data = parsedData['departments'] ?? [];
            print('DEBUG: Extracted departments from object');
          } else if (parsedData is List) {
            // Handle case where API returns [...] directly
            data = parsedData;
            print('DEBUG: Using direct array response');
          } else {
            print('DEBUG: Unexpected response format');
            data = [];
          }
          
          print('DEBUG: Final department data array: $data');
          final departments = data.map((json) => Department.fromJson(json)).toList();
          print('DEBUG: Mapped departments count: ${departments.length}');
          return departments;
        } catch (e) {
          print('DEBUG: JSON parsing error: $e');
          print('DEBUG: Raw response body: ${response.body}');
          return [];
        }
      } else {
        print('DEBUG: Department API error - Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load departments: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Department API exception: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<List<Department>> getDepartmentsByHospital(int hospitalId) async {
    try {
      print('DEBUG: Getting departments for hospital $hospitalId using doctor relationships');
      
      // Step 1: Get all doctors for this hospital
      final doctors = await _doctorService.getDoctorsByHospital(hospitalId);
      print('DEBUG: Found ${doctors.length} doctors for hospital $hospitalId');
      
      // Step 2: Get all departments from API
      final allDepartments = await getDepartments();
      print('DEBUG: Found ${allDepartments.length} total departments');
      
      // Step 3: Extract unique department IDs from doctors in this hospital
      final hospitalDepartmentIds = doctors
          .where((d) => d.departmentId != null)
          .map((d) => d.departmentId!)
          .toSet();
      print('DEBUG: Hospital has ${hospitalDepartmentIds.length} unique department IDs');
      
      // Step 4: Filter departments that have doctors in this hospital
      final hospitalDepartments = allDepartments
          .where((dept) => hospitalDepartmentIds.contains(dept.id))
          .where((d) => d.isActive)
          .toList();
      
      print('DEBUG: Final hospital departments count: ${hospitalDepartments.length}');
      return hospitalDepartments;
      
    } catch (e) {
      print('DEBUG: Error getting hospital departments: $e');
      // Fallback to all departments if something goes wrong
      final allDepartments = await getDepartments();
      return allDepartments.where((d) => d.isActive).toList();
    }
  }
}