import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/badge_model.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../services/badge_service.dart';
import '../../services/google_sign_in_service.dart';
import '../../widgets/badge_widgets.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_stats_card.dart';
import 'widgets/event_history_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserModel? _currentUser;
  bool _isLoading = true;
  List<UserBadgeModel> _userBadges = [];
  Map<String, int> _badgeStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        
        // Load user badges and stats
        await _loadUserBadges(user.uid);
        
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

  Future<void> _loadUserBadges(String userId) async {
    try {
      // Check and award automatic badges
      await BadgeService.checkAndAwardAutomaticBadges(userId);
      
      // Load user badges
      final badges = await BadgeService.getUserBadges(userId);
      final stats = await BadgeService.getUserBadgeStats(userId);
      
      setState(() {
        _userBadges = badges;
        _badgeStats = stats;
      });
    } catch (e) {
      print('Error loading user badges: $e');
      // Don't show error to user as badges are not critical
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditProfile(),
            tooltip: 'Edit Profile',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (context) => [
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
              : Column(
                  children: [
                    ProfileHeader(user: _currentUser!),
                    const SizedBox(height: 16),
                    ProfileStatsCard(userId: _currentUser!.uid),
                    const SizedBox(height: 16),
                    _buildTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildUpcomingEvents(),
                          _buildEventHistory(),
                          _buildAchievements(),
                        ],
                      ),
                    ),
                  ],
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.deepPurple,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Upcoming'),
          Tab(text: 'History'),
          Tab(text: 'Achievements'),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getUserRegisteredEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading events',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final upcomingEvents = (snapshot.data ?? [])
            .where((event) => event.isUpcoming)
            .toList();

        if (upcomingEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No upcoming events',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Register for events to see them here!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: upcomingEvents.length,
          itemBuilder: (context, index) {
            final event = upcomingEvents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventHistoryCard(
                event: event,
                showStatus: false,
                showCountdown: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEventHistory() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getUserRegisteredEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading event history',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final pastEvents = (snapshot.data ?? [])
            .where((event) => event.isCompleted)
            .toList();

        if (pastEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No event history',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your completed events will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: pastEvents.length,
          itemBuilder: (context, index) {
            final event = pastEvents[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: EventHistoryCard(
                event: event,
                showStatus: true,
                showCountdown: false,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Membership Status Badge
          if (_currentUser != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MembershipStatusBadge(
                  status: _currentUser!.membershipStatus,
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          
          // Badge Statistics
          if (_badgeStats.isNotEmpty) ...[
            BadgeStatsCard(stats: _badgeStats),
            const SizedBox(height: 20),
          ],
          
          // Badges Section
          const Text(
            'Your Badges',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // User Badges Display
          if (_userBadges.isNotEmpty)
            Expanded(
              child: BadgeGrid(
                badges: _userBadges,
                maxDisplay: 20, // Show more badges in profile
                showDetails: true,
                onBadgeTap: (userBadge) {
                  showDialog(
                    context: context,
                    builder: (context) => BadgeDetailsDialog(userBadge: userBadge),
                  );
                },
              ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No badges earned yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete your profile and participate in events to earn badges!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(
    String title,
    String description,
    IconData icon,
    Color color,
    {bool isEarned = false}
  ) {
    return Card(
      elevation: isEarned ? 4 : 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isEarned ? color.withOpacity(0.1) : Colors.grey[50],
          border: Border.all(
            color: isEarned ? color.withOpacity(0.3) : Colors.grey[300]!,
            width: isEarned ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isEarned ? color : Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isEarned ? color : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isEarned ? Colors.grey[700] : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (isEarned) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Earned',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditProfileScreen(user: _currentUser!),
        ),
      ).then((updated) {
        if (updated == true) {
          _loadUserData(); // Reload user data if profile was updated
        }
      });
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
