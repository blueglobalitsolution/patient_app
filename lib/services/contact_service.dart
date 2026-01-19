import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';
import '../utils/constants.dart';
import 'storage_service.dart';
import 'auth_service.dart';

class ContactService {
  final String baseUrl = '${ApiConstants.baseUrl}/api/contacts/';
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

  Future<List<Contact>> getContacts() async {
    final headers = await _headers(auth: true);
    final response = await _executeWithRefresh(
      () => http.get(Uri.parse(baseUrl), headers: headers),
    );
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Contact.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  Future<bool> addContact(Contact contact) async {
    final headers = await _headers(auth: true);
    final response = await _executeWithRefresh(
      () => http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: jsonEncode(contact.toJson()),
      ),
    );
    return response.statusCode == 201;
  }

  Future<bool> updateContact(Contact contact) async {
    final String url = '$baseUrl${contact.id}/';
    final headers = await _headers(auth: true);
    final response = await _executeWithRefresh(
      () => http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(contact.toJson()),
      ),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteContact(int id) async {
    final String url = '$baseUrl$id/';
    final headers = await _headers(auth: true);
    final response = await _executeWithRefresh(
      () => http.delete(Uri.parse(url), headers: headers),
    );
    return response.statusCode == 204;
  }
}
