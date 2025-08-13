import 'package:flutter/material.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import '../../widgets/announcement_widgets.dart';
import 'announcement_details_screen.dart';

class CategoryAnnouncementsScreen extends StatefulWidget {
  final AnnouncementCategory category;
  const CategoryAnnouncementsScreen({super.key, required this.category});

  @override
  State<CategoryAnnouncementsScreen> createState() => _CategoryAnnouncementsScreenState();
}

class _CategoryAnnouncementsScreenState extends State<CategoryAnnouncementsScreen> {
  late Future<List<AnnouncementModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AnnouncementModel>> _load() async {
    try {
      final list = await AnnouncementService.getPublishedAnnouncements(
        limit: 100,
        category: widget.category,
      );
      if (list.isNotEmpty) return list;
      // Fallback to demo data
      return AnnouncementService.getDemoAnnouncements()
          .where((a) => a.status == AnnouncementStatus.published && a.category == widget.category)
          .toList();
    } catch (_) {
      return AnnouncementService.getDemoAnnouncements()
          .where((a) => a.status == AnnouncementStatus.published && a.category == widget.category)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.category.toString().split('.').last;
    return Scaffold(
      appBar: AppBar(
        title: Text('$title Announcements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<AnnouncementModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) => const AnnouncementShimmer(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading $title announcements',
                  style: TextStyle(color: Colors.red[400]),
                ),
              ),
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return EmptyAnnouncementsWidget(
              message: 'No $title announcements',
              subtitle: 'Announcements in this category will appear here',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future;
            },
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final announcement = items[index];
                return AnnouncementCard(
                  announcement: announcement,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AnnouncementDetailsScreen(announcement: announcement),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
