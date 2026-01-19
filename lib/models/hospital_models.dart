class Hospital {
  final int id;
  final String name;
  final String? address;
  final String? specialty;
  final double latitude;
  final double longitude;
  final double distance;
  final String? phone;

  Hospital({
    required this.id,
    required this.name,
    this.address,
    this.specialty,
    required this.latitude,
    required this.longitude,
    required this.distance,
    this.phone,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      specialty: json['specialty'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      distance: (json['distance'] ?? 0.0).toDouble(),
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'specialty': specialty,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'phone': phone,
    };
  }

  String getDistanceText() {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    }
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }
}

class ApprovedHospital {
  final int id;
  final String name;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? phone;
  final String? email;
  final String? logo;
  final String? description;
  final bool isActive;
  final int? totalDoctors;
  final int? totalDepartments;
  final String? createdAt;
  final String? updatedAt;

  ApprovedHospital({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.phone,
    this.email,
    this.logo,
    this.description,
    this.isActive = true,
    this.totalDoctors,
    this.totalDepartments,
    this.createdAt,
    this.updatedAt,
  });

  factory ApprovedHospital.fromJson(Map<String, dynamic> json) {
    return ApprovedHospital(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      phone: json['phone'],
      email: json['email'],
      logo: json['logo'],
      description: json['description'],
      isActive: json['is_active'] ?? json['active'] ?? true,
      totalDoctors: json['total_doctors'],
      totalDepartments: json['total_departments'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'email': email,
      'logo': logo,
      'description': description,
      'is_active': isActive,
      'total_doctors': totalDoctors,
      'total_departments': totalDepartments,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
