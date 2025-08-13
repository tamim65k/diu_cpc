import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/announcement_model.dart';
import '../../../services/announcement_service.dart';

class AdminAnnouncementFormScreen extends StatefulWidget {
  const AdminAnnouncementFormScreen({super.key});

  @override
  State<AdminAnnouncementFormScreen> createState() => _AdminAnnouncementFormScreenState();
}

class _AdminAnnouncementFormScreenState extends State<AdminAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _imageUrlController = TextEditingController();

  AnnouncementPriority _priority = AnnouncementPriority.normal;
  AnnouncementCategory _category = AnnouncementCategory.general;
  DateTime? _expiryDate;
  bool _isPinned = false;
  bool _publishNow = true;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final now = DateTime.now();
      final tags = _tagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final model = AnnouncementModel(
        id: '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Admin',
        priority: _priority,
        category: _category,
        status: _publishNow ? AnnouncementStatus.published : AnnouncementStatus.draft,
        tags: tags,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        createdAt: now,
        updatedAt: now,
        publishedAt: _publishNow ? now : null,
        expiresAt: _expiryDate,
        isPinned: _isPinned,
      );

      final id = await AnnouncementService.createAnnouncement(model);
      if (id == null) throw Exception('Failed to create announcement');

      // If publishNow is true but service sets draft by default, ensure publish
      if (_publishNow && model.status != AnnouncementStatus.published) {
        await AnnouncementService.publishAnnouncement(id);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Announcement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Content is required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AnnouncementPriority>(
                        value: _priority,
                        items: AnnouncementPriority.values.map((p) {
                          final temp = AnnouncementModel(
                            id: '', title: '', content: '', authorId: '', authorName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), priority: p, category: _category,
                          );
                          return DropdownMenuItem(value: p, child: Text(temp.getPriorityDisplayName()));
                        }).toList(),
                        onChanged: (v) => setState(() => _priority = v ?? AnnouncementPriority.normal),
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<AnnouncementCategory>(
                        value: _category,
                        items: AnnouncementCategory.values.map((c) {
                          final temp = AnnouncementModel(
                            id: '', title: '', content: '', authorId: '', authorName: '', createdAt: DateTime.now(), updatedAt: DateTime.now(), category: c,
                          );
                          return DropdownMenuItem(value: c, child: Text(temp.getCategoryDisplayName()));
                        }).toList(),
                        onChanged: (v) => setState(() => _category = v ?? AnnouncementCategory.general),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiryDate,
                        icon: const Icon(Icons.event),
                        label: Text(_expiryDate == null
                            ? 'Set expiry (optional)'
                            : 'Expires: ${_expiryDate!.toLocal().toString().split(' ').first}'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SwitchListTile(
                        value: _isPinned,
                        onChanged: (v) => setState(() => _isPinned = v),
                        title: const Text('Pin'),
                        dense: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _publishNow,
                  onChanged: (v) => setState(() => _publishNow = v),
                  title: const Text('Publish now'),
                  subtitle: const Text('If off, saves as draft'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save),
                    label: Text(_submitting ? 'Saving...' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
