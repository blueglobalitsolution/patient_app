import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/contact.dart';

class ContactService {
  final String baseUrl = 'http://192.168.1.208:8000/api/contacts/';
  //final String baseUrl = 'http://192.168.0.109:8000/api/contacts/';

  Future<List<Contact>> getContacts() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((dynamic item) => Contact.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load contacts');
    }
  }

  Future<bool> addContact(Contact contact) async {
    final responce = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contact.toJson()),
    );
    return responce.statusCode == 201;
  }

  Future<bool> updateContact(Contact contact) async {
    final String url = '$baseUrl${contact.id}/';
    final response = await http.put(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(contact.toJson()),
    );
    return response.statusCode == 200;
  }

  Future<bool> deleteContact(int id) async {
    final String url = '$baseUrl$id/';
    final response = await http.delete(Uri.parse(url));
    return response.statusCode == 204;
  }
}