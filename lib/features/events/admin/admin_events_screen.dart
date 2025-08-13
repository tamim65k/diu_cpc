import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';
import 'admin_event_form_screen.dart';

class AdminEventsScreen extends StatelessWidget {
  const AdminEventsScreen({super.key});

  bool _isAdmin(User? user) {
    // TODO: Replace with real admin role check (e.g., custom claims or users collection role field)
    // For now treat any logged-in user as admin for demo purposes
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (!_isAdmin(user)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Events')),
        body: const Center(child: Text('Admin access required')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final created = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminEventFormScreen(),
                ),
              );
              if (created == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event created')),
                );
              }
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Pending'),
                Tab(text: 'Approved'),
                Tab(text: 'Cancelled'),
              ],
              labelColor: Colors.deepPurple,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _EventsList(filter: _Filter.pending),
                  _EventsList(filter: _Filter.approved),
                  _EventsList(filter: _Filter.cancelled),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Filter { pending, approved, cancelled }

class _EventsList extends StatelessWidget {
  final _Filter filter;
  const _EventsList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getAllEvents(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var events = snap.data ?? [];
        events = events.where((e) {
          final approval = (e.additionalInfo?['approvalStatus'] ?? 'approved') as String;
          switch (filter) {
            case _Filter.pending:
              return approval == 'pending';
            case _Filter.approved:
              return approval == 'approved' && e.status != EventStatus.cancelled;
            case _Filter.cancelled:
              return e.status == EventStatus.cancelled || approval == 'rejected';
          }
        }).toList();

        if (events.isEmpty) {
          return const Center(child: Text('No events'));
        }

        return ListView.separated(
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = events[i];
            final approval = (e.additionalInfo?['approvalStatus'] ?? 'approved') as String;
            return ListTile(
              title: Text(e.title),
              subtitle: Text('${e.categoryDisplayName} • ${e.getFormattedDate()}'),
              trailing: _AdminActions(event: e, approvalStatus: approval),
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminEventFormScreen(event: e),
                  ),
                );
                if (updated == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event updated')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class _AdminActions extends StatelessWidget {
  final EventModel event;
  final String approvalStatus;
  const _AdminActions({required this.event, required this.approvalStatus});

  @override
  Widget build(BuildContext context) {
    final isPending = approvalStatus == 'pending';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isPending) ...[
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green),
            tooltip: 'Approve',
            onPressed: () async {
              await EventService.approveEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event approved')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red),
            tooltip: 'Reject',
            onPressed: () async {
              await EventService.rejectEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event rejected')),
                );
              }
            },
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.cancel_schedule_send, color: Colors.orange),
            tooltip: 'Cancel',
            onPressed: () async {
              await EventService.cancelEvent(event.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Event cancelled')),
                );
              }
            },
          ),
        ],
      ],
    );
  }
}
