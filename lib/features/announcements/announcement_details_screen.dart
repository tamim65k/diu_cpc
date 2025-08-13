import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';

class AnnouncementDetailsScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailsScreen> createState() => _AnnouncementDetailsScreenState();
}

class _AnnouncementDetailsScreenState extends State<AnnouncementDetailsScreen> {
  late AnnouncementModel _announcement;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      await AnnouncementService.incrementViewCount(_announcement.id);
      // Update local view count
      setState(() {
        _announcement = _announcement.copyWith(
          viewCount: _announcement.viewCount + 1,
        );
      });
    } catch (e) {
      // Silently fail - view count is not critical
      print('Error incrementing view count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAnnouncement,
            tooltip: 'Share',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  _copyToClipboard();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Copy text'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with priority and category
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColorFromHex(_announcement.getPriorityColor()).withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Priority and category badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getColorFromHex(_announcement.getPriorityColor()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _announcement.getPriorityDisplayName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _announcement.getCategoryIcon(),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _announcement.getCategoryDisplayName(),
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (_announcement.isPinned)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.push_pin,
                            size: 20,
                            color: Colors.orange[700],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    _announcement.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _announcement.authorName,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _announcement.getFormattedPublishedDate(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (_announcement.viewCount > 0) ...[
                        Icon(
                          Icons.visibility,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_announcement.viewCount} views',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image if available
                  if (_announcement.imageUrl != null && _announcement.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _announcement.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Content text
                  Text(
                    _announcement.content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Tags
                  if (_announcement.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _announcement.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Text(
                            '#$tag',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  // Expiry information
                  if (_announcement.expiresAt != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _announcement.isExpired 
                            ? Colors.red[50] 
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _announcement.isExpired 
                              ? Colors.red[200]! 
                              : Colors.orange[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _announcement.isExpired 
                                ? Icons.schedule_outlined 
                                : Icons.access_time,
                            color: _announcement.isExpired 
                                ? Colors.red[600] 
                                : Colors.orange[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _announcement.isExpired 
                                      ? 'This announcement has expired' 
                                      : 'This announcement expires on',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _announcement.isExpired 
                                        ? Colors.red[700] 
                                        : Colors.orange[700],
                                  ),
                                ),
                                Text(
                                  '${_announcement.expiresAt!.day}/${_announcement.expiresAt!.month}/${_announcement.expiresAt!.year}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _announcement.isExpired 
                                        ? Colors.red[600] 
                                        : Colors.orange[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAnnouncement() {
    final text = '''
${_announcement.title}

${_announcement.content}

Published by ${_announcement.authorName}
${_announcement.getFormattedPublishedDate()}

#DIU #CPC #${_announcement.getCategoryDisplayName()}
''';
    
    // In a real app, you would use the share_plus package
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Announcement copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _copyToClipboard() {
    final text = '''
${_announcement.title}

${_announcement.content}
''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        backgroundColor: Colors.green,
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
