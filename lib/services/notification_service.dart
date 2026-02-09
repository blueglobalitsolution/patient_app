import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _initializeLocalNotifications();

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    final androidImplementation = _localNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted = await androidImplementation!.requestNotificationsPermission();
      if (kDebugMode) {
        print('NotificationService: Android permission granted: $granted');
      }
    }

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (kDebugMode) {
      print('NotificationService: Local notifications initialized');
    }
  }


  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kDebugMode) {
      print('NotificationService: Showing local notification - ID: $id, Title: $title');
    }

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'patient_app_channel',
      'Patient App Notifications',
      channelDescription: 'Notifications for patient appointments and reminders',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      channelShowBadge: true,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: const Color(0xFF8c6239),
      ledOnMs: 500,
      ledOffMs: 1000,
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      groupKey: 'patient_app_notifications',
      setAsGroupSummary: false,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentSound: true,
      presentBadge: true,
      presentAlert: true,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    if (kDebugMode) {
      print('NotificationService: Local notification sent successfully');
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    await _localNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'patient_app_channel',
          'Patient App Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String doctorName,
    required DateTime appointmentTime,
  }) async {
    if (kDebugMode) {
      print('NotificationService: Scheduling reminder for appointment #$appointmentId at $appointmentTime');
    }

    final reminderTime = appointmentTime.subtract(const Duration(hours: 1));
    final reminderId = (appointmentId * 100) + 1;

    final timeStr = '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}';
    final period = appointmentTime.hour >= 12 ? 'PM' : 'AM';
    final displayHour = appointmentTime.hour > 12 ? appointmentTime.hour - 12 : (appointmentTime.hour == 0 ? 12 : appointmentTime.hour);
    final formattedTime = '${displayHour}:${appointmentTime.minute.toString().padLeft(2, '0')} $period';

    await scheduleNotification(
      id: reminderId,
      title: 'Appointment Reminder',
      body: 'Reminder: Your appointment with Dr. $doctorName is scheduled for $formattedTime.',
      scheduledTime: reminderTime,
      payload: jsonEncode({
        'type': 'appointment_reminder',
        'appointmentId': appointmentId,
      }),
    );

    if (kDebugMode) {
      print('NotificationService: Reminder scheduled (ID: $reminderId) for $reminderTime');
    }
  }

  Future<void> cancelNotification(int id) async {
    await _localNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
  }

  Future<void> cancelAppointmentReminder(int appointmentId) async {
    final reminderId = (appointmentId * 100) + 1;
    if (kDebugMode) {
      print('NotificationService: Cancelling reminder for appointment #$appointmentId (ID: $reminderId)');
    }
    await cancelNotification(reminderId);
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    if (kDebugMode) {
      print('Notification tapped: ${response.payload}');
    }

    if (response.payload != null) {
      try {
        final payload = jsonDecode(response.payload!);
        if (payload['type'] == 'appointment_reminder') {
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing notification payload: $e');
        }
      }
    }
  }
}