import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'models/event_model.dart';
import 'services/event_service.dart';
import 'services/user_service.dart';
import 'services/google_sign_in_service.dart';
import 'services/demo_event_data.dart';
import 'features/events/events_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/announcements/announcements_screen.dart';
import 'features/contact/contact_screen.dart';
import 'widgets/gradient_background.dart';
import 'theme/app_colors.dart';
import 'models/event_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  List<EventModel> _upcomingEvents = [];
  bool _isLoading = true;
  // Carousel state
  final PageController _carouselCtrl = PageController(viewportFraction: 1.0);
  int _carouselIndex = 0;
  Timer? _carouselTimer;
  List<EventModel> _carouselEvents = [];
  // Feature flag to show/hide hero carousel
  final bool _enableHeroCarousel = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Prepare demo images for hero carousel (3 upcoming demo images)
    final demo = DemoEventData.upcoming().take(3).toList();
    _carouselEvents = demo;
    // Ensure PageView is mounted before starting (disabled when hidden)
    if (_enableHeroCarousel) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startCarousel());
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    if (_carouselEvents.isEmpty) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _carouselEvents.isEmpty) return;
      if (!_carouselCtrl.hasClients) return;
      _carouselIndex = (_carouselIndex + 1) % _carouselEvents.length;
      _carouselCtrl.animateToPage(
        _carouselIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _carouselCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load user data
      _currentUser = await UserService.getCurrentUserProfile();
      
      // Try to load events, but handle permission errors gracefully
      try {
        EventService.getUpcomingEventsWithDemo().take(1).listen(
          (events) {
            if (mounted) {
              // For homepage upcoming section, use demo events only
              final demo = DemoEventData.upcoming().take(5).toList();
              setState(() {
                _upcomingEvents = demo;
                _isLoading = false;
              });
            }
          },
          onError: (error) {
            print('Events loading error (permission denied): $error');
            if (mounted) {
              final demo = DemoEventData.upcoming();
              setState(() {
                _upcomingEvents = demo.take(3).toList();
                _isLoading = false;
              });
            }
          },
        );
      } catch (e) {
        print('Events stream error: $e');
        setState(() {
          _upcomingEvents = []; // Empty list if error
          _isLoading = false;
        });
      }
      
      // Set a timeout to ensure loading doesn't hang indefinitely
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
          });
        }
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading home data: $e');
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await GoogleSignInService.signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        useStandardBackground: true,
        backgroundColor: AppColors.primaryBackground,
        showCpcLogo: true,
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopNavigationBar(context),
                    _buildHeroSection(context),
                    _buildQuickActionButtons(context),
                    _buildUpcomingEventsPreview(context),
                    _buildMemberHighlights(context),
                    _buildFooter(context),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/cpc.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIU CPC',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.cyan,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Hackathon 2025',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  radius: 18,
                  child: Text(
                    _currentUser?.name.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.deepPurple),
                onPressed: () => _signOut(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade600,
            Colors.cyan.shade400,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${_currentUser?.name ?? 'Member'}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ready to explore upcoming events and connect with the community?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                // Demo upcoming carousel (hidden by request)
                if (_enableHeroCarousel && _carouselEvents.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _carouselCtrl,
                            itemCount: _carouselEvents.length,
                            onPageChanged: (i) => setState(() => _carouselIndex = i),
                            itemBuilder: (context, i) {
                              final ev = _carouselEvents[i];
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (ev.imageUrl != null)
                                    Image.network(
                                      ev.imageUrl!,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, progress) => progress == null
                                          ? child
                                          : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorBuilder: (context, error, stack) => Container(
                                        color: Colors.black26,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image, color: Colors.white70),
                                      ),
                                    )
                                  else
                                    Container(color: Colors.black26),
                                  // Gradient overlay
                                  Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black54,
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Text content
                                  Positioned(
                                    left: 12,
                                    right: 12,
                                    bottom: 12,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ev.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text(
                                              ev.getFormattedDate(),
                                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.location_on, size: 12, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                ev.venue,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          // Dots indicator
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_carouselEvents.length, (i) {
                                final active = i == _carouselIndex;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 10 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active ? Colors.white : Colors.white54,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildActionCard(
                icon: Icons.event,
                title: 'Events',
                subtitle: 'Browse & Register',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.person,
                title: 'My Profile',
                subtitle: 'View & Edit',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.announcement,
                title: 'Announcements',
                subtitle: 'Latest News',
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnnouncementsScreen()),
                  );
                },
              ),
              _buildActionCard(
                icon: Icons.support_agent,
                title: 'Contact & Support',
                subtitle: 'Get Help',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ContactScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingEventsPreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EventsScreen()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_upcomingEvents.isEmpty)
            _buildEmptyEventsState()
          else
            _buildEventsCarousel(),
        ],
      ),
    );
  }

  Widget _buildEmptyEventsState() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy,
              size: 40,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No upcoming events available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Check back later for new events!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventsScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(120, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Browse Events', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsCarousel() {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _upcomingEvents.length,
        itemBuilder: (context, index) {
          final event = _upcomingEvents[index];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image header
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: SizedBox(
                      height: 90,
                      width: double.infinity,
                      child: (event.imageUrl != null && event.imageUrl!.isNotEmpty)
                          ? Image.network(
                              event.imageUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) => progress == null
                                  ? child
                                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              errorBuilder: (context, error, stack) => Container(
                                color: Colors.grey[300],
                                alignment: Alignment.center,
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                          : Container(color: Colors.grey[200]),
                    ),
                  ),
                  // Text content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              event.getFormattedDate(),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.venue,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EventsScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              minimumSize: const Size(double.infinity, 32),
                              ),
                            child: const Text('View Details', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }



  Widget _buildMemberHighlights(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Membership',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getMembershipStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getMembershipStatusText(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getMembershipStatusColor(),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: const Text('View Profile'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Events Joined', '${_upcomingEvents.length}'),
                  _buildStatItem('Department', _currentUser?.department ?? 'N/A'),
                  _buildStatItem('Year', _currentUser?.academicYear ?? 'N/A'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'DIU Computer Programming Club',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Empowering students through technology and innovation',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.facebook, color: Colors.blue),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.link, color: Colors.cyan),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.email, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getMembershipStatusColor() {
    switch (_currentUser?.membershipStatus) {
      case MembershipStatus.approved:
        return Colors.green;
      case MembershipStatus.pending:
        return Colors.orange;
      case MembershipStatus.rejected:
        return Colors.red;
      case MembershipStatus.suspended:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  String _getMembershipStatusText() {
    switch (_currentUser?.membershipStatus) {
      case MembershipStatus.approved:
        return 'Active Member';
      case MembershipStatus.pending:
        return 'Pending Approval';
      case MembershipStatus.rejected:
        return 'Application Rejected';
      case MembershipStatus.suspended:
        return 'Suspended';
      default:
        return 'Pending Approval';
    }
  }
}
