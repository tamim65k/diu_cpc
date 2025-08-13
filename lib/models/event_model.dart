import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { upcoming, ongoing, completed, cancelled }

enum EventCategory { workshop, contest, seminar, meetup, general }

class EventModel {
  final String id;
  final String title;
  final String description;
  final String agenda;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String venue;
  final String? location; // For map integration
  final EventCategory category;
  final EventStatus status;
  final String organizerName;
  final String organizerEmail;
  final String? organizerPhone;
  final List<String> speakers;
  final int maxParticipants;
  final int currentParticipants;
  final List<String> registeredUsers;
  final List<String> waitlistUsers;
  final String? imageUrl;
  final List<String> requirements;
  final bool requiresApproval;
  final double? registrationFee;
  final DateTime? registrationDeadline;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic>? additionalInfo;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.agenda,
    required this.startDateTime,
    required this.endDateTime,
    required this.venue,
    this.location,
    required this.category,
    required this.status,
    required this.organizerName,
    required this.organizerEmail,
    this.organizerPhone,
    required this.speakers,
    required this.maxParticipants,
    this.currentParticipants = 0,
    required this.registeredUsers,
    required this.waitlistUsers,
    this.imageUrl,
    required this.requirements,
    this.requiresApproval = false,
    this.registrationFee,
    this.registrationDeadline,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.additionalInfo,
  });

  // Factory constructor to create EventModel from Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return EventModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      agenda: data['agenda'] ?? '',
      startDateTime: (data['startDateTime'] as Timestamp).toDate(),
      endDateTime: (data['endDateTime'] as Timestamp).toDate(),
      venue: data['venue'] ?? '',
      location: data['location'],
      category: EventCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => EventCategory.general,
      ),
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => EventStatus.upcoming,
      ),
      organizerName: data['organizerName'] ?? '',
      organizerEmail: data['organizerEmail'] ?? '',
      organizerPhone: data['organizerPhone'],
      speakers: List<String>.from(data['speakers'] ?? []),
      maxParticipants: data['maxParticipants'] ?? 0,
      currentParticipants: data['currentParticipants'] ?? 0,
      registeredUsers: List<String>.from(data['registeredUsers'] ?? []),
      waitlistUsers: List<String>.from(data['waitlistUsers'] ?? []),
      imageUrl: data['imageUrl'],
      requirements: List<String>.from(data['requirements'] ?? []),
      requiresApproval: data['requiresApproval'] ?? false,
      registrationFee: data['registrationFee']?.toDouble(),
      registrationDeadline: data['registrationDeadline'] != null
          ? (data['registrationDeadline'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      additionalInfo: data['additionalInfo'],
    );
  }

  // Convert EventModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'agenda': agenda,
      'startDateTime': Timestamp.fromDate(startDateTime),
      'endDateTime': Timestamp.fromDate(endDateTime),
      'venue': venue,
      'location': location,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'organizerName': organizerName,
      'organizerEmail': organizerEmail,
      'organizerPhone': organizerPhone,
      'speakers': speakers,
      'maxParticipants': maxParticipants,
      'currentParticipants': currentParticipants,
      'registeredUsers': registeredUsers,
      'waitlistUsers': waitlistUsers,
      'imageUrl': imageUrl,
      'requirements': requirements,
      'requiresApproval': requiresApproval,
      'registrationFee': registrationFee,
      'registrationDeadline': registrationDeadline != null
          ? Timestamp.fromDate(registrationDeadline!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'additionalInfo': additionalInfo,
    };
  }

  // Helper methods
  bool get isUpcoming => status == EventStatus.upcoming;
  bool get isOngoing => status == EventStatus.ongoing;
  bool get isCompleted => status == EventStatus.completed;
  bool get isCancelled => status == EventStatus.cancelled;
  bool get isFull => currentParticipants >= maxParticipants;
  bool get hasWaitlist => waitlistUsers.isNotEmpty;
  bool get isRegistrationOpen => 
      isUpcoming && 
      (registrationDeadline == null || DateTime.now().isBefore(registrationDeadline!));

  Duration get timeUntilStart => startDateTime.difference(DateTime.now());
  Duration get duration => endDateTime.difference(startDateTime);

  String getFormattedDate() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = startDateTime.day;
    final month = months[startDateTime.month - 1];
    final year = startDateTime.year;
    final hour = startDateTime.hour;
    final minute = startDateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$day $month $year, $displayHour:$minute $period';
  }

  String get categoryDisplayName {
    switch (category) {
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.contest:
        return 'Contest';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.meetup:
        return 'Meetup';
      case EventCategory.general:
        return 'General';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case EventStatus.upcoming:
        return 'Upcoming';
      case EventStatus.ongoing:
        return 'Ongoing';
      case EventStatus.completed:
        return 'Completed';
      case EventStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Copy with method for updates
  EventModel copyWith({
    String? title,
    String? description,
    String? agenda,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? venue,
    String? location,
    EventCategory? category,
    EventStatus? status,
    String? organizerName,
    String? organizerEmail,
    String? organizerPhone,
    List<String>? speakers,
    int? maxParticipants,
    int? currentParticipants,
    List<String>? registeredUsers,
    List<String>? waitlistUsers,
    String? imageUrl,
    List<String>? requirements,
    bool? requiresApproval,
    double? registrationFee,
    DateTime? registrationDeadline,
    DateTime? updatedAt,
    Map<String, dynamic>? additionalInfo,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      agenda: agenda ?? this.agenda,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      venue: venue ?? this.venue,
      location: location ?? this.location,
      category: category ?? this.category,
      status: status ?? this.status,
      organizerName: organizerName ?? this.organizerName,
      organizerEmail: organizerEmail ?? this.organizerEmail,
      organizerPhone: organizerPhone ?? this.organizerPhone,
      speakers: speakers ?? this.speakers,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      registeredUsers: registeredUsers ?? this.registeredUsers,
      waitlistUsers: waitlistUsers ?? this.waitlistUsers,
      imageUrl: imageUrl ?? this.imageUrl,
      requirements: requirements ?? this.requirements,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      registrationFee: registrationFee ?? this.registrationFee,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      createdBy: createdBy,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
