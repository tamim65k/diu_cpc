import 'package:flutter/material.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'event_details_screen.dart';
import 'past_events_archive_screen.dart';
import 'widgets/event_card.dart';
import 'admin/admin_events_screen.dart';
import 'widgets/event_filter_chip.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EventCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
            Tab(text: 'My Events'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingEvents(),
                _buildPastEvents(),
                _buildMyEvents(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AdminEventsScreen(),
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search events...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 12),
          // Category filters
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                EventFilterChip(
                  label: 'All',
                  isSelected: _selectedCategory == null,
                  onSelected: () {
                    setState(() {
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(width: 8),
                ...EventCategory.values.map((category) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: EventFilterChip(
                        label: _getCategoryDisplayName(category),
                        isSelected: _selectedCategory == category,
                        onSelected: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getUpcomingEventsWithDemo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading events',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final events = _filterEvents(snapshot.data ?? []);

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No upcoming events found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later for new events!',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: EventCard(
                event: event,
                onTap: () => _navigateToEventDetails(event),
                showCountdown: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPastEvents() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getPastEventsWithDemo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading past events',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final events = _filterEvents(snapshot.data ?? []);

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No past events found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Past events will appear here once completed',
                  style: TextStyle(color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PastEventsArchiveScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.archive),
                  label: const Text('View Full Archive'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Archive button at the top
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PastEventsArchiveScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.archive),
                label: const Text('View Complete Archive'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // Recent past events
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: events.take(5).length, // Show only recent 5 events
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: EventCard(
                      event: event,
                      onTap: () => _navigateToEventDetails(event),
                      showCountdown: false,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMyEvents() {
    return StreamBuilder<List<EventModel>>(
      stream: EventService.getUserRegisteredEventsWithDemo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error loading your events',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        final events = _filterEvents(snapshot.data ?? []);

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No registered events',
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
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: EventCard(
                event: event,
                onTap: () => _navigateToEventDetails(event),
                showCountdown: event.isUpcoming,
                isRegistered: true,
              ),
            );
          },
        );
      },
    );
  }

  List<EventModel> _filterEvents(List<EventModel> events) {
    var filteredEvents = events;

    // Filter by category
    if (_selectedCategory != null) {
      filteredEvents = filteredEvents
          .where((event) => event.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredEvents = filteredEvents
          .where((event) =>
              event.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              event.organizerName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    return filteredEvents;
  }

  String _getCategoryDisplayName(EventCategory category) {
    switch (category) {
      case EventCategory.workshop:
        return 'Workshop';
      case EventCategory.contest:
        return 'Contest';
      case EventCategory.seminar:
        return 'Seminar';
      case EventCategory.meetup:
        return 'Meetup';
      case EventCategory.general:
        return 'General';
    }
  }

  void _navigateToEventDetails(EventModel event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(event: event),
      ),
    );
  }
}
