import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's profile data from Firestore
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromFirestore(userDoc);
      }
      
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  /// Toggle announcement notification preference
  static Future<bool> updateAnnouncementNotifications(String uid, bool enabled) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'announcementNotificationsEnabled': enabled,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating announcement notifications: $e');
      return false;
    }
  }

  /// Create or update user profile in Firestore
  static Future<bool> saveUserProfile(UserModel userModel) async {
    try {
      await _firestore
          .collection('users')
          .doc(userModel.uid)
          .set(userModel.toFirestore(), SetOptions(merge: true));
      
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  /// Update specific user profile fields
  static Future<bool> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      
      await _firestore
          .collection('users')
          .doc(uid)
          .update(updates);
      
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Create a basic user profile for new users
  static Future<UserModel?> createBasicProfile(User firebaseUser) async {
    try {
      final basicUser = UserModel(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
        email: firebaseUser.email ?? '',
        phone: '',
        department: '',
        academicYear: '',
        studentId: '',
        batch: '',
        bloodGroup: '',
        emergencyContact: '',
        address: '',
        bio: '',
        dateOfBirth: null,
        socialLinks: const {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        membershipStatus: MembershipStatus.pending,
        profileImageUrl: firebaseUser.photoURL,
      );

      final success = await saveUserProfile(basicUser);
      return success ? basicUser : null;
    } catch (e) {
      print('Error creating basic profile: $e');
      return null;
    }
  }

  /// Update user profile picture URL
  static Future<bool> updateProfilePicture(String uid, String profileImageUrl) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'profileImageUrl': profileImageUrl,
        'updatedAt': Timestamp.now(),
      });
      return true;
    } catch (e) {
      print('Error updating profile picture: $e');
      return false;
    }
  }

  /// Get user profile stream for real-time updates
  static Stream<UserModel?> getUserProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists && doc.data() != null) {
            return UserModel.fromFirestore(doc);
          }
          return null;
        });
  }
}
