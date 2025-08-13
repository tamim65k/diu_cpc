import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/demo_user_data.dart';
import '../../../services/demo_event_data.dart';
import '../../../services/announcement_service.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Analytics'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AnalyticsTile(
            title: 'Active Members',
            collection: 'users',
            whereField: 'membershipStatus',
            whereEquals: 'approved',
          ),
          _AnalyticsTile(
            title: 'Upcoming Events',
            collection: 'events',
            whereField: 'date',
            whereGreaterThanNow: true,
          ),
          _AnalyticsTile(
            title: 'Published Announcements',
            collection: 'announcements',
            whereField: 'status',
            whereEquals: 'published',
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String title;
  final String collection;
  final String? whereField;
  final String? whereEquals;
  final bool whereGreaterThanNow;

  const _AnalyticsTile({
    required this.title,
    required this.collection,
    this.whereField,
    this.whereEquals,
    this.whereGreaterThanNow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<int>(
          stream: _countStream(),
          builder: (context, snapshot) {
            final value = snapshot.data;
            return Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                Text(
                  value == null ? '—' : value.toString(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Stream<int> _countStream() async* {
    Query query = FirebaseFirestore.instance.collection(collection);
    if (whereField != null) {
      if (whereGreaterThanNow) {
        query = query.where(whereField!, isGreaterThan: Timestamp.now());
      } else if (whereEquals != null) {
        query = query.where(whereField!, isEqualTo: whereEquals);
      }
    }
    try {
      final snapshots = query.snapshots();
      await for (final snap in snapshots) {
        final live = snap.docs.length;
        if (live > 0) {
          yield live;
        } else {
          yield _demoCount();
        }
      }
    } catch (_) {
      yield _demoCount();
    }
  }

  int _demoCount() {
    // Map known tiles to demo counts based on provided filters
    if (collection == 'users' && whereField == 'membershipStatus' && whereEquals == 'approved') {
      return DemoUserData.countApproved();
    }
    if (collection == 'events' && whereGreaterThanNow) {
      // Upcoming events
      return DemoEventData.upcoming().length;
    }
    if (collection == 'announcements' && whereField == 'status' && whereEquals == 'published') {
      return AnnouncementService.getDemoAnnouncements().where((a) => a.status.toString().split('.').last == 'published').length;
    }
    // Default combined demo size when no specific mapping exists
    return 0;
  }
}
