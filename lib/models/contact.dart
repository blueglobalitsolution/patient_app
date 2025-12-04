class Contact {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String user;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.user,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      user: json['user']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'user': user,
    };
  }


}