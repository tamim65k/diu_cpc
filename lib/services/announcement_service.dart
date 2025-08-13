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

  /// Demo announcements for UI fallback (does not write to Firestore)
  static List<AnnouncementModel> getDemoAnnouncements() {
    final now = DateTime.now();
    const authorId = 'demo-admin';
    const authorName = 'Admin';
    return [
      AnnouncementModel(
        id: 'demo-1',
        title: 'Welcome to DIU CPC Hackathon 2025! 🎉',
        content:
            'Join the DIU CPC Hackathon 2025 for prizes, mentorship, and fun. Registration is open now for all DIU students.',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.high,
        category: AnnouncementCategory.events,
        status: AnnouncementStatus.published,
        tags: const ['hackathon', 'competition', 'coding'],
        imageUrl:
            'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        publishedAt: now.subtract(const Duration(days: 3)),
        isPinned: true,
      ),
      AnnouncementModel(
        id: 'demo-2',
        title: 'Flutter Workshop: Build Your First App',
        content:
            'Hands-on session covering Flutter basics, widgets, and state management. Limited seats — register early!',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.technical,
        status: AnnouncementStatus.published,
        tags: const ['workshop', 'flutter', 'mobile'],
        imageUrl:
            'https://images.unsplash.com/photo-1551817958-20204d6ab464?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
        publishedAt: now.subtract(const Duration(days: 2)),
      ),
      AnnouncementModel(
        id: 'demo-3',
        title: 'Semester Midterm Schedule Released',
        content:
            'The academic office has published the midterm exam schedule. Please review and prepare accordingly.',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.academic,
        status: AnnouncementStatus.published,
        tags: const ['midterm', 'schedule', 'academic'],
        imageUrl:
            'https://images.unsplash.com/photo-1517048676732-d65bc937f952?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
        publishedAt: now.subtract(const Duration(days: 4)),
      ),
      AnnouncementModel(
        id: 'demo-4',
        title: 'Administrative Notice: ID Card Renewal',
        content:
            'Students whose ID cards expire this term should renew at the admin desk by the end of the month.',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.low,
        category: AnnouncementCategory.administrative,
        status: AnnouncementStatus.published,
        tags: const ['administrative', 'id-card'],
        imageUrl:
            'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
        publishedAt: now.subtract(const Duration(days: 6)),
      ),
      AnnouncementModel(
        id: 'demo-5',
        title: 'Club Meeting: January Highlights',
        content:
            'Monthly club meeting to discuss new initiatives, events, and member feedback. Everyone is welcome!',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.general,
        status: AnnouncementStatus.published,
        tags: const ['meeting', 'monthly', 'community'],
        imageUrl:
            'https://images.unsplash.com/photo-1552581234-26160f608093?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
        publishedAt: now.subtract(const Duration(days: 1)),
      ),
      AnnouncementModel(
        id: 'demo-6',
        title: 'Social: Coding Night & Pizza',
        content:
            'Unwind with peers at our casual coding night. Bring your laptop, collaborate, and enjoy pizza! 🍕',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.low,
        category: AnnouncementCategory.social,
        status: AnnouncementStatus.published,
        tags: const ['social', 'networking'],
        imageUrl:
            'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(hours: 10)),
        updatedAt: now.subtract(const Duration(hours: 10)),
        publishedAt: now.subtract(const Duration(hours: 10)),
      ),
      // Archived demo
      AnnouncementModel(
        id: 'demo-7',
        title: 'Archived: Last Year Hackathon Winners',
        content: 'Highlights and achievements from last year\'s hackathon event.',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.normal,
        category: AnnouncementCategory.events,
        status: AnnouncementStatus.archived,
        tags: const ['archive', 'highlights'],
        imageUrl:
            'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now.subtract(const Duration(days: 190)),
        publishedAt: now.subtract(const Duration(days: 200)),
      ),
      // Urgent demo
      AnnouncementModel(
        id: 'demo-8',
        title: 'Urgent: System Maintenance Tonight',
        content: 'Portal will be down from 11 PM to 1 AM for maintenance. Plan accordingly.',
        authorId: authorId,
        authorName: authorName,
        priority: AnnouncementPriority.urgent,
        category: AnnouncementCategory.administrative,
        status: AnnouncementStatus.published,
        tags: const ['urgent', 'maintenance'],
        imageUrl:
            'https://images.unsplash.com/photo-1518770660439-4636190af475?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
        publishedAt: now.subtract(const Duration(hours: 5)),
        isPinned: true,
      ),
    ];
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

  /// Get archived announcements
  static Future<List<AnnouncementModel>> getArchivedAnnouncements({
    int limit = 50,
    AnnouncementCategory? category,
  }) async {
    try {
      Query query = _firestore
          .collection('announcements')
          .where('status', isEqualTo: 'archived')
          .orderBy('updatedAt', descending: true);

      if (category != null) {
        query = query.where('category', isEqualTo: category.toString().split('.').last);
      }

      final querySnapshot = await query.limit(limit).get();
      return querySnapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting archived announcements: $e');
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
        imageUrl: 'https://images.unsplash.com/photo-1518779578993-ec3579fee39f?q=80&w=1600&auto=format&fit=crop',
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
        imageUrl: 'https://images.unsplash.com/photo-1551817958-20204d6ab464?q=80&w=1600&auto=format&fit=crop',
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
        imageUrl: 'https://images.unsplash.com/photo-1552581234-26160f608093?q=80&w=1600&auto=format&fit=crop',
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        publishedAt: now.subtract(const Duration(hours: 12)),
      ),
    ];
  }
}
