import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Pick an image from gallery or camera
  static Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Upload profile picture to Firebase Storage
  static Future<String?> uploadProfilePicture(XFile imageFile) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create a unique file name
      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      
      // Create reference to Firebase Storage
      final Reference ref = _storage.ref().child('profile_pictures').child(fileName);
      
      // Upload file
      final File file = File(imageFile.path);
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile picture: $e');
      return null;
    }
  }

  /// Delete old profile picture from Firebase Storage
  static Future<bool> deleteProfilePicture(String imageUrl) async {
    try {
      if (imageUrl.isEmpty || !imageUrl.contains('firebase')) {
        return true; // Nothing to delete
      }

      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting profile picture: $e');
      return false;
    }
  }

  /// Show image source selection dialog
  static Future<ImageSource?> showImageSourceDialog() async {
    // This will be implemented in the UI layer
    // Return null for now, will be handled by the calling widget
    return null;
  }

  /// Validate image file
  static bool isValidImage(XFile imageFile) {
    final String extension = path.extension(imageFile.path).toLowerCase();
    final List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    
    return allowedExtensions.contains(extension);
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(XFile file) async {
    final int bytes = await File(file.path).length();
    return bytes / (1024 * 1024);
  }

  /// Check if file size is within limit (5MB)
  static Future<bool> isFileSizeValid(XFile file) async {
    final double sizeInMB = await getFileSizeInMB(file);
    return sizeInMB <= 5.0;
  }
}
