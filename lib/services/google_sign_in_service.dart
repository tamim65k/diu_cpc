import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class GoogleSignInService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // TODO: Replace with your actual web client ID from Firebase Console
    // Go to Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration
    clientId: '741543342347-n09scgfcvut6sf6tdc90d8189835jof9.apps.googleusercontent.com',
  );

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Check if user document exists in Firestore, create if it doesn't
      if (userCredential.user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (!userDoc.exists) {
          // Create user document for new Google Sign-In users
          final newUser = UserModel(
            uid: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email ?? '',
            phone: '',
            department: '',
            academicYear: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isEmailVerified: userCredential.user!.emailVerified,
            membershipStatus: MembershipStatus.pending,
            profileImageUrl: userCredential.user!.photoURL,
          );
          
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set(newUser.toFirestore());
        }
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
