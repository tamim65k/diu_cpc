import 'package:flutter/material.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';

class ProfileStatsCard extends StatelessWidget {
  final String userId;

  const ProfileStatsCard({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Activity Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<EventModel>>(
                stream: EventService.getUserRegisteredEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final events = snapshot.data ?? [];
                  final upcomingEvents = events.where((e) => e.isUpcoming).length;
                  final completedEvents = events.where((e) => e.isCompleted).length;
                  final totalEvents = events.length;
                  
                  // Calculate event type participation
                  final workshops = events.where((e) => e.category == EventCategory.workshop).length;
                  final contests = events.where((e) => e.category == EventCategory.contest).length;
                  final seminars = events.where((e) => e.category == EventCategory.seminar).length;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              'Total Events',
                              totalEvents.toString(),
                              Icons.event,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Upcoming',
                              upcomingEvents.toString(),
                              Icons.schedule,
                              Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              'Completed',
                              completedEvents.toString(),
                              Icons.check_circle,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Event Categories',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildCategoryItem(
                              'Workshops',
                              workshops.toString(),
                              Icons.build,
                              Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: _buildCategoryItem(
                              'Contests',
                              contests.toString(),
                              Icons.emoji_events,
                              Colors.green,
                            ),
                          ),
                          Expanded(
                            child: _buildCategoryItem(
                              'Seminars',
                              seminars.toString(),
                              Icons.school,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
