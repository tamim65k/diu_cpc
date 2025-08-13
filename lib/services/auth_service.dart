import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      // Create user account
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send email verification
      await result.user?.sendEmailVerification();

      // Save user data to Firestore
      await _firestore.collection('users').doc(result.user!.uid).set(
        userModel.copyWith(id: result.user!.uid).toMap(),
      );

      return result;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Failed to resend verification email: ${e.toString()}');
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  // Update user data in Firestore
  Future<void> updateUserData(UserModel userModel) async {
    try {
      await _firestore.collection('users').doc(userModel.id).update(userModel.toMap());
    } catch (e) {
      throw Exception('Failed to update user data: ${e.toString()}');
    }
  }

  // Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Account lockout tracking (simple implementation)
  static const int maxFailedAttempts = 5;
  static const int lockoutDurationMinutes = 30;

  Future<bool> isAccountLocked(String email) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('account_security')
          .doc(email.replaceAll('.', '_'))
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        int failedAttempts = data['failedAttempts'] ?? 0;
        DateTime? lastFailedAttempt = data['lastFailedAttempt']?.toDate();

        if (failedAttempts >= maxFailedAttempts && lastFailedAttempt != null) {
          DateTime unlockTime = lastFailedAttempt.add(
            Duration(minutes: lockoutDurationMinutes),
          );
          return DateTime.now().isBefore(unlockTime);
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> recordFailedAttempt(String email) async {
    try {
      String docId = email.replaceAll('.', '_');
      DocumentReference doc = _firestore.collection('account_security').doc(docId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(doc);
        
        if (snapshot.exists) {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          int currentAttempts = data['failedAttempts'] ?? 0;
          
          transaction.update(doc, {
            'failedAttempts': currentAttempts + 1,
            'lastFailedAttempt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(doc, {
            'email': email,
            'failedAttempts': 1,
            'lastFailedAttempt': FieldValue.serverTimestamp(),
          });
        }
      });
    } catch (e) {
      // Silently fail for security tracking
    }
  }

  Future<void> clearFailedAttempts(String email) async {
    try {
      String docId = email.replaceAll('.', '_');
      await _firestore.collection('account_security').doc(docId).delete();
    } catch (e) {
      // Silently fail for security tracking
    }
  }
}
