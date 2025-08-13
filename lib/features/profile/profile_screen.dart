import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../services/google_sign_in_service.dart';
import '../../services/image_upload_service.dart';
import 'edit_profile_screen.dart';

// Removed old Sliver TabBar header and tabbed UI

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to view your profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try to get existing user profile
      UserModel? userProfile = await UserService.getCurrentUserProfile();
      
      if (userProfile != null) {
        setState(() {
          _currentUser = userProfile;
        });
        setState(() {
          _isLoading = false;
        });
      } else {
        // Create a basic user profile if it doesn't exist
        userProfile = await UserService.createBasicProfile(user);
        
        if (userProfile != null) {
          setState(() {
            _currentUser = userProfile;
            _isLoading = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile created. Please complete your profile information.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } else {
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create user profile. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      print('Profile loading error: $e'); // Debug logging
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              } else if (value == 'edit') {
                _navigateToEditProfile();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('Edit Info'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 16),
                      _buildInfoSection(),
                      const SizedBox(height: 16),
                      _buildUpcomingDemoSection(),
                      const SizedBox(height: 16),
                      _buildHistoryDemoSection(),
                      const SizedBox(height: 16),
                      _buildRolesSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load profile',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  Widget _buildProfileCard() {
    final user = _currentUser!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple.shade50,
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: (user.profileImageUrl == null || user.profileImageUrl!.isEmpty)
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _uploadProfilePicture,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.name,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _membershipChip(user.membershipStatus),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(user.email, style: TextStyle(color: Colors.grey[700])),
                  if (user.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(user.phone, style: TextStyle(color: Colors.grey[700])),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _navigateToEditProfile,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Info'),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _membershipChip(MembershipStatus status) {
    Color color;
    String text;
    switch (status) {
      case MembershipStatus.approved:
        color = Colors.green;
        text = 'Approved';
        break;
      case MembershipStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case MembershipStatus.suspended:
        color = Colors.orange;
        text = 'Suspended';
        break;
      case MembershipStatus.pending:
        color = Colors.blueGrey;
        text = 'Pending';
        break;
    }
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final user = _currentUser!;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Profile Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _infoRow(Icons.school, 'Department', user.department.isNotEmpty ? user.department : 'Not set'),
            _infoRow(Icons.badge, 'Student ID', user.studentId.isNotEmpty ? user.studentId : 'Not set'),
            _infoRow(Icons.class_, 'Batch', user.batch.isNotEmpty ? user.batch : 'Not set'),
            _infoRow(Icons.timeline, 'Academic Year', user.academicYear.isNotEmpty ? user.academicYear : 'Not set'),
            _infoRow(Icons.bloodtype, 'Blood Group', user.bloodGroup.isNotEmpty ? user.bloodGroup : 'Not set'),
            _infoRow(Icons.phone, 'Emergency Contact', user.emergencyContact.isNotEmpty ? user.emergencyContact : 'Not set'),
            _infoRow(Icons.location_on, 'Address', user.address.isNotEmpty ? user.address : 'Not set'),
            if (user.bio.isNotEmpty) _infoRow(Icons.info_outline, 'Bio', user.bio),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDemoSection() {
    return _demoListSection(
      title: 'Upcoming Registrations',
      icon: Icons.event_available,
      items: const [
        ('Code Sprint 2025', 'Aug 20, 2025 • 10:00 AM'),
        ('Flutter Workshop', 'Aug 25, 2025 • 2:00 PM'),
        ('AI Meetup', 'Sep 1, 2025 • 5:00 PM'),
      ],
      primary: true,
    );
  }

  Widget _buildHistoryDemoSection() {
    return _demoListSection(
      title: 'Event Participation History',
      icon: Icons.history,
      items: const [
        ('Hackathon 2025', 'Participated • Jul 10, 2025'),
        ('DSA Contest', 'Completed • Jun 18, 2025'),
        ('Tech Talk', 'Attended • May 30, 2025'),
      ],
      primary: false,
    );
  }

  Widget _demoListSection({
    required String title,
    required IconData icon,
    required List<(String, String)> items,
    required bool primary,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: primary ? Colors.deepPurple : Colors.grey[700]),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: primary ? Colors.deepPurple : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(e.$2, style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRolesSection() {
    final status = _currentUser!.membershipStatus;
    final isApproved = status == MembershipStatus.approved;
    final roles = <String>[
      isApproved ? 'Regular Member' : 'Pending Member',
      if (_currentUser!.isApproved) 'Verified',
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Badges & Roles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: roles
                  .map((r) => Chip(
                        label: Text(r),
                        avatar: const Icon(Icons.workspace_premium, size: 18),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_currentUser == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(user: _currentUser!),
      ),
    ).then((_) => _loadUserData());
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final image = await ImageUploadService.pickImage();
      if (image == null) return;

      if (!ImageUploadService.isValidImage(image)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a JPG/PNG/WebP image.')),
        );
        return;
      }

      final sizeOk = await ImageUploadService.isFileSizeValid(image);
      if (!sizeOk) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is larger than 5MB. Please choose a smaller file.')),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading profile picture...')),
      );

      final downloadUrl = await ImageUploadService.uploadProfilePicture(image);
      if (downloadUrl == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ok = await UserService.updateProfilePicture(uid, downloadUrl);
      if (ok) {
        setState(() {
          _currentUser = _currentUser!.copyWith(profileImageUrl: downloadUrl);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image URL.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }


  Future<void> _signOut() async {
    try {
      await GoogleSignInService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }
}
