import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';

class ContactService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Submit a contact form
  static Future<void> submitContactForm({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      
      final contactMessage = ContactModel(
        id: '', // Will be set by Firestore
        name: name,
        email: email,
        subject: subject,
        message: message,
        userId: user?.uid,
        status: ContactStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add to Firestore
      final docRef = await _firestore
          .collection('contact_messages')
          .add(contactMessage.toMap());

      // Update the document with its ID
      await docRef.update({'id': docRef.id});

      // Send auto-acknowledgment email (placeholder for now)
      await _sendAutoAcknowledgmentEmail(email, name, subject);
      
    } catch (e) {
      throw Exception('Failed to submit contact form: $e');
    }
  }

  /// Get contact messages (for admin use)
  static Stream<List<ContactModel>> getContactMessages({
    ContactStatus? status,
    int limit = 50,
  }) {
    Query query = _firestore
        .collection('contact_messages')
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.toString().split('.').last);
    }

    query = query.limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Update contact message status (for admin use)
  static Future<void> updateContactMessageStatus(
    String messageId,
    ContactStatus status,
  ) async {
    try {
      await _firestore
          .collection('contact_messages')
          .doc(messageId)
          .update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update contact message status: $e');
    }
  }

  /// Add admin response to contact message
  static Future<void> addAdminResponse(
    String messageId,
    String response,
  ) async {
    try {
      await _firestore
          .collection('contact_messages')
          .doc(messageId)
          .update({
        'adminResponse': response,
        'status': ContactStatus.resolved.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add admin response: $e');
    }
  }

  /// Get user's contact messages
  static Stream<List<ContactModel>> getUserContactMessages() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('contact_messages')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Send auto-acknowledgment email (placeholder implementation)
  /// In a real app, this would integrate with an email service like SendGrid, AWS SES, etc.
  static Future<void> _sendAutoAcknowledgmentEmail(
    String email,
    String name,
    String subject,
  ) async {
    // Placeholder for email service integration
    // For now, we'll just log the email details
    print('Auto-acknowledgment email sent to: $email');
    print('Subject: Thank you for contacting DIU CPC - $subject');
    print('Name: $name');
    
    // In a real implementation, you would:
    // 1. Use a cloud function to send emails
    // 2. Integrate with email services like SendGrid, AWS SES, etc.
    // 3. Use email templates for professional formatting
    
    // Example email content:
    final emailContent = '''
    Dear $name,
    
    Thank you for contacting DIU CPC. We have received your message regarding "$subject" and will get back to you within 24-48 hours.
    
    Your message is important to us, and our team will review it carefully.
    
    Best regards,
    DIU CPC Team
    ''';
    
    // Store email log in Firestore for tracking
    await _firestore.collection('email_logs').add({
      'to': email,
      'subject': 'Thank you for contacting DIU CPC - $subject',
      'content': emailContent,
      'type': 'auto_acknowledgment',
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'sent', // In real implementation, this would be updated based on actual send status
    });
  }

  /// Get contact statistics (for admin dashboard)
  static Future<Map<String, int>> getContactStatistics() async {
    try {
      final snapshot = await _firestore
          .collection('contact_messages')
          .get();

      int total = snapshot.docs.length;
      int pending = 0;
      int inProgress = 0;
      int resolved = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'];
        
        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'in_progress':
            inProgress++;
            break;
          case 'resolved':
            resolved++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'in_progress': inProgress,
        'resolved': resolved,
      };
    } catch (e) {
      throw Exception('Failed to get contact statistics: $e');
    }
  }
}
