import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/announcement_model.dart';
import '../../announcements/admin/admin_announcement_form_screen.dart';
import '../../../services/announcement_service.dart';

class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Announcements'),
          actions: [
            IconButton(
              tooltip: 'New Announcement',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnnouncementFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Drafts'),
              Tab(text: 'Published'),
              Tab(text: 'Archived'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AnnouncementsList(status: AnnouncementStatus.draft),
            _AnnouncementsList(status: AnnouncementStatus.published),
            _AnnouncementsList(status: AnnouncementStatus.archived),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsList extends StatelessWidget {
  final AnnouncementStatus status;
  const _AnnouncementsList({required this.status});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('announcements')
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy(status == AnnouncementStatus.published ? 'publishedAt' : 'updatedAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          // Demo fallback filtered by status
          final demo = AnnouncementService.getDemoAnnouncements().where((a) => a.status == status).toList();
          if (demo.isEmpty) return const Center(child: Text('No announcements'));
          return ListView.separated(
            itemCount: demo.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final a = demo[i];
              final title = a.title;
              final isPinned = a.isPinned;
              final subtitle = '${a.getCategoryDisplayName()} • ${a.getPriorityDisplayName()}';
              return ListTile(
                title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(subtitle),
                // No Firestore actions in demo mode
                trailing: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminAnnouncementFormScreen(),
                    ),
                  );
                },
              );
            },
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final id = docs[i].id;
            final title = data['title'] ?? 'Untitled';
            final isPinned = data['isPinned'] == true;
            final subtitle = _subtitleText(data);
            return ListTile(
              title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(subtitle),
              trailing: _AnnouncementActions(id: id, data: data, status: status, isPinned: isPinned),
              onTap: () async {
                // Open create form (current form does not support editing existing announcement)
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminAnnouncementFormScreen(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  String _subtitleText(Map<String, dynamic> data) {
    final category = data['category'] ?? 'general';
    final priority = data['priority'] ?? 'normal';
    final updated = (data['updatedAt'] as Timestamp?)?.toDate();
    final dateStr = updated != null ? '${updated.year}-${updated.month}-${updated.day}' : '';
    return '${category.toString()} • ${priority.toString()}${dateStr.isNotEmpty ? ' • $dateStr' : ''}';
  }
}

class _AnnouncementActions extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final AnnouncementStatus status;
  final bool isPinned;
  const _AnnouncementActions({required this.id, required this.data, required this.status, required this.isPinned});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: isPinned ? 'Unpin' : 'Pin',
          icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('announcements').doc(id).update({
              'isPinned': !isPinned,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          },
        ),
        if (status != AnnouncementStatus.published)
          IconButton(
            tooltip: 'Publish',
            icon: const Icon(Icons.publish),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('announcements').doc(id).update({
                'status': 'published',
                'publishedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published')));
              }
            },
          ),
        if (status == AnnouncementStatus.published)
          IconButton(
            tooltip: 'Archive',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('announcements').doc(id).update({
                'status': 'archived',
                'updatedAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archived')));
              }
            },
          ),
        IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Delete Announcement?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                ],
              ),
            );
            if (confirm != true) return;
            await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
            }
          },
        ),
      ],
    );
  }
}
