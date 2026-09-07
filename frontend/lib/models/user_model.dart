class UserModel {
  final String id;
  final String name;
  final String? phone;
  final String role; // 'civilian' or 'police'
  final String district;

  UserModel({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    required this.district,
  });

  bool get isCivilian => role.toLowerCase() == 'civilian';
  bool get isPolice => role.toLowerCase() == 'police';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? '',
      district: json['district'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (phone != null) 'phone': phone,
      'role': role,
      'district': district,
    };
  }
}
