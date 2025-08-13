import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/announcement_model.dart';

class AnnouncementService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all published announcements
  static Future<List<AnnouncementModel>> getPublishedAnnouncements({
    int limit = 20,
    AnnouncementCategory? category,
    List<String>? tags,
  }) async {
    try {
      Query query = _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .orderBy('isPinned', descending: true)
          .orderBy('publishedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive) // Filter out expired
          .toList();
    } catch (e) {
      print('Error getting published announcements: $e');
      return [];
    }
  }

  /// Get announcement by ID
  static Future<AnnouncementModel?> getAnnouncementById(String id) async {
    try {
      final doc = await _firestore.collection('announcements').doc(id).get();
      if (doc.exists) {
        return AnnouncementModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting announcement by ID: $e');
      return null;
    }
  }

  /// Create new announcement
  static Future<String?> createAnnouncement(AnnouncementModel announcement) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final docRef = await _firestore.collection('announcements').add(announcement.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating announcement: $e');
      return null;
    }
  }

  /// Update announcement
  static Future<bool> updateAnnouncement(String id, AnnouncementModel announcement) async {
    try {
      await _firestore
          .collection('announcements')
          .doc(id)
          .update(announcement.toFirestore());
      return true;
    } catch (e) {
      print('Error updating announcement: $e');
      return false;
    }
  }

  /// Delete announcement
  static Future<bool> deleteAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting announcement: $e');
      return false;
    }
  }

  /// Publish announcement
  static Future<bool> publishAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).update({
        'status': 'published',
        'publishedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error publishing announcement: $e');
      return false;
    }
  }

  /// Archive announcement
  static Future<bool> archiveAnnouncement(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).update({
        'status': 'archived',
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error archiving announcement: $e');
      return false;
    }
  }

  /// Increment view count
  static Future<void> incrementViewCount(String id) async {
    try {
      await _firestore.collection('announcements').doc(id).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing view count: $e');
    }
  }

  /// Get announcements by category
  static Future<List<AnnouncementModel>> getAnnouncementsByCategory(
    AnnouncementCategory category, {
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .where('category', isEqualTo: category.toString().split('.').last)
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)
          .toList();
    } catch (e) {
      print('Error getting announcements by category: $e');
      return [];
    }
  }

  /// Search announcements
  static Future<List<AnnouncementModel>> searchAnnouncements(
    String searchTerm, {
    int limit = 20,
    AnnouncementCategory? category,
  }) async {
    try {
      Query query = _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published');

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      final querySnapshot = await query
          .orderBy('publishedAt', descending: true)
          .limit(limit * 2) // Get more to filter
          .get();

      final announcements = querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)
          .where((announcement) =>
              announcement.title.toLowerCase().contains(searchTerm.toLowerCase()) ||
              announcement.content.toLowerCase().contains(searchTerm.toLowerCase()) ||
              announcement.tags.any((tag) => tag.toLowerCase().contains(searchTerm.toLowerCase())))
          .take(limit)
          .toList();

      return announcements;
    } catch (e) {
      print('Error searching announcements: $e');
      return [];
    }
  }

  /// Get pinned announcements
  static Future<List<AnnouncementModel>> getPinnedAnnouncements() async {
    try {
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .where('isPinned', isEqualTo: true)
          .orderBy('publishedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)
          .toList();
    } catch (e) {
      print('Error getting pinned announcements: $e');
      return [];
    }
  }

  /// Get recent announcements (for homepage)
  static Future<List<AnnouncementModel>> getRecentAnnouncements({int limit = 5}) async {
    try {
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)
          .toList();
    } catch (e) {
      print('Error getting recent announcements: $e');
      return [];
    }
  }

  /// Get announcements stream for real-time updates
  static Stream<List<AnnouncementModel>> getAnnouncementsStream({
    int limit = 20,
    AnnouncementCategory? category,
  }) {
    try {
      Query query = _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .orderBy('isPinned', descending: true)
          .orderBy('publishedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      return query.limit(limit).snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => AnnouncementModel.fromFirestore(doc))
            .where((announcement) => announcement.isActive)
            .toList();
      });
    } catch (e) {
      print('Error getting announcements stream: $e');
      return Stream.value([]);
    }
  }

  /// Get all categories with announcement counts
  static Future<Map<AnnouncementCategory, int>> getCategoryCounts() async {
    try {
      final querySnapshot = await _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'published')
          .get();

      final announcements = querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .where((announcement) => announcement.isActive)
          .toList();

      Map<AnnouncementCategory, int> counts = {};
      for (var category in AnnouncementCategory.values) {
        counts[category] = announcements
            .where((announcement) => announcement.category == category)
            .length;
      }

      return counts;
    } catch (e) {
      print('Error getting category counts: $e');
      return {};
    }
  }

  /// Initialize sample announcements (for testing)
  static Future<void> initializeSampleAnnouncements() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final sampleAnnouncements = _getSampleAnnouncements(user);
      
      for (AnnouncementModel announcement in sampleAnnouncements) {
        // Check if announcement already exists
        final existingQuery = await _firestore
            .collection('announcements')
            .where('title', isEqualTo: announcement.title)
            .get();
        
        if (existingQuery.docs.isEmpty) {
          await _firestore
              .collection('announcements')
              .add(announcement.toFirestore());
        }
      }
    } catch (e) {
      print('Error initializing sample announcements: $e');
    }
  }

  /// Get sample announcements for testing
  static List<AnnouncementModel> _getSampleAnnouncements(User user) {
    final now = DateTime.now();
    return [
      AnnouncementModel(
        id: '',
        title: 'Welcome to DIU CPC Hackathon 2025!',
        content: 'We are excited to announce the DIU CPC Hackathon 2025! Join us for an amazing coding competition with great prizes and networking opportunities. Registration is now open for all DIU students.',
        authorId: user.uid,
        authorName: user.displayName ?? 'Admin',
        priority: AnnouncementPriority.high,
        category: AnnouncementCategory.events,
        status: AnnouncementStatus.published,
        tags: ['hackathon', 'competition', 'coding'],
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        publishedAt: now.subtract(const Duration(days: 2)),
        isPinned: true,
      ),
      AnnouncementModel(
        id: '',
        title: 'New Workshop: Flutter Development Basics',
        content: 'Learn the fundamentals of Flutter development in our upcoming workshop. Perfect for beginners who want to start mobile app development. Limited seats available!',
        authorId: user.uid,
        authorName: user.displayName ?? 'Admin',
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.technical,
        status: AnnouncementStatus.published,
        tags: ['workshop', 'flutter', 'mobile'],
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      AnnouncementModel(
        id: '',
        title: 'Club Meeting - January 2025',
        content: 'Monthly club meeting to discuss upcoming events, new initiatives, and member feedback. All members are encouraged to attend and share their ideas.',
        authorId: user.uid,
        authorName: user.displayName ?? 'Admin',
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.general,
        status: AnnouncementStatus.published,
        tags: ['meeting', 'monthly', 'discussion'],
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        publishedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
