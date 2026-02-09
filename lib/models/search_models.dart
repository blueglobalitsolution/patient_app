class SearchHospital {
  final int id;
  final String name;
  final String? department;
  final String? city;
  final String? type;
  final String? action;

  SearchHospital({
    required this.id,
    required this.name,
    this.department,
    this.city,
    this.type,
    this.action,
  });

  factory SearchHospital.fromJson(Map<String, dynamic> json) {
    return SearchHospital(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      department: json['department'],
      city: json['city'],
      type: json['type'],
      action: json['action'],
    );
  }
}

class SearchDoctor {
  final int id;
  final String name;
  final String? specialization;
  final String? treatment;
  final int? hospitalId;
  final String? hospitalName;
  final String? type;
  final String? action;

  SearchDoctor({
    required this.id,
    required this.name,
    this.specialization,
    this.treatment,
    this.hospitalId,
    this.hospitalName,
    this.type,
    this.action,
  });

  factory SearchDoctor.fromJson(Map<String, dynamic> json) {
    return SearchDoctor(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      specialization: json['specialization'],
      treatment: json['treatment'],
      hospitalId: json['hospital_id'],
      hospitalName: json['hospital_name'],
      type: json['type'],
      action: json['action'],
    );
  }
}

class SearchResult {
  final List<SearchHospital> hospitals;
  final List<SearchDoctor> doctors;
  final String? resolvedKeyword;

  SearchResult({
    required this.hospitals,
    required this.doctors,
    this.resolvedKeyword,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final hospitalsData = json['hospitals'] as List<dynamic>? ?? [];
    final doctorsData = json['doctors'] as List<dynamic>? ?? [];

    return SearchResult(
      hospitals: hospitalsData.map((e) => SearchHospital.fromJson(e)).toList(),
      doctors: doctorsData.map((e) => SearchDoctor.fromJson(e)).toList(),
      resolvedKeyword: json['resolved_keyword'],
    );
  }

  bool get hasResults => hospitals.isNotEmpty || doctors.isNotEmpty;
}
