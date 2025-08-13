import 'package:flutter/material.dart';
import '../../../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onTap;
  final bool showCountdown;
  final bool isRegistered;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.showCountdown = false,
    this.isRegistered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event image or placeholder
            _buildEventImage(),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event title and category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Event description
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Event details row
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(event.startDateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Bottom row with participants and countdown/status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildParticipantsInfo(),
                      if (showCountdown && event.isUpcoming)
                        _buildCountdown()
                      else
                        _buildStatusChip(),
                    ],
                  ),
                  
                  // Registration status for user's events
                  if (isRegistered) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Registered',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: Colors.grey[200],
      ),
      child: event.imageUrl != null
          ? ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                event.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage();
                },
              ),
            )
          : _buildPlaceholderImage(),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
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
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCategoryColor().withOpacity(0.3),
        ),
      ),
      child: Text(
        event.categoryDisplayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _getCategoryColor(),
        ),
      ),
    );
  }

  Widget _buildParticipantsInfo() {
    return Row(
      children: [
        Icon(
          Icons.people,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          '${event.currentParticipants}/${event.maxParticipants}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (event.isFull) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.warning,
            size: 14,
            color: Colors.orange[600],
          ),
        ],
      ],
    );
  }

  Widget _buildCountdown() {
    final timeUntil = event.timeUntilStart;
    
    if (timeUntil.isNegative) {
      return _buildStatusChip();
    }

    String countdownText;
    Color countdownColor;

    if (timeUntil.inDays > 0) {
      countdownText = '${timeUntil.inDays}d';
      countdownColor = Colors.blue;
    } else if (timeUntil.inHours > 0) {
      countdownText = '${timeUntil.inHours}h';
      countdownColor = Colors.orange;
    } else {
      countdownText = '${timeUntil.inMinutes}m';
      countdownColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: countdownColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: countdownColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 12,
            color: countdownColor,
          ),
          const SizedBox(width: 4),
          Text(
            countdownText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: countdownColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    IconData statusIcon;
    
    switch (event.status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            event.statusDisplayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (event.category) {
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
    switch (event.category) {
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

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$displayHour:$minute $period';
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
