import 'package:cloud_firestore/cloud_firestore.dart';

enum MembershipStatus { pending, approved, rejected, suspended }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String academicYear;
  final String studentId;
  final String batch;
  final String bloodGroup;
  final String emergencyContact;
  final String address;
  final String bio;
  final DateTime? dateOfBirth;
  final Map<String, String> socialLinks;
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
    this.phone = '',
    this.department = '',
    this.academicYear = '',
    this.studentId = '',
    this.batch = '',
    this.bloodGroup = '',
    this.emergencyContact = '',
    this.address = '',
    this.bio = '',
    this.dateOfBirth,
    this.socialLinks = const {},
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
      studentId: map['studentId'] ?? '',
      batch: map['batch'] ?? '',
      bloodGroup: map['bloodGroup'] ?? '',
      emergencyContact: map['emergencyContact'] ?? '',
      address: map['address'] ?? '',
      bio: map['bio'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['dateOfBirth'])
          : null,
      socialLinks: map['socialLinks'] != null 
          ? Map<String, String>.from(map['socialLinks'])
          : {},
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
      studentId: data['studentId'] ?? '',
      batch: data['batch'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      emergencyContact: data['emergencyContact'] ?? '',
      address: data['address'] ?? '',
      bio: data['bio'] ?? '',
      dateOfBirth: data['dateOfBirth'] != null 
          ? (data['dateOfBirth'] as Timestamp).toDate()
          : null,
      socialLinks: data['socialLinks'] != null 
          ? Map<String, String>.from(data['socialLinks'] as Map)
          : {},
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
      'studentId': studentId,
      'batch': batch,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'address': address,
      'bio': bio,
      'dateOfBirth': dateOfBirth?.millisecondsSinceEpoch,
      'socialLinks': socialLinks,
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
      'studentId': studentId,
      'batch': batch,
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'address': address,
      'bio': bio,
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'socialLinks': socialLinks,
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
    String? studentId,
    String? batch,
    String? bloodGroup,
    String? emergencyContact,
    String? address,
    String? bio,
    DateTime? dateOfBirth,
    Map<String, String>? socialLinks,
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
      studentId: studentId ?? this.studentId,
      batch: batch ?? this.batch,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isApproved: isApproved ?? this.isApproved,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      membershipStatus: membershipStatus ?? this.membershipStatus,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}
