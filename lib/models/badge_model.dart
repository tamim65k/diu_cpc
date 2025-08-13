import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeType {
  membership,
  achievement,
  participation,
  leadership,
  skill,
}

enum BadgeCategory {
  events,
  programming,
  leadership,
  community,
  special,
}

class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final BadgeCategory category;
  final int points;
  final Map<String, dynamic> criteria;
  final DateTime? earnedAt;
  final bool isActive;
  final String? color; // Hex color code for badge styling

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.category,
    this.points = 0,
    this.criteria = const {},
    this.earnedAt,
    this.isActive = true,
    this.color,
  });

  /// Create BadgeModel from Firestore document
  factory BadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BadgeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      iconUrl: data['iconUrl'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => BadgeType.achievement,
      ),
      category: BadgeCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => BadgeCategory.events,
      ),
      points: data['points'] ?? 0,
      criteria: data['criteria'] ?? {},
      earnedAt: data['earnedAt']?.toDate(),
      isActive: data['isActive'] ?? true,
      color: data['color'],
    );
  }

  /// Convert BadgeModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.toString().split('.').last,
      'category': category.toString().split('.').last,
      'points': points,
      'criteria': criteria,
      'earnedAt': earnedAt != null ? Timestamp.fromDate(earnedAt!) : null,
      'isActive': isActive,
      'color': color,
    };
  }

  /// Get badge display color
  String getDisplayColor() {
    if (color != null) return color!;
    
    switch (category) {
      case BadgeCategory.events:
        return '#4CAF50'; // Green
      case BadgeCategory.programming:
        return '#2196F3'; // Blue
      case BadgeCategory.leadership:
        return '#FF9800'; // Orange
      case BadgeCategory.community:
        return '#9C27B0'; // Purple
      case BadgeCategory.special:
        return '#F44336'; // Red
    }
  }

  /// Get badge type display name
  String getTypeDisplayName() {
    switch (type) {
      case BadgeType.membership:
        return 'Membership';
      case BadgeType.achievement:
        return 'Achievement';
      case BadgeType.participation:
        return 'Participation';
      case BadgeType.leadership:
        return 'Leadership';
      case BadgeType.skill:
        return 'Skill';
    }
  }

  /// Get badge category display name
  String getCategoryDisplayName() {
    switch (category) {
      case BadgeCategory.events:
        return 'Events';
      case BadgeCategory.programming:
        return 'Programming';
      case BadgeCategory.leadership:
        return 'Leadership';
      case BadgeCategory.community:
        return 'Community';
      case BadgeCategory.special:
        return 'Special';
    }
  }

  /// Check if badge is earned
  bool get isEarned => earnedAt != null;

  /// Get formatted earned date
  String getFormattedEarnedDate() {
    if (earnedAt == null) return 'Not earned';
    
    final now = DateTime.now();
    final difference = now.difference(earnedAt!);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BadgeModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// User Badge Model - represents a badge earned by a user
class UserBadgeModel {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final Map<String, dynamic> metadata;
  final BadgeModel? badge; // Optional badge details

  const UserBadgeModel({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    this.metadata = const {},
    this.badge,
  });

  /// Create UserBadgeModel from Firestore document
  factory UserBadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadgeModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      badgeId: data['badgeId'] ?? '',
      earnedAt: data['earnedAt']?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  /// Convert UserBadgeModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'badgeId': badgeId,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'metadata': metadata,
    };
  }

  /// Create UserBadgeModel with badge details
  UserBadgeModel copyWithBadge(BadgeModel badge) {
    return UserBadgeModel(
      id: id,
      userId: userId,
      badgeId: badgeId,
      earnedAt: earnedAt,
      metadata: metadata,
      badge: badge,
    );
  }
}
