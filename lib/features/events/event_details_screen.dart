import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isRegistering = false;
  bool _isRegistered = false;
  bool _isOnWaitlist = false;

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  void _checkRegistrationStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isRegistered = widget.event.registeredUsers.contains(user.uid);
        _isOnWaitlist = widget.event.waitlistUsers.contains(user.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEventHeader(),
                  const SizedBox(height: 24),
                  _buildEventDetails(),
                  const SizedBox(height: 24),
                  _buildDescription(),
                  const SizedBox(height: 24),
                  _buildAgenda(),
                  const SizedBox(height: 24),
                  _buildSpeakers(),
                  const SizedBox(height: 24),
                  _buildRequirements(),
                  const SizedBox(height: 24),
                  _buildOrganizer(),
                  const SizedBox(height: 100), // Space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.event.imageUrl != null
            ? Image.network(
                widget.event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              )
            : _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor().withOpacity(0.7),
            _getCategoryColor().withOpacity(0.9),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getCategoryIcon(),
          size: 64,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                widget.event.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildCategoryChip(),
          ],
        ),
        const SizedBox(height: 8),
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildEventDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.access_time,
              'Date & Time',
              '${_formatDate(widget.event.startDateTime)}\n${_formatTime(widget.event.startDateTime)} - ${_formatTime(widget.event.endDateTime)}',
            ),
            const Divider(),
            _buildDetailRow(
              Icons.location_on,
              'Venue',
              widget.event.venue,
            ),
            const Divider(),
            _buildDetailRow(
              Icons.people,
              'Participants',
              '${widget.event.currentParticipants}/${widget.event.maxParticipants} registered',
            ),
            if (widget.event.registrationFee != null) ...[
              const Divider(),
              _buildDetailRow(
                Icons.payment,
                'Registration Fee',
                '৳${widget.event.registrationFee!.toStringAsFixed(0)}',
              ),
            ],
            if (widget.event.registrationDeadline != null) ...[
              const Divider(),
              _buildDetailRow(
                Icons.schedule,
                'Registration Deadline',
                _formatDate(widget.event.registrationDeadline!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.deepPurple),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.event.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildAgenda() {
    if (widget.event.agenda.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agenda',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.event.agenda,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSpeakers() {
    if (widget.event.speakers.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Speakers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.event.speakers.map((speaker) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    speaker,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRequirements() {
    if (widget.event.requirements.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requirements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.event.requirements.map((requirement) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      requirement,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildOrganizer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Organizer',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Text(
                      widget.event.organizerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, color: Colors.deepPurple),
                    const SizedBox(width: 12),
                    Text(
                      widget.event.organizerEmail,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                if (widget.event.organizerPhone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Text(
                        widget.event.organizerPhone!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to register for events')),
          );
        },
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.login, color: Colors.white),
        label: const Text('Login Required', style: TextStyle(color: Colors.white)),
      );
    }

    if (!widget.event.isRegistrationOpen) {
      return FloatingActionButton.extended(
        onPressed: null,
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.close, color: Colors.white),
        label: const Text('Registration Closed', style: TextStyle(color: Colors.white)),
      );
    }

    if (_isRegistered) {
      return FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _unregisterFromEvent,
        backgroundColor: Colors.red,
        icon: _isRegistering
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.cancel, color: Colors.white),
        label: Text(
          _isRegistering ? 'Unregistering...' : 'Unregister',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (_isOnWaitlist) {
      return FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _unregisterFromEvent,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.schedule, color: Colors.white),
        label: const Text('On Waitlist', style: TextStyle(color: Colors.white)),
      );
    }

    return FloatingActionButton.extended(
      onPressed: _isRegistering ? null : _registerForEvent,
      backgroundColor: widget.event.isFull ? Colors.orange : Colors.green,
      icon: _isRegistering
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(
              widget.event.isFull ? Icons.schedule : Icons.check,
              color: Colors.white,
            ),
      label: Text(
        _isRegistering
            ? 'Registering...'
            : widget.event.isFull
                ? 'Join Waitlist'
                : 'Register',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Future<void> _registerForEvent() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      final wasRegistered = await EventService.registerForEvent(widget.event.id);
      
      if (wasRegistered) {
        setState(() {
          _isRegistered = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered for event!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _isOnWaitlist = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event is full. You have been added to the waitlist.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Future<void> _unregisterFromEvent() async {
    setState(() {
      _isRegistering = true;
    });

    try {
      await EventService.unregisterFromEvent(widget.event.id);
      
      setState(() {
        _isRegistered = false;
        _isOnWaitlist = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully unregistered from event'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unregister: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
        ),
      ),
      child: Text(
        widget.event.categoryDisplayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _getCategoryColor(),
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    IconData statusIcon;
    
    switch (widget.event.status) {
      case EventStatus.upcoming:
        statusColor = Colors.blue;
        statusIcon = Icons.schedule;
        break;
      case EventStatus.ongoing:
        statusColor = Colors.green;
        statusIcon = Icons.play_circle;
        break;
      case EventStatus.completed:
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        break;
      case EventStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 6),
          Text(
            widget.event.statusDisplayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.event.category) {
      case EventCategory.workshop:
        return Colors.blue;
      case EventCategory.contest:
        return Colors.green;
      case EventCategory.seminar:
        return Colors.orange;
      case EventCategory.meetup:
        return Colors.purple;
      case EventCategory.general:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon() {
    switch (widget.event.category) {
      case EventCategory.workshop:
        return Icons.build;
      case EventCategory.contest:
        return Icons.emoji_events;
      case EventCategory.seminar:
        return Icons.school;
      case EventCategory.meetup:
        return Icons.people;
      case EventCategory.general:
        return Icons.event;
    }
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }
}
