import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';
import 'demo_event_data.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _eventsCollection = 'events';

  // Helper: return demo data (3 items) when stream errors or comes back empty
  static Stream<List<EventModel>> _withDemoOnEmptyOrError(
    Stream<List<EventModel>> base,
    List<EventModel> Function() demo,
  ) {
    return base.transform(
      StreamTransformer.fromHandlers(
        handleData: (events, sink) {
          if (events.isEmpty) {
            sink.add(demo().take(3).toList());
          } else {
            sink.add(events);
          }
        },
        handleError: (error, stackTrace, sink) {
          // On any Firestore error (e.g., missing index, rules), show demo content
          sink.add(demo().take(3).toList());
        },
      ),
    );
  }

  // Get all events
  static Stream<List<EventModel>> getAllEvents() {
    return _firestore
        .collection(_eventsCollection)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // For demo mode when not logged in or no registrations, return some upcoming demo as placeholder
  static Stream<List<EventModel>> getUserRegisteredEventsWithDemo() {
    final base = getUserRegisteredEvents();
    return _withDemoOnEmptyOrError(base, () => DemoEventData.upcoming());
  }

  // Get upcoming events
  static Stream<List<EventModel>> getUpcomingEvents() {
    return _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: 'upcoming')
        .where('startDateTime', isGreaterThan: Timestamp.now())
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Get upcoming events with demo fallback
  static Stream<List<EventModel>> getUpcomingEventsWithDemo() {
    return _withDemoOnEmptyOrError(getUpcomingEvents(), () => DemoEventData.upcoming());
  }

  // Get past events
  static Stream<List<EventModel>> getPastEvents() {
    return _firestore
        .collection(_eventsCollection)
        .where('status', isEqualTo: 'completed')
        .orderBy('startDateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Get past events with demo fallback
  static Stream<List<EventModel>> getPastEventsWithDemo() {
    return _withDemoOnEmptyOrError(getPastEvents(), () => DemoEventData.past());
  }

  // Get events by category
  static Stream<List<EventModel>> getEventsByCategory(EventCategory category) {
    return _firestore
        .collection(_eventsCollection)
        .where('category', isEqualTo: category.toString().split('.').last)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Get single event by ID
  static Future<EventModel?> getEventById(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();
      
      if (doc.exists) {
        return EventModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get event: $e');
    }
  }

  // Create new event (Admin only)
  static Future<String> createEvent(EventModel event) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create events');
      }

      // Check if user is admin (you can implement admin role checking here)
      // For now, we'll allow any authenticated user to create events
      
      final eventData = event.toFirestore();
      eventData['createdBy'] = user.uid;
      eventData['createdAt'] = Timestamp.now();
      eventData['updatedAt'] = Timestamp.now();

      final docRef = await _firestore
          .collection(_eventsCollection)
          .add(eventData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update event (Admin only)
  static Future<void> updateEvent(String eventId, EventModel updatedEvent) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to update events');
      }

      final eventData = updatedEvent.toFirestore();
      eventData['updatedAt'] = Timestamp.now();

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .update(eventData);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event (Admin only)
  static Future<void> deleteEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to delete events');
      }

      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Register for event
  static Future<bool> registerForEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to register for events');
      }

      return await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
        final eventDoc = await transaction.get(eventRef);
        
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final event = EventModel.fromFirestore(eventDoc);
        
        // Check if user is already registered
        if (event.registeredUsers.contains(user.uid)) {
          throw Exception('User already registered for this event');
        }

        // Check if event is full
        if (event.currentParticipants >= event.maxParticipants) {
          // Add to waitlist
          final updatedWaitlist = List<String>.from(event.waitlistUsers);
          if (!updatedWaitlist.contains(user.uid)) {
            updatedWaitlist.add(user.uid);
            transaction.update(eventRef, {'waitlistUsers': updatedWaitlist});
          }
          return false; // Added to waitlist, not registered
        }

        // Register user
        final updatedRegistered = List<String>.from(event.registeredUsers);
        updatedRegistered.add(user.uid);
        
        transaction.update(eventRef, {
          'registeredUsers': updatedRegistered,
          'currentParticipants': event.currentParticipants + 1,
        });

        return true; // Successfully registered
      });
    } catch (e) {
      throw Exception('Failed to register for event: $e');
    }
  }

  // Unregister from event
  static Future<void> unregisterFromEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to unregister from events');
      }

      await _firestore.runTransaction((transaction) async {
        final eventRef = _firestore.collection(_eventsCollection).doc(eventId);
        final eventDoc = await transaction.get(eventRef);
        
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final event = EventModel.fromFirestore(eventDoc);
        
        // Remove from registered users
        final updatedRegistered = List<String>.from(event.registeredUsers);
        updatedRegistered.remove(user.uid);
        
        // Remove from waitlist if present
        final updatedWaitlist = List<String>.from(event.waitlistUsers);
        updatedWaitlist.remove(user.uid);

        // If there's someone on waitlist and space available, move them to registered
        int newParticipantCount = event.currentParticipants;
        if (event.registeredUsers.contains(user.uid)) {
          newParticipantCount -= 1;
          
          if (updatedWaitlist.isNotEmpty && newParticipantCount < event.maxParticipants) {
            final nextUser = updatedWaitlist.removeAt(0);
            updatedRegistered.add(nextUser);
            newParticipantCount += 1;
          }
        }

        transaction.update(eventRef, {
          'registeredUsers': updatedRegistered,
          'waitlistUsers': updatedWaitlist,
          'currentParticipants': newParticipantCount,
        });
      });
    } catch (e) {
      throw Exception('Failed to unregister from event: $e');
    }
  }

  // Get user's registered events
  static Stream<List<EventModel>> getUserRegisteredEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_eventsCollection)
        .where('registeredUsers', arrayContains: user.uid)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Get user's waitlisted events
  static Stream<List<EventModel>> getUserWaitlistedEvents() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(_eventsCollection)
        .where('waitlistUsers', arrayContains: user.uid)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EventModel.fromFirestore(doc))
            .toList());
  }

  // Search events
  static Future<List<EventModel>> searchEvents(String query) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For better search, consider using Algolia or similar
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .where((event) =>
              event.title.toLowerCase().contains(query.toLowerCase()) ||
              event.description.toLowerCase().contains(query.toLowerCase()) ||
              event.organizerName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return events;
    } catch (e) {
      throw Exception('Failed to search events: $e');
    }
  }

  // Update event status (for automated status updates)
  static Future<void> updateEventStatus(String eventId, EventStatus newStatus) async {
    try {
      await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .update({
        'status': newStatus.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update event status: $e');
    }
  }

  // Admin: approve event
  static Future<void> approveEvent(String eventId) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'status': 'upcoming',
        'updatedAt': Timestamp.now(),
        'additionalInfo.approvalStatus': 'approved',
      });
    } catch (e) {
      throw Exception('Failed to approve event: $e');
    }
  }

  // Admin: reject event
  static Future<void> rejectEvent(String eventId, {String? reason}) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
        'additionalInfo.approvalStatus': 'rejected',
        if (reason != null) 'additionalInfo.rejectionReason': reason,
      });
    } catch (e) {
      throw Exception('Failed to reject event: $e');
    }
  }

  // Admin: cancel event
  static Future<void> cancelEvent(String eventId, {String? reason}) async {
    try {
      await _firestore.collection(_eventsCollection).doc(eventId).update({
        'status': 'cancelled',
        'updatedAt': Timestamp.now(),
        if (reason != null) 'additionalInfo.cancellationReason': reason,
      });
    } catch (e) {
      throw Exception('Failed to cancel event: $e');
    }
  }

  // Get events count by status
  static Future<Map<EventStatus, int>> getEventsCountByStatus() async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .get();

      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc))
          .toList();

      final counts = <EventStatus, int>{};
      for (final status in EventStatus.values) {
        counts[status] = events.where((event) => event.status == status).length;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get events count: $e');
    }
  }
}
