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
