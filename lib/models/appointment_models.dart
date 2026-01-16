import 'package:flutter/material.dart';

class Doctor {
  final int id;
  final String name;
  final String specialization;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
    );
  }
}

class Slot {
  final int id;
  final String start;
  final String end;

  Slot({
    required this.id,
    required this.start,
    required this.end,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'],
      start: json['start'] ?? '',
      end: json['end'] ?? '',
    );
  }
}

class SlotDay {
  final String date;
  final String label;
  final List<Slot> slots;

  SlotDay({
    required this.date,
    required this.label,
    required this.slots,
  });

  factory SlotDay.fromJson(Map<String, dynamic> json) {
    final slotsJson = json['slots'] as List<dynamic>? ?? [];
    return SlotDay(
      date: json['date'] ?? '',
      label: json['label'] ?? '',
      slots: slotsJson.map((e) => Slot.fromJson(e)).toList(),
    );
  }
}

class MyAppointment {
  final int id;
  final String date;
  final String time;
  final String status;
  final String reason;
  final Doctor doctor;
  final String? hospitalName;
  final String? department;

  MyAppointment({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    required this.reason,
    required this.doctor,
    this.hospitalName,
    this.department,
  });

  factory MyAppointment.fromJson(Map<String, dynamic> json) {
    return MyAppointment(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      status: json['status'] ?? '',
      reason: json['reason'] ?? '',
      doctor: Doctor.fromJson(json['doctor'] ?? {}),
      hospitalName: json['hospital_name'],
      department: json['department'],
    );
  }

  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'scheduled':
        return 'Confirmed';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'scheduled':
        return const Color(0xFF4CAF50);
      case 'completed':
        return const Color(0xFF2196F3);
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'pending':
        return const Color(0xFFFF9800);
      default:
        return Colors.grey;
    }
  }
}
