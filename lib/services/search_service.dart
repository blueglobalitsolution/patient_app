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
    Future<http.Response> request,
  ) async {
    var response = await request;

    if (response.statusCode == 401) {
      if (_isRefreshing) {
        return response;
      }

      _isRefreshing = true;
      try {
        final newToken = await _auth.refreshAccessToken();
        if (newToken != null) {
          response = await request;
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
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/universal-search/')
          .replace(queryParameters: queryParams);

      print('DEBUG: API URL: $uri');

      final headers = await _headers(auth: requireAuth);
      final response = await _executeWithRefresh(
        http.get(uri, headers: headers),
      );

      if (response.statusCode == 200) {
        print('DEBUG: Response 200 OK');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return SearchResult.fromJson(data);
      } else {
        print('DEBUG: Response error ${response.statusCode}: ${response.body}');
        throw Exception('Search failed: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Exception in search: $e');
      throw Exception('Search error: $e');
    }
  }
}
