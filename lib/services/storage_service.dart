import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment_models.dart';

class StorageService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _appointmentsKey = 'booked_appointments';
  static const _localNotificationsKey = 'local_notifications';


  Future<void> saveAccessToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, token);
  }

  Future<void> saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
  }

  Future<void> clearRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_refreshTokenKey);
  }

  Future<void> clearAllTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }

  Future<void> saveAppointment(MyAppointment appointment) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();
    appointments.add(appointment);
    final jsonString = jsonEncode(appointments.map((a) => _appointmentToJson(a)).toList());
    await prefs.setString(_appointmentsKey, jsonString);
  }

  Future<void> deleteAppointment(int appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();
    appointments.removeWhere((a) => a.id == appointmentId);
    final jsonString = jsonEncode(appointments.map((a) => _appointmentToJson(a)).toList());
    await prefs.setString(_appointmentsKey, jsonString);
  }

  Future<void> updateAppointmentStatus(int appointmentId, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final appointments = await getAppointments();
    for (var i = 0; i < appointments.length; i++) {
      if (appointments[i].id == appointmentId) {
        final updatedAppointment = MyAppointment(
          id: appointments[i].id,
          date: appointments[i].date,
          time: appointments[i].time,
          status: newStatus,
          reason: appointments[i].reason,
          doctor: appointments[i].doctor,
          hospitalName: appointments[i].hospitalName,
          department: appointments[i].department,
        );
        appointments[i] = updatedAppointment;
        break;
      }
    }
    final jsonString = jsonEncode(appointments.map((a) => _appointmentToJson(a)).toList());
    await prefs.setString(_appointmentsKey, jsonString);
  }

  Future<List<MyAppointment>> getAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_appointmentsKey);
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => MyAppointment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appointmentsKey);
  }

  Map<String, dynamic> _appointmentToJson(MyAppointment appointment) {
    return {
      'id': appointment.id,
      'date': appointment.date,
      'time': appointment.time,
      'status': appointment.status,
      'reason': appointment.reason,
      'doctor': {
        'id': appointment.doctor.id,
        'name': appointment.doctor.name,
        'specialization': appointment.doctor.specialization,
      },
      'hospital_name': appointment.hospitalName,
      'department': appointment.department,
    };
  }

  Future<void> saveLocalNotification(LocalNotification notification) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getLocalNotifications();
    notifications.insert(0, notification);
    final jsonString = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_localNotificationsKey, jsonString);
  }

  Future<List<LocalNotification>> getLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_localNotificationsKey);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => LocalNotification.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> markLocalNotificationAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getLocalNotifications();
    for (var i = 0; i < notifications.length; i++) {
      if (notifications[i].id == notificationId) {
        notifications[i] = LocalNotification(
          id: notifications[i].id,
          title: notifications[i].title,
          message: notifications[i].message,
          type: notifications[i].type,
          createdAt: notifications[i].createdAt,
          isRead: true,
          appointmentId: notifications[i].appointmentId,
        );
        break;
      }
    }
    final jsonString = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_localNotificationsKey, jsonString);
  }

  Future<void> markAllLocalNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getLocalNotifications();
    final updatedNotifications = notifications.map((n) => LocalNotification(
      id: n.id,
      title: n.title,
      message: n.message,
      type: n.type,
      createdAt: n.createdAt,
      isRead: true,
      appointmentId: n.appointmentId,
    )).toList();
    final jsonString = jsonEncode(updatedNotifications.map((n) => n.toJson()).toList());
    await prefs.setString(_localNotificationsKey, jsonString);
  }

  Future<void> deleteLocalNotification(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = await getLocalNotifications();
    notifications.removeWhere((n) => n.id == notificationId);
    final jsonString = jsonEncode(notifications.map((n) => n.toJson()).toList());
    await prefs.setString(_localNotificationsKey, jsonString);
  }

  Future<void> clearAllLocalNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localNotificationsKey);
  }
}

