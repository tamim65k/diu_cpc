import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/user_model.dart';
import '../../../services/demo_user_data.dart';

class AdminMembersScreen extends StatelessWidget {
  const AdminMembersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Members'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'Suspended'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MembersList(filter: MembershipStatus.pending),
            _MembersList(filter: MembershipStatus.approved),
            _MembersList(filter: MembershipStatus.suspended),
            _MembersList(filter: MembershipStatus.rejected),
          ],
        ),
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  final MembershipStatus filter;
  const _MembersList({required this.filter});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('membershipStatus', isEqualTo: filter.toString().split('.').last)
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          // Demo fallback
          final demo = DemoUserData.byStatus(filter);
          if (demo.isEmpty) return const Center(child: Text('No members'));
          return ListView.separated(
            itemCount: demo.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final u = demo[i];
              final name = u.name;
              final email = u.email;
              final status = u.membershipStatus.toString().split('.').last;
              return ListTile(
                leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
                title: Text(name),
                subtitle: Text('$email • $status'),
                // No Firestore actions in demo mode
              );
            },
          );
        }

        return ListView.separated(
          itemCount: docs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final uid = docs[i].id;
            final name = data['name'] ?? data['fullName'] ?? 'Unnamed';
            final email = data['email'] ?? '';
            final status = data['membershipStatus'] ?? 'pending';
            final isApproved = data['isApproved'] == true;

            return ListTile(
              leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : '?')),
              title: Text(name),
              subtitle: Text('$email • ${status.toString()}'),
              trailing: _MemberActions(uid: uid, current: filter, isApproved: isApproved),
              onTap: () => _showMemberDetails(context, uid, data),
            );
          },
        );
      },
    );
  }

  void _showMemberDetails(BuildContext context, String uid, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? 'Member', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Email: ${data['email'] ?? ''}'),
                Text('Phone: ${data['phone'] ?? ''}'),
                Text('Department: ${data['department'] ?? ''}'),
                Text('Student ID: ${data['studentId'] ?? ''}'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'membershipStatus': 'approved',
                          'isApproved': true,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'membershipStatus': 'suspended',
                          'isApproved': false,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.pause_circle),
                      label: const Text('Suspend'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users').doc(uid).update({
                          'membershipStatus': 'rejected',
                          'isApproved': false,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberActions extends StatelessWidget {
  final String uid;
  final MembershipStatus current;
  final bool isApproved;
  const _MemberActions({required this.uid, required this.current, required this.isApproved});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 0,
      children: [
        if (current != MembershipStatus.approved)
          IconButton(
            tooltip: 'Approve',
            icon: const Icon(Icons.check_circle, color: Colors.green),
            onPressed: () => _update(context, 'approved', true),
          ),
        if (current != MembershipStatus.suspended)
          IconButton(
            tooltip: 'Suspend',
            icon: const Icon(Icons.pause_circle, color: Colors.orange),
            onPressed: () => _update(context, 'suspended', false),
          ),
        if (current != MembershipStatus.rejected)
          IconButton(
            tooltip: 'Reject',
            icon: const Icon(Icons.cancel, color: Colors.red),
            onPressed: () => _update(context, 'rejected', false),
          ),
      ],
    );
  }

  Future<void> _update(BuildContext context, String status, bool approved) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'membershipStatus': status,
      'isApproved': approved,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Member ${status.toLowerCase()}')),
      );
    }
  }
}
