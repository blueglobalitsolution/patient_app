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
  final String? pNumber;
  final String? email;
  final String? logo;
  final List<String>? hospitalType;
  final int? totalDoctors;
  final int? totalDepartments;

  ApprovedHospital({
    required this.id,
    required this.name,
    this.address,
    this.city,
    this.pNumber,
    this.email,
    this.logo,
    this.hospitalType,
    this.totalDoctors,
    this.totalDepartments,
  });

  factory ApprovedHospital.fromJson(Map<String, dynamic> json) {
    return ApprovedHospital(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'],
      city: json['city'],
      pNumber: json['p_number']?.toString(),
      email: json['email'],
      logo: json['logo'],
      hospitalType: json['hospital_type'] != null 
          ? List<String>.from(json['hospital_type']) 
          : null,
      totalDoctors: json['total_doctors'],
      totalDepartments: json['total_departments'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'p_number': pNumber,
      'email': email,
      'logo': logo,
      'hospital_type': hospitalType,
      'total_doctors': totalDoctors,
      'total_departments': totalDepartments,
    };
  }
}
