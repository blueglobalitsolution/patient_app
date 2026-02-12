class Department {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;

  Department({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
  });

  factory Department.fromJson(Map<String, dynamic> json) {

    
    // Handle ID parsing more robustly
    int? departmentId;
    if (json['id'] != null) {
      if (json['id'] is int) {
        departmentId = json['id'] as int;
      } else if (json['id'] is double) {
        // Convert double to int
        departmentId = (json['id'] as double).toInt();
        print('DEBUG: Converted double ID to int: ${json['id']} -> $departmentId');
      } else if (json['id'] is String) {
        departmentId = int.tryParse(json['id'] as String);
      }
    }
    
    return Department(
      id: departmentId ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      isActive: json['is_active'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'is_active': isActive,
    };
  }
}