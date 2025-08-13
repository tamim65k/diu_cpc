import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementPriority {
  low,
  normal,
  high,
  urgent,
}

enum AnnouncementCategory {
  general,
  events,
  academic,
  technical,
  administrative,
  social,
}

enum AnnouncementStatus {
  draft,
  published,
  archived,
}

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final AnnouncementPriority priority;
  final AnnouncementCategory category;
  final AnnouncementStatus status;
  final List<String> tags;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool isPinned;
  final int viewCount;
  final List<String> targetAudience; // Empty means all users
  final Map<String, dynamic> metadata;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.priority = AnnouncementPriority.normal,
    this.category = AnnouncementCategory.general,
    this.status = AnnouncementStatus.draft,
    this.tags = const [],
    this.imageUrl,
    this.publishedAt,
    this.expiresAt,
    this.isPinned = false,
    this.viewCount = 0,
    this.targetAudience = const [],
    this.metadata = const {},
  });

  /// Create AnnouncementModel from Firestore document
  factory AnnouncementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AnnouncementModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      priority: AnnouncementPriority.values.firstWhere(
        (e) => e.toString().split('.').last == data['priority'],
        orElse: () => AnnouncementPriority.normal,
      ),
      category: AnnouncementCategory.values.firstWhere(
        (e) => e.toString().split('.').last == data['category'],
        orElse: () => AnnouncementCategory.general,
      ),
      status: AnnouncementStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => AnnouncementStatus.draft,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      publishedAt: data['publishedAt']?.toDate(),
      expiresAt: data['expiresAt']?.toDate(),
      isPinned: data['isPinned'] ?? false,
      viewCount: data['viewCount'] ?? 0,
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      metadata: data['metadata'] ?? {},
    );
  }

  /// Convert AnnouncementModel to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'priority': priority.toString().split('.').last,
      'category': category.toString().split('.').last,
      'status': status.toString().split('.').last,
      'tags': tags,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'publishedAt': publishedAt != null ? Timestamp.fromDate(publishedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isPinned': isPinned,
      'viewCount': viewCount,
      'targetAudience': targetAudience,
      'metadata': metadata,
    };
  }

  /// Get priority display name
  String getPriorityDisplayName() {
    switch (priority) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.normal:
        return 'Normal';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  /// Get priority color
  String getPriorityColor() {
    switch (priority) {
      case AnnouncementPriority.low:
        return '#4CAF50'; // Green
      case AnnouncementPriority.normal:
        return '#2196F3'; // Blue
      case AnnouncementPriority.high:
        return '#FF9800'; // Orange
      case AnnouncementPriority.urgent:
        return '#F44336'; // Red
    }
  }

  /// Get category display name
  String getCategoryDisplayName() {
    switch (category) {
      case AnnouncementCategory.general:
        return 'General';
      case AnnouncementCategory.events:
        return 'Events';
      case AnnouncementCategory.academic:
        return 'Academic';
      case AnnouncementCategory.technical:
        return 'Technical';
      case AnnouncementCategory.administrative:
        return 'Administrative';
      case AnnouncementCategory.social:
        return 'Social';
    }
  }

  /// Get category icon
  String getCategoryIcon() {
    switch (category) {
      case AnnouncementCategory.general:
        return '📢';
      case AnnouncementCategory.events:
        return '🎉';
      case AnnouncementCategory.academic:
        return '📚';
      case AnnouncementCategory.technical:
        return '💻';
      case AnnouncementCategory.administrative:
        return '📋';
      case AnnouncementCategory.social:
        return '🤝';
    }
  }

  /// Check if announcement is published and not expired
  bool get isActive {
    if (status != AnnouncementStatus.published) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  /// Check if announcement is expired
  bool get isExpired {
    return expiresAt != null && DateTime.now().isAfter(expiresAt!);
  }

  /// Get formatted published date
  String getFormattedPublishedDate() {
    if (publishedAt == null) return 'Not published';
    
    final now = DateTime.now();
    final difference = now.difference(publishedAt!);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${publishedAt!.day}/${publishedAt!.month}/${publishedAt!.year}';
    }
  }

  /// Get content preview (first 150 characters)
  String getContentPreview({int maxLength = 150}) {
    if (content.length <= maxLength) return content;
    return '${content.substring(0, maxLength)}...';
  }

  /// Create a copy with updated fields
  AnnouncementModel copyWith({
    String? title,
    String? content,
    AnnouncementPriority? priority,
    AnnouncementCategory? category,
    AnnouncementStatus? status,
    List<String>? tags,
    String? imageUrl,
    DateTime? updatedAt,
    DateTime? publishedAt,
    DateTime? expiresAt,
    bool? isPinned,
    int? viewCount,
    List<String>? targetAudience,
    Map<String, dynamic>? metadata,
  }) {
    return AnnouncementModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId,
      authorName: authorName,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPinned: isPinned ?? this.isPinned,
      viewCount: viewCount ?? this.viewCount,
      targetAudience: targetAudience ?? this.targetAudience,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnnouncementModel && 
      runtimeType == other.runtimeType && 
      id == other.id;

  @override
  int get hashCode => id.hashCode;
}
