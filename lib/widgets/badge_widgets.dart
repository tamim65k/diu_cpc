import 'package:flutter/material.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';

class BadgeCard extends StatelessWidget {
  final UserBadgeModel userBadge;
  final bool showDetails;
  final VoidCallback? onTap;

  const BadgeCard({
    super.key,
    required this.userBadge,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final badge = userBadge.badge;
    if (badge == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getColorFromHex(badge.getDisplayColor()).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getColorFromHex(badge.getDisplayColor()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  badge.iconUrl,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Badge Name
            Text(
              badge.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (showDetails) ...[
              const SizedBox(height: 4),
              Text(
                badge.description,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getColorFromHex(badge.getDisplayColor()),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${badge.points} pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class BadgeGrid extends StatelessWidget {
  final List<UserBadgeModel> badges;
  final int maxDisplay;
  final bool showDetails;
  final Function(UserBadgeModel)? onBadgeTap;

  const BadgeGrid({
    super.key,
    required this.badges,
    this.maxDisplay = 6,
    this.showDetails = false,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayBadges = badges.take(maxDisplay).toList();
    final remainingCount = badges.length - maxDisplay;

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: showDetails ? 2 : 3,
            childAspectRatio: showDetails ? 0.8 : 1.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: displayBadges.length,
          itemBuilder: (context, index) {
            return BadgeCard(
              userBadge: displayBadges[index],
              showDetails: showDetails,
              onTap: onBadgeTap != null 
                  ? () => onBadgeTap!(displayBadges[index])
                  : null,
            );
          },
        ),
        
        if (remainingCount > 0) ...[
          const SizedBox(height: 8),
          Text(
            '+$remainingCount more badges',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class BadgeStatsCard extends StatelessWidget {
  final Map<String, int> stats;

  const BadgeStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade600,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Total Badges',
                '${stats['total'] ?? 0}',
                Icons.stars,
              ),
              _buildStatItem(
                'Total Points',
                '${stats['totalPoints'] ?? 0}',
                Icons.emoji_events,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCategoryItem('Events', stats['events'] ?? 0, '🎯'),
              _buildCategoryItem('Programming', stats['programming'] ?? 0, '💻'),
              _buildCategoryItem('Leadership', stats['leadership'] ?? 0, '👑'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem(String label, int count, String emoji) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class MembershipStatusBadge extends StatelessWidget {
  final MembershipStatus status;
  final String? role;

  const MembershipStatusBadge({
    super.key,
    required this.status,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getStatusText(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case MembershipStatus.approved:
        return Colors.green;
      case MembershipStatus.pending:
        return Colors.orange;
      case MembershipStatus.rejected:
        return Colors.red;
      case MembershipStatus.suspended:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (status) {
      case MembershipStatus.approved:
        return Icons.verified;
      case MembershipStatus.pending:
        return Icons.hourglass_empty;
      case MembershipStatus.rejected:
        return Icons.cancel;
      case MembershipStatus.suspended:
        return Icons.pause_circle;
    }
  }

  String _getStatusText() {
    if (role != null && role!.isNotEmpty && status == MembershipStatus.approved) {
      return role!;
    }
    
    switch (status) {
      case MembershipStatus.approved:
        return 'Member';
      case MembershipStatus.pending:
        return 'Pending';
      case MembershipStatus.rejected:
        return 'Rejected';
      case MembershipStatus.suspended:
        return 'Suspended';
    }
  }
}

class BadgeDetailsDialog extends StatelessWidget {
  final UserBadgeModel userBadge;

  const BadgeDetailsDialog({
    super.key,
    required this.userBadge,
  });

  @override
  Widget build(BuildContext context) {
    final badge = userBadge.badge;
    if (badge == null) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _getColorFromHex(badge.getDisplayColor()).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: Text(
                  badge.iconUrl,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Badge Name
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Badge Description
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Badge Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem('Type', badge.getTypeDisplayName()),
                _buildDetailItem('Category', badge.getCategoryDisplayName()),
                _buildDetailItem('Points', '${badge.points}'),
              ],
            ),
            const SizedBox(height: 16),
            
            // Earned Date
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Earned ${badge.getFormattedEarnedDate()}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getColorFromHex(badge.getDisplayColor()),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hexColor) {
    try {
      return Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}
