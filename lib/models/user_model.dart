class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String department;
  final String academicYear;
  final DateTime createdAt;
  final bool isApproved;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.department,
    required this.academicYear,
    required this.createdAt,
    this.isApproved = false,
    this.isEmailVerified = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      department: map['department'] ?? '',
      academicYear: map['academicYear'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isApproved: map['isApproved'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'department': department,
      'academicYear': academicYear,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isApproved': isApproved,
      'isEmailVerified': isEmailVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? department,
    String? academicYear,
    DateTime? createdAt,
    bool? isApproved,
    bool? isEmailVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      createdAt: createdAt ?? this.createdAt,
      isApproved: isApproved ?? this.isApproved,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
