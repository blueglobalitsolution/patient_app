import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_models.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class SearchService {
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

  Future<SearchResult> universalSearch({
    required String query,
    String? city,
    bool requireAuth = false,
  }) async {
    try {
      final queryParams = <String, String>{'query': query};

      // Only add city parameter if it's provided and valid
      // Sometimes backend returns empty results if city doesn't match exactly
      if (city != null && city.isNotEmpty && city != 'null') {
        queryParams['city'] = city;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/universal-search/')
          .replace(queryParameters: queryParams);

      print('==================== SEARCH DEBUG ====================');
      print('🔍 Query: "$query"');
      print('🏙️  City: "$city"');
      print('🌐 Full URL: $uri');
      print('📋 QueryParams: $queryParams');
      print('🔐 RequireAuth: $requireAuth');
      print('====================================================');

      final headers = await _headers(auth: requireAuth);
      print('📤 Request Headers: $headers');

      final response = await _executeWithRefresh(
        () => http.get(uri, headers: headers),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Parsed Data: ${data.keys}');
        print('👨‍⚕️  Doctors found: ${(data['doctors'] as List?)?.length ?? 0}');
        print('🏥 Hospitals found: ${(data['hospitals'] as List?)?.length ?? 0}');
        print('====================================================\n');
        return SearchResult.fromJson(data);
      } else {
        print('❌ Response error ${response.statusCode}: ${response.body}');
        print('====================================================\n');
        throw Exception('Search failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Exception in search: $e');
      print('====================================================\n');
      throw Exception('Search error: $e');
    }
  }
}
