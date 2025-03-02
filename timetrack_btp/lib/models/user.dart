class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'worker', 'supervisor', 'admin'
  final String? phoneNumber;
  final String? profileImage;
  final bool isFirstLogin;
  final DateTime createdAt;
  final String? createdBy; // ID de l'admin qui a créé ce compte

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profileImage,
    this.isFirstLogin = false,
    DateTime? createdAt,
    this.createdBy,
  }) : this.createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      phoneNumber: json['phoneNumber'],
      profileImage: json['profileImage'],
      isFirstLogin: json['isFirstLogin'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      createdBy: json['createdBy'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phoneNumber': phoneNumber,
      'profileImage': profileImage,
      'isFirstLogin': isFirstLogin,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
  
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? phoneNumber,
    String? profileImage,
    bool? isFirstLogin,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}