import 'package:flutter/material.dart';

class DoctorDetails {
  final int id;
  final String name;
  final String? specialization;
  final String? hospitalName;
  final String? address;

  DoctorDetails({
    required this.id,
    required this.name,
    this.specialization,
    this.hospitalName,
    this.address,
  });

  factory DoctorDetails.fromJson(Map<String, dynamic> json) {
    return DoctorDetails(
      id: json['id'],
      name: json['name'] ?? '',
      specialization: json['specialization'],
      hospitalName: json['hospital_name'],
      address: json['address'],
    );
  }
}

class Doctor {
  final int id;
  final String name;
  final String specialization;
  final String? hospitalName;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    this.hospitalName,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'],
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      hospitalName: json['hospital_name'] ?? json['hospitalName'],
    );
  }
}

class DoctorSlotsResponse {
  final DoctorDetails doctor;
  final List<SlotDay> days;

  DoctorSlotsResponse({
    required this.doctor,
    required this.days,
  });

  factory DoctorSlotsResponse.fromJson(Map<String, dynamic> json) {
    final daysJson = json['days'] as List<dynamic>? ?? 
                    json['availability'] as List<dynamic>? ?? 
                    json['available_slots'] as List<dynamic>? ?? 
                    json['slots'] as List<dynamic>? ?? [];
    
    print('DEBUG: DoctorSlotsResponse parsing:');
    print('  Doctor: ${json['doctor']}');
    print('  Days count: ${daysJson.length}');
    
    final doctorData = json['doctor'] ?? json;
    
    return DoctorSlotsResponse(
      doctor: DoctorDetails.fromJson(doctorData),
      days: daysJson.map((e) => SlotDay.fromJson(e)).toList(),
    );
  }
}

  String _convertTo12HourFormat(String time24) {
    if (time24.isEmpty) return time24;
    
    if (time24.toUpperCase().contains('AM') || time24.toUpperCase().contains('PM')) {
      return time24;
    }
    
    final parts = time24.trim().split(':');
    if (parts.length < 2) return time24;
    
    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1].length > 2 ? parts[1].substring(0, 2) : parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    
    final hourStr = hour.toString().padLeft(2, '0');
    return '$hourStr:$minute $period';
  }

class Slot {
  final int id;
  final String start;
  final String end;
  final String displayTime;

  Slot({
    required this.id,
    required this.start,
    required this.end,
    this.displayTime = '',
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['availability_id'] ?? 0;
    final timeField = json['time'] ?? json['start_time'] ?? json['start'] ?? '';
    final endField = json['end'] ?? json['end_time'] ?? '';
    
    String displayTime = '';
    String startTime = '';
    String endTime = '';
    
    if (timeField.contains('-') && !timeField.contains(':')) {
      final parts = timeField.split(' - ');
      startTime = parts.isNotEmpty ? _convertTo12HourFormat(parts[0].trim()) : '';
      endTime = parts.length > 1 ? _convertTo12HourFormat(parts[1].trim()) : '';
      displayTime = timeField;
    } else {
      startTime = _convertTo12HourFormat(timeField);
      endTime = _convertTo12HourFormat(endField);
      displayTime = startTime;
    }
    
    if (startTime.isEmpty && endTime.isEmpty && json.toString().isNotEmpty) {
      displayTime = json.toString();
      startTime = 'Slot';
      endTime = json.toString();
    }
    
    return Slot(
      id: id,
      start: startTime,
      end: endTime,
      displayTime: displayTime,
    );
  }
  
  @override
  String toString() {
    return 'Slot(id: $id, start: $start, end: $end, displayTime: $displayTime)';
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
    final slotsJson = json['slots'] as List<dynamic>? ?? 
                    json['available_slots'] as List<dynamic>? ?? 
                    json['timeslots'] as List<dynamic>? ?? [];
    final dateValue = json['date'] ?? json['day'] ?? '';
    final labelValue = json['label'] ?? json['day_name'] ?? '';
    
    print('DEBUG: SlotDay parsing:');
    print('  Date: $dateValue');
    print('  Label: $labelValue');
    print('  Slots count: ${slotsJson.length}');
    for (var i = 0; i < slotsJson.length && i < 3; i++) {
      print('  Slot $i: ${slotsJson[i]}');
    }
    
    return SlotDay(
      date: dateValue,
      label: labelValue,
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

  DateTime? get appointmentDateTime {
    try {
      final dateParts = date.split('-');
      if (dateParts.length != 3) return null;
      
      int? hour;
      int? minute;
      
      if (time.toUpperCase().contains('AM') || time.toUpperCase().contains('PM')) {
        final cleanTime = time.toUpperCase().replaceAll('AM', '').replaceAll('PM', '').trim();
        final timeParts = cleanTime.split(':');
        if (timeParts.length != 2) return null;
        
        final baseHour = int.tryParse(timeParts[0]);
        minute = int.tryParse(timeParts[1]);
        
        if (baseHour == null || minute == null) return null;
        
        if (time.toUpperCase().contains('PM') && baseHour != 12) {
          hour = baseHour + 12;
        } else if (time.toUpperCase().contains('AM') && baseHour == 12) {
          hour = 0;
        } else {
          hour = baseHour;
        }
      }
      else {
        final timeParts = time.split(':');
        if (timeParts.length != 2) return null;
        hour = int.tryParse(timeParts[0]);
        minute = int.tryParse(timeParts[1]);
        
        if (hour == null || minute == null) return null;
      }
      
      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);
      
      if (year == null || month == null || day == null) return null;
      
      return DateTime(year,
          month, day, hour, minute);
    } catch (e) {
      return null;
    }
  }

  Duration? get timeFromNow {
    final appointmentTime = appointmentDateTime;
    if (appointmentTime == null) return null;
    return appointmentTime.difference(DateTime.now());
  }
}

class LocalNotification {
  final int id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final int? appointmentId;

  LocalNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.appointmentId,
  });

  factory LocalNotification.fromJson(Map<String, dynamic> json) {
    return LocalNotification(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      isRead: json['is_read'] ?? false,
      appointmentId: json['appointment_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'appointment_id': appointmentId,
    };
  }
}

