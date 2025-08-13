import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { pending, approved, rejected, suspended }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String academicYear;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isApproved;
  final bool isEmailVerified;
  final MembershipStatus membershipStatus;
  final String? profileImageUrl;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.academicYear,
    required this.createdAt,
    required this.updatedAt,
    this.isApproved = false,
    this.isEmailVerified = false,
    this.membershipStatus = MembershipStatus.pending,
    this.profileImageUrl,
  });

  // Backward compatibility getters
  String get id => uid;
  String get fullName => name;
  String get phoneNumber => phone;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? map['id'] ?? '',
      name: map['name'] ?? map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? map['phoneNumber'] ?? '',
      department: map['department'] ?? '',
      academicYear: map['academicYear'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
      isApproved: map['isApproved'] ?? false,
      isEmailVerified: map['isEmailVerified'] ?? false,
      membershipStatus: MembershipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['membershipStatus'],
        orElse: () => MembershipStatus.pending,
      ),
      profileImageUrl: map['profileImageUrl'],
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? data['phoneNumber'] ?? '',
      department: data['department'] ?? '',
      academicYear: data['academicYear'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isApproved: data['isApproved'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      membershipStatus: MembershipStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['membershipStatus'],
        orElse: () => MembershipStatus.pending,
      ),
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'academicYear': academicYear,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isApproved': isApproved,
      'isEmailVerified': isEmailVerified,
      'membershipStatus': membershipStatus.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      // Backward compatibility
      'id': uid,
      'fullName': name,
      'phoneNumber': phone,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'department': department,
      'academicYear': academicYear,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isApproved': isApproved,
      'isEmailVerified': isEmailVerified,
      'membershipStatus': membershipStatus.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? department,
    String? academicYear,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isApproved,
    bool? isEmailVerified,
    MembershipStatus? membershipStatus,
    String? profileImageUrl,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
