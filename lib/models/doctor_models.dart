class Doctor {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? qualification;
  final String? specialization;
  final int? experience;
  final String? experienceUnit;
  final String? about;
  final String? profileImage;
  final int? hospitalId;
  final String? hospitalName;
  final int? departmentId;
  final String? departmentName;
  final double? rating;
  final int? reviewCount;
  final bool isActive;
  final String? availableFrom;
  final String? availableTo;
  final List<String>? availableDays;

  Doctor({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.qualification,
    this.specialization,
    this.experience,
    this.experienceUnit,
    this.about,
    this.profileImage,
    this.hospitalId,
    this.hospitalName,
    this.departmentId,
    this.departmentName,
    this.rating,
    this.reviewCount,
    this.isActive = true,
    this.availableFrom,
    this.availableTo,
    this.availableDays,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['contact_number'] ?? json['phone'],
      qualification: json['qualification'],
      specialization: json['specialization'],
      experience: json['years_of_experience'] ?? json['experience'],
      experienceUnit: json['experience_unit'] ?? 'years',
      about: json['about'],
      profileImage: json['profile_image'] ?? json['passport_photo'] ?? json['image'],
      hospitalId: json['hospital_id'] ?? json['hospital'],
      hospitalName: json['hospital_name'],
      departmentId: json['department_id'] ?? json['department'],
      departmentName: json['department_name'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'],
      isActive: json['is_active'] ?? json['is_approved'] ?? json['active'] ?? true,
      availableFrom: json['available_from'],
      availableTo: json['available_to'],
      availableDays: json['available_days'] != null
          ? List<String>.from(json['available_days'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'qualification': qualification,
      'specialization': specialization,
      'experience': experience,
      'experience_unit': experienceUnit,
      'about': about,
      'profile_image': profileImage,
      'hospital_id': hospitalId,
      'hospital_name': hospitalName,
      'department_id': departmentId,
      'department_name': departmentName,
      'rating': rating,
      'review_count': reviewCount,
      'is_active': isActive,
      'available_from': availableFrom,
      'available_to': availableTo,
      'available_days': availableDays,
    };
  }

  String get experienceText {
    if (experience == null) return '';
    return '$experience ${experienceUnit ?? 'years'}';
  }
}