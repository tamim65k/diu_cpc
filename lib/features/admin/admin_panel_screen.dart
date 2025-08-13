import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../events/admin/admin_events_screen.dart';
import '../announcements/admin/admin_announcement_form_screen.dart';
import 'members/admin_members_screen.dart';
import 'announcements/admin_announcements_screen.dart';
import 'analytics/admin_analytics_screen.dart';
import '../../services/demo_event_data.dart';
import '../../services/announcement_service.dart';
import '../../services/demo_user_data.dart';
import 'admin_login_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _index = 0;

  final _pages = [
    const _AdminDashboard(),
    const AdminMembersScreen(),
    const AdminEventsScreen(),
    const AdminAnnouncementsScreen(),
    const AdminAnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            tooltip: 'New announcement',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAnnouncementFormScreen()),
              );
            },
            icon: const Icon(Icons.campaign_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Members'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.campaign_outlined), label: 'Announcements'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Analytics'),
        ],
      ),
    );
  }
}

class _AdminDashboard extends StatelessWidget {
  const _AdminDashboard();

  @override
  Widget build(BuildContext context) {
    // Simple placeholder dashboard with quick links
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: const [
            _StatCard(title: 'Members', icon: Icons.group, collection: 'users'),
            _StatCard(title: 'Events', icon: Icons.event, collection: 'events'),
            _StatCard(title: 'Announcements', icon: Icons.campaign, collection: 'announcements'),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminMembersScreen()),
              ),
              icon: const Icon(Icons.group),
              label: const Text('Manage Members'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminEventsScreen()),
              ),
              icon: const Icon(Icons.event),
              label: const Text('Manage Events'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminAnnouncementsScreen()),
              ),
              icon: const Icon(Icons.campaign),
              label: const Text('Manage Announcements'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String collection;
  const _StatCard({required this.title, required this.icon, required this.collection});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 120,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<int>(
            stream: _countStream(collection),
            builder: (context, snapshot) {
              final count = snapshot.data;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(icon, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(
                          count == null ? '—' : count.toString(),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Stream<int> _countStream(String col) async* {
    // Lightweight approximate counter using snapshots length
    try {
      final snapshots = FirebaseFirestore.instance.collection(col).snapshots();
      await for (final snap in snapshots) {
        final live = snap.docs.length;
        if (live > 0) {
          yield live;
        } else {
          // Demo fallback counts
          yield _demoCount(col);
        }
      }
    } catch (_) {
      // On any error, show demo counts
      yield _demoCount(col);
    }
  }

  int _demoCount(String col) {
    switch (col) {
      case 'users':
        return DemoUserData.all().length;
      case 'events':
        return DemoEventData.upcoming().length + DemoEventData.past().length;
      case 'announcements':
        return AnnouncementService.getDemoAnnouncements().length;
      default:
        return 0;
    }
  }
}
