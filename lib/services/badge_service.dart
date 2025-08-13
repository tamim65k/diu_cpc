import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';

class BadgeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all available badges
  static Future<List<BadgeModel>> getAllBadges() async {
    try {
      final querySnapshot = await _firestore
          .collection('badges')
          .where('isActive', isEqualTo: true)
          .orderBy('category')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BadgeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all badges: $e');
      return [];
    }
  }

  /// Get user's earned badges
  static Future<List<UserBadgeModel>> getUserBadges(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .orderBy('earnedAt', descending: true)
          .get();

      List<UserBadgeModel> userBadges = querySnapshot.docs
          .map((doc) => UserBadgeModel.fromFirestore(doc))
          .toList();

      // Get badge details for each user badge
      List<UserBadgeModel> badgesWithDetails = [];
      for (UserBadgeModel userBadge in userBadges) {
        try {
          final badgeDoc = await _firestore
              .collection('badges')
              .doc(userBadge.badgeId)
              .get();
          
          if (badgeDoc.exists) {
            final badge = BadgeModel.fromFirestore(badgeDoc);
            badgesWithDetails.add(userBadge.copyWithBadge(badge));
          }
        } catch (e) {
          print('Error getting badge details for ${userBadge.badgeId}: $e');
          badgesWithDetails.add(userBadge); // Add without badge details
        }
      }

      return badgesWithDetails;
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  /// Award a badge to a user
  static Future<bool> awardBadge(String userId, String badgeId, {Map<String, dynamic>? metadata}) async {
    try {
      // Check if user already has this badge
      final existingBadge = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .get();

      if (existingBadge.docs.isNotEmpty) {
        print('User already has this badge');
        return false;
      }

      // Award the badge
      final userBadge = UserBadgeModel(
        id: '', // Will be set by Firestore
        userId: userId,
        badgeId: badgeId,
        earnedAt: DateTime.now(),
        metadata: metadata ?? {},
      );

      await _firestore.collection('user_badges').add(userBadge.toFirestore());
      return true;
    } catch (e) {
      print('Error awarding badge: $e');
      return false;
    }
  }

  /// Get user's badge statistics
  static Future<Map<String, int>> getUserBadgeStats(String userId) async {
    try {
      final userBadges = await getUserBadges(userId);
      
      Map<String, int> stats = {
        'total': userBadges.length,
        'events': 0,
        'programming': 0,
        'leadership': 0,
        'community': 0,
        'special': 0,
        'totalPoints': 0,
      };

      for (UserBadgeModel userBadge in userBadges) {
        if (userBadge.badge != null) {
          final category = userBadge.badge!.category.toString().split('.').last;
          stats[category] = (stats[category] ?? 0) + 1;
          stats['totalPoints'] = (stats['totalPoints'] ?? 0) + userBadge.badge!.points;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting user badge stats: $e');
      return {'total': 0, 'totalPoints': 0};
    }
  }

  /// Check and award automatic badges based on user activity
  static Future<void> checkAndAwardAutomaticBadges(String userId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData = UserModel.fromFirestore(userDoc);
      
      // Check for membership badges
      await _checkMembershipBadges(userId, userData);
      
      // Check for participation badges
      await _checkParticipationBadges(userId);
      
      // Check for achievement badges
      await _checkAchievementBadges(userId);
      
    } catch (e) {
      print('Error checking automatic badges: $e');
    }
  }

  /// Check and award membership-related badges
  static Future<void> _checkMembershipBadges(String userId, UserModel userData) async {
    try {
      // New Member Badge
      if (userData.membershipStatus == MembershipStatus.approved) {
        await _awardBadgeIfNotExists(userId, 'new_member');
      }

      // Profile Complete Badge
      if (_isProfileComplete(userData)) {
        await _awardBadgeIfNotExists(userId, 'profile_complete');
      }
    } catch (e) {
      print('Error checking membership badges: $e');
    }
  }

  /// Check and award participation-related badges
  static Future<void> _checkParticipationBadges(String userId) async {
    try {
      // Get user's event registrations
      final eventRegistrations = await _firestore
          .collection('event_registrations')
          .where('userId', isEqualTo: userId)
          .get();

      final registrationCount = eventRegistrations.docs.length;

      // First Event Badge
      if (registrationCount >= 1) {
        await _awardBadgeIfNotExists(userId, 'first_event');
      }

      // Event Enthusiast Badge (5 events)
      if (registrationCount >= 5) {
        await _awardBadgeIfNotExists(userId, 'event_enthusiast');
      }

      // Event Champion Badge (10 events)
      if (registrationCount >= 10) {
        await _awardBadgeIfNotExists(userId, 'event_champion');
      }
    } catch (e) {
      print('Error checking participation badges: $e');
    }
  }

  /// Check and award achievement-related badges
  static Future<void> _checkAchievementBadges(String userId) async {
    try {
      final currentBadges = await getUserBadges(userId);
      final badgeCount = currentBadges.length;

      // Badge Collector (5 badges)
      if (badgeCount >= 5) {
        await _awardBadgeIfNotExists(userId, 'badge_collector');
      }

      // Badge Master (10 badges)
      if (badgeCount >= 10) {
        await _awardBadgeIfNotExists(userId, 'badge_master');
      }
    } catch (e) {
      print('Error checking achievement badges: $e');
    }
  }

  /// Award badge if user doesn't already have it
  static Future<void> _awardBadgeIfNotExists(String userId, String badgeId) async {
    try {
      final existingBadge = await _firestore
          .collection('user_badges')
          .where('userId', isEqualTo: userId)
          .where('badgeId', isEqualTo: badgeId)
          .get();

      if (existingBadge.docs.isEmpty) {
        await awardBadge(userId, badgeId);
      }
    } catch (e) {
      print('Error awarding badge $badgeId: $e');
    }
  }

  /// Check if user profile is complete
  static bool _isProfileComplete(UserModel userData) {
    return userData.name.isNotEmpty &&
           userData.phone.isNotEmpty &&
           userData.department.isNotEmpty &&
           userData.academicYear.isNotEmpty;
  }

  /// Get badges by category
  static Future<List<BadgeModel>> getBadgesByCategory(BadgeCategory category) async {
    try {
      final querySnapshot = await _firestore
          .collection('badges')
          .where('category', isEqualTo: category.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => BadgeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting badges by category: $e');
      return [];
    }
  }

  /// Initialize default badges (call this once to set up the badge system)
  static Future<void> initializeDefaultBadges() async {
    try {
      final defaultBadges = _getDefaultBadges();
      
      for (BadgeModel badge in defaultBadges) {
        // Check if badge already exists
        final existingBadge = await _firestore
            .collection('badges')
            .doc(badge.id)
            .get();
        
        if (!existingBadge.exists) {
          await _firestore
              .collection('badges')
              .doc(badge.id)
              .set(badge.toFirestore());
        }
      }
    } catch (e) {
      print('Error initializing default badges: $e');
    }
  }

  /// Get default badges for the system
  static List<BadgeModel> _getDefaultBadges() {
    return [
      // Membership Badges
      BadgeModel(
        id: 'new_member',
        name: 'New Member',
        description: 'Welcome to DIU CPC! Your membership has been approved.',
        iconUrl: '🎉',
        type: BadgeType.membership,
        category: BadgeCategory.community,
        points: 10,
        color: '#4CAF50',
      ),
      BadgeModel(
        id: 'profile_complete',
        name: 'Profile Complete',
        description: 'Completed your profile with all required information.',
        iconUrl: '✅',
        type: BadgeType.achievement,
        category: BadgeCategory.community,
        points: 5,
        color: '#2196F3',
      ),
      
      // Event Participation Badges
      BadgeModel(
        id: 'first_event',
        name: 'First Event',
        description: 'Registered for your first DIU CPC event.',
        iconUrl: '🎯',
        type: BadgeType.participation,
        category: BadgeCategory.events,
        points: 15,
        color: '#FF9800',
      ),
      BadgeModel(
        id: 'event_enthusiast',
        name: 'Event Enthusiast',
        description: 'Registered for 5 or more events.',
        iconUrl: '🔥',
        type: BadgeType.participation,
        category: BadgeCategory.events,
        points: 25,
        color: '#F44336',
      ),
      BadgeModel(
        id: 'event_champion',
        name: 'Event Champion',
        description: 'Registered for 10 or more events.',
        iconUrl: '🏆',
        type: BadgeType.achievement,
        category: BadgeCategory.events,
        points: 50,
        color: '#FFD700',
      ),
      
      // Badge Collection Achievements
      BadgeModel(
        id: 'badge_collector',
        name: 'Badge Collector',
        description: 'Earned 5 different badges.',
        iconUrl: '🎖️',
        type: BadgeType.achievement,
        category: BadgeCategory.special,
        points: 30,
        color: '#9C27B0',
      ),
      BadgeModel(
        id: 'badge_master',
        name: 'Badge Master',
        description: 'Earned 10 different badges.',
        iconUrl: '👑',
        type: BadgeType.achievement,
        category: BadgeCategory.special,
        points: 75,
        color: '#E91E63',
      ),
    ];
  }
}
