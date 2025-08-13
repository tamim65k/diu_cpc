import 'package:flutter/material.dart';
import '../../../models/event_model.dart';

class EventHistoryCard extends StatelessWidget {
  final EventModel event;
  final bool showStatus;
  final bool showCountdown;

  const EventHistoryCard({
    super.key,
    required this.event,
    this.showStatus = true,
    this.showCountdown = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.categoryDisplayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: _getCategoryColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStatus) _buildStatusChip(),
                if (showCountdown && event.isUpcoming) _buildCountdown(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
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
                  size: 14,
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
            if (event.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEventIcon() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getCategoryIcon(),
        color: _getCategoryColor(),
        size: 20,
      ),
    );
  }

  Widget _buildStatusChip() {
    Color statusColor;
    String statusText;
    
    switch (event.status) {
      case EventStatus.upcoming:
        statusColor = Colors.blue;
        statusText = 'Upcoming';
        break;
      case EventStatus.ongoing:
        statusColor = Colors.green;
        statusText = 'Ongoing';
        break;
      case EventStatus.completed:
        statusColor = Colors.grey;
        statusText = 'Completed';
        break;
      case EventStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: statusColor,
        ),
      ),
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
      countdownText = '${timeUntil.inDays}d left';
      countdownColor = Colors.blue;
    } else if (timeUntil.inHours > 0) {
      countdownText = '${timeUntil.inHours}h left';
      countdownColor = Colors.orange;
    } else {
      countdownText = '${timeUntil.inMinutes}m left';
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
            size: 10,
            color: countdownColor,
          ),
          const SizedBox(width: 4),
          Text(
            countdownText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: countdownColor,
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
    } else if (difference.inDays < 7 && difference.inDays > 0) {
      return '${_getDayName(dateTime.weekday)} ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
