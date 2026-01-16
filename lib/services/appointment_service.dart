import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/appointment_models.dart';
import 'storage_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';

class AppointmentService {
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

  Future<List<Doctor>> fetchDoctors({
    required int hospitalId,
    required String department,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}/appointments/widget/doctors/'
          '?hospital_id=$hospitalId&department=$department',
    );

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final list = data['doctors'] as List<dynamic>? ?? [];
      return list.map((e) => Doctor.fromJson(e)).toList();
    }
    throw Exception('Failed to load doctors');
  }

  Future<List<SlotDay>> fetchSlots(int doctorId, {String? date}) async {
    String url = '${ApiConstants.baseUrl}/api/appointments/api/mobile-slots/$doctorId/';
    
    if (date != null) {
      url += '?date=$date';
    }

    final uri = Uri.parse(url);
    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final days = data['days'] as List<dynamic>? ?? [];
      return days.map((e) => SlotDay.fromJson(e)).toList();
    }
    throw Exception('Failed to load slots');
  }

  Future<String> bookAppointment({
    required int doctorId,
    required int slotId,
    required String date,
    String reason = 'Consultation',
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/mobile/book/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      http.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'doctor_id': doctorId,
          'slot_id': slotId,
          'date': date,
          'reason': reason,
        }),
      ),
    );

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode == 200 || res.statusCode == 201) {
      return data['message'] ?? 'Appointment booked successfully';
    } else {
      throw Exception(data['error'] ?? 'Booking failed');
    }
  }

  Future<List<MyAppointment>> getMyAppointments() async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/appointments/my-appointments/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      http.get(uri, headers: headers),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => MyAppointment.fromJson(e)).toList();
    }
    throw Exception('Failed to load appointments');
  }

  Future<void> cancelAppointment(int appointmentId) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/appointments/cancel/$appointmentId/');

    final headers = await _headers(auth: true);
    final res = await _executeWithRefresh(
      http.post(uri, headers: headers),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to cancel appointment');
    }
  }
}
