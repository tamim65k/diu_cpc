import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/announcement_model.dart';
import '../../services/announcement_service.dart';
import '../../widgets/announcement_widgets.dart';
import 'announcement_details_screen.dart';
import 'admin/admin_announcement_form_screen.dart';
import 'category_announcements_screen.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<AnnouncementModel> _allAnnouncements = [];
  List<AnnouncementModel> _filteredAnnouncements = [];
  Map<AnnouncementCategory, int> _categoryCounts = {};
  AnnouncementCategory? _selectedCategory;
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Seed demo data (safe no-op if already exists)
    AnnouncementService.initializeSampleAnnouncements();
    _loadAnnouncements();
    _loadCategoryCounts();
  }

  Widget _buildArchiveTab() {
    return FutureBuilder<List<AnnouncementModel>>(
      future: AnnouncementService.getArchivedAnnouncements(limit: 50, category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => const AnnouncementShimmer(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading archived announcements',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        var archivedAnnouncements = snapshot.data ?? [];
        if (archivedAnnouncements.isEmpty) {
          archivedAnnouncements = AnnouncementService.getDemoAnnouncements()
              .where((a) => a.status == AnnouncementStatus.archived)
              .where((a) => _selectedCategory == null || a.category == _selectedCategory)
              .toList();
        }

        if (archivedAnnouncements.isEmpty) {
          return const EmptyAnnouncementsWidget(
            message: 'No archived announcements',
            subtitle: 'Archived announcements will appear here',
          );
        }

        return ListView.builder(
          itemCount: archivedAnnouncements.length,
          itemBuilder: (context, index) {
            final announcement = archivedAnnouncements[index];
            return AnnouncementCard(
              announcement: announcement,
              onTap: () => _navigateToDetails(announcement),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final announcements = await AnnouncementService.getPublishedAnnouncements(
        limit: 50,
        category: _selectedCategory,
      );

      var finalList = announcements;
      if (finalList.isEmpty) {
        // Fallback to demo data (published & active)
        final demo = AnnouncementService.getDemoAnnouncements()
            .where((a) => a.status == AnnouncementStatus.published)
            .where((a) => a.expiresAt == null || a.expiresAt!.isAfter(DateTime.now()))
            .toList();
        if (_selectedCategory != null) {
          finalList = demo.where((a) => a.category == _selectedCategory).toList();
        } else {
          finalList = demo;
        }
      }

      setState(() {
        _allAnnouncements = finalList;
        _filteredAnnouncements = finalList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        // On error, show demo data
        final demo = AnnouncementService.getDemoAnnouncements()
            .where((a) => a.status == AnnouncementStatus.published)
            .toList();
        _allAnnouncements = demo;
        _filteredAnnouncements = demo;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading announcements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final counts = await AnnouncementService.getCategoryCounts();
      // If no data, compute from demo announcements
      if (counts.values.fold<int>(0, (p, c) => p + c) == 0) {
        final demo = AnnouncementService.getDemoAnnouncements()
            .where((a) => a.status == AnnouncementStatus.published)
            .toList();
        final map = <AnnouncementCategory, int>{};
        for (var cat in AnnouncementCategory.values) {
          map[cat] = demo.where((a) => a.category == cat).length;
        }
        setState(() {
          _categoryCounts = map;
        });
      } else {
        setState(() {
          _categoryCounts = counts;
        });
      }
    } catch (e) {
      print('Error loading category counts: $e');
      // Fallback to demo counts on error
      final demo = AnnouncementService.getDemoAnnouncements()
          .where((a) => a.status == AnnouncementStatus.published)
          .toList();
      final map = <AnnouncementCategory, int>{};
      for (var cat in AnnouncementCategory.values) {
        map[cat] = demo.where((a) => a.category == cat).length;
      }
      setState(() {
        _categoryCounts = map;
      });
    }
  }

  void _filterByCategory(AnnouncementCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    _loadAnnouncements();
  }

  void _searchAnnouncements(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredAnnouncements = _allAnnouncements;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await AnnouncementService.searchAnnouncements(
        query,
        category: _selectedCategory,
      );
      
      setState(() {
        _filteredAnnouncements = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Pinned', icon: Icon(Icons.push_pin)),
            Tab(text: 'Archive', icon: Icon(Icons.archive)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchAnnouncements('');
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
              onChanged: _searchAnnouncements,
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAnnouncementsTab(),
                _buildPinnedAnnouncementsTab(),
                _buildArchiveTab(),
                _buildCategoriesTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildAdminFab(),
    );
  }

  Widget _buildAllAnnouncementsTab() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => const AnnouncementShimmer(),
      );
    }

    if (_filteredAnnouncements.isEmpty) {
      return EmptyAnnouncementsWidget(
        message: _searchController.text.isNotEmpty
            ? 'No announcements found'
            : 'No announcements available',
        subtitle: _searchController.text.isNotEmpty
            ? 'Try adjusting your search terms'
            : 'Check back later for updates',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnnouncements,
      child: ListView.builder(
        itemCount: _filteredAnnouncements.length,
        itemBuilder: (context, index) {
          final announcement = _filteredAnnouncements[index];
          return AnnouncementCard(
            announcement: announcement,
            onTap: () => _navigateToDetails(announcement),
          );
        },
      ),
    );
  }

  Widget _buildPinnedAnnouncementsTab() {
    return FutureBuilder<List<AnnouncementModel>>(
      future: AnnouncementService.getPinnedAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) => const AnnouncementShimmer(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading pinned announcements',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        var pinnedAnnouncements = snapshot.data ?? [];
        if (pinnedAnnouncements.isEmpty) {
          pinnedAnnouncements = AnnouncementService.getDemoAnnouncements()
              .where((a) => a.status == AnnouncementStatus.published && a.isPinned)
              .toList();
        }
        
        if (pinnedAnnouncements.isEmpty) {
          return const EmptyAnnouncementsWidget(
            message: 'No pinned announcements',
            subtitle: 'Important announcements will appear here',
          );
        }

        return ListView.builder(
          itemCount: pinnedAnnouncements.length,
          itemBuilder: (context, index) {
            final announcement = pinnedAnnouncements[index];
            return AnnouncementCard(
              announcement: announcement,
              onTap: () => _navigateToDetails(announcement),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browse by Category',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Category filters
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text('All (${_allAnnouncements.length})'),
                selected: _selectedCategory == null,
                onSelected: (_) => _filterByCategory(null),
                backgroundColor: Colors.grey[200],
                selectedColor: Colors.blue[100],
              ),
              ...AnnouncementCategory.values.map((category) {
                final count = _categoryCounts[category] ?? 0;
                return CategoryFilterChip(
                  category: category,
                  isSelected: _selectedCategory == category,
                  onTap: () => _filterByCategory(category),
                  count: count,
                );
              }).toList(),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Category grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: AnnouncementCategory.values.length,
            itemBuilder: (context, index) {
              final category = AnnouncementCategory.values[index];
              final count = _categoryCounts[category] ?? 0;
              
              return _buildCategoryCard(category, count);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(AnnouncementCategory category, int count) {
    final announcement = AnnouncementModel(
      id: '',
      title: '',
      content: '',
      authorId: '',
      authorName: '',
      category: category,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CategoryAnnouncementsScreen(category: category),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                announcement.getCategoryIcon(),
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                announcement.getCategoryDisplayName(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count announcement${count != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminFab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () async {
        final created = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminAnnouncementFormScreen(),
          ),
        );
        if (created == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement created')),
          );
          _loadAnnouncements();
          _loadCategoryCounts();
        }
      },
      icon: const Icon(Icons.campaign),
      label: const Text('New Announcement'),
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
    );
  }

  void _navigateToDetails(AnnouncementModel announcement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnnouncementDetailsScreen(
          announcement: announcement,
        ),
      ),
    );
  }
}
