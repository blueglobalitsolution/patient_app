class PatientProfile {
  final int id;
  final String email;
  final String fullName;
  final String? phone;
  final String? address;
  final int? age;
  final String? gender;

  PatientProfile({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address,
    this.age,
    this.gender,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? json['name'] ?? '',
      phone: json['phone_number']?.toString() ?? json['phone']?.toString(),
      address: json['address'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'phone_number': phone,
      'address': address,
      'age': age,
      'gender': gender,
    };
  }
}

class MedicalRecord {
  final int id;
  final String date;
  final String diagnosis;
  final String? notes;
  final String? doctor;
  final String? hospital;
  final String? department;

  MedicalRecord({
    required this.id,
    required this.date,
    required this.diagnosis,
    this.notes,
    this.doctor,
    this.hospital,
    this.department,
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      notes: json['notes'],
      doctor: json['doctor']?.toString() ?? json['doctor_name'],
      hospital: json['hospital']?.toString() ?? json['hospital_name'],
      department: json['department'],
    );
  }
}

class PatientNotification {
  final int id;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;
  final String? type;
  final String? appointmentId;

  PatientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.appointmentId,
  });

  factory PatientNotification.fromJson(Map<String, dynamic> json) {
    return PatientNotification(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? json['read'] ?? false,
      createdAt: json['created_at'] ?? json['date'] ?? '',
      type: json['type'],
      appointmentId: json['appointment_id']?.toString(),
    );
  }
}
