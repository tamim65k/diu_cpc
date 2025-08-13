import 'package:cloud_firestore/cloud_firestore.dart';

enum ContactStatus {
  pending,
  inProgress,
  resolved,
}

class ContactModel {
  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String? userId;
  final ContactStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? adminResponse;

  ContactModel({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.userId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.adminResponse,
  });

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      userId: map['userId'],
      status: _parseStatus(map['status']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      adminResponse: map['adminResponse'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'userId': userId,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'adminResponse': adminResponse,
    };
  }

  static ContactStatus _parseStatus(dynamic status) {
    if (status == null) return ContactStatus.pending;
    
    switch (status.toString()) {
      case 'pending':
        return ContactStatus.pending;
      case 'inProgress':
      case 'in_progress':
        return ContactStatus.inProgress;
      case 'resolved':
        return ContactStatus.resolved;
      default:
        return ContactStatus.pending;
    }
  }

  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else {
      return DateTime.now();
    }
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    String? userId,
    ContactStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ContactStatus.pending:
        return 'Pending';
      case ContactStatus.inProgress:
        return 'In Progress';
      case ContactStatus.resolved:
        return 'Resolved';
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, name: $name, email: $email, subject: $subject, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContactModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.subject == subject &&
        other.message == message &&
        other.userId == userId &&
        other.status == status &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.adminResponse == adminResponse;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        subject.hashCode ^
        message.hashCode ^
        userId.hashCode ^
        status.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        adminResponse.hashCode;
  }
}
