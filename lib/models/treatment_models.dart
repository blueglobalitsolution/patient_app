class Treatment {
  final int id;
  final String name;
  final String? description;
  final String? category;
  final int? departmentId;
  final String? departmentName;
  final int? estimatedDuration;
  final String? estimatedDurationUnit;
  final bool isActive;

  Treatment({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.departmentId,
    this.departmentName,
    this.estimatedDuration,
    this.estimatedDurationUnit,
    this.isActive = true,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      category: json['category'],
      departmentId: json['department_id'],
      departmentName: json['department_name'],
      estimatedDuration: json['estimated_duration'],
      estimatedDurationUnit: json['estimated_duration_unit'],
      isActive: json['is_active'] ?? json['active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'department_id': departmentId,
      'department_name': departmentName,
      'estimated_duration': estimatedDuration,
      'estimated_duration_unit': estimatedDurationUnit,
      'is_active': isActive,
    };
  }
}