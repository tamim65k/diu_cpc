import 'package:flutter/material.dart';
import '../../../models/user_model.dart';

class ProfileDetailsCard extends StatelessWidget {
  final UserModel user;
  const ProfileDetailsCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _detailRow('Name', user.name),
          _detailRow('Email', user.email),
          _detailRow('Phone', user.phone),
          _detailRow('Department', user.department),
          _detailRow('Academic Year', user.academicYear),
          _divider(),
          _detailRow('Student ID', user.studentId),
          _detailRow('Batch', user.batch),
          _detailRow('Blood Group', user.bloodGroup),
          _detailRow('Emergency Contact', user.emergencyContact),
          _detailRow('Address', user.address),
          if (user.bio.isNotEmpty) _detailRow('Bio', user.bio, maxLines: 3),
        ],
      ),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Divider(height: 1),
      );

  Widget _detailRow(String label, String value, {int maxLines = 1}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black87),
            ),
          )
        ],
      ),
    );
  }
}
