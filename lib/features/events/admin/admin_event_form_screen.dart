import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/event_model.dart';
import '../../../services/event_service.dart';

class AdminEventFormScreen extends StatefulWidget {
  final EventModel? event; // null => create, not null => edit
  const AdminEventFormScreen({super.key, this.event});

  @override
  State<AdminEventFormScreen> createState() => _AdminEventFormScreenState();
}

class _AdminEventFormScreenState extends State<AdminEventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _agendaCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _speakersCtrl = TextEditingController();
  final _requirementsCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _maxParticipantsCtrl = TextEditingController(text: '100');
  final _feeCtrl = TextEditingController(text: '0');

  DateTime _start = DateTime.now().add(const Duration(days: 3));
  DateTime _end = DateTime.now().add(const Duration(days: 3, hours: 3));
  DateTime? _regDeadline = DateTime.now().add(const Duration(days: 2));
  EventCategory _category = EventCategory.general;
  bool _requiresApproval = true; // new events default pending approval
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descCtrl.text = e.description;
      _agendaCtrl.text = e.agenda;
      _venueCtrl.text = e.venue;
      _locationCtrl.text = e.location ?? '';
      _speakersCtrl.text = e.speakers.join(', ');
      _requirementsCtrl.text = e.requirements.join(', ');
      _imageUrlCtrl.text = e.imageUrl ?? '';
      _maxParticipantsCtrl.text = e.maxParticipants.toString();
      _feeCtrl.text = (e.registrationFee ?? 0).toString();
      _start = e.startDateTime;
      _end = e.endDateTime;
      _regDeadline = e.registrationDeadline;
      _category = e.category;
      _requiresApproval = e.requiresApproval;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _agendaCtrl.dispose();
    _venueCtrl.dispose();
    _locationCtrl.dispose();
    _speakersCtrl.dispose();
    _requirementsCtrl.dispose();
    _imageUrlCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _textField(_titleCtrl, 'Title', requiredField: true),
              const SizedBox(height: 12),
              _textField(_descCtrl, 'Description', maxLines: 4, requiredField: true),
              const SizedBox(height: 12),
              _textField(_agendaCtrl, 'Agenda', maxLines: 3),
              const SizedBox(height: 12),
              _textField(_venueCtrl, 'Venue', requiredField: true),
              const SizedBox(height: 12),
              _textField(_locationCtrl, 'Location (lat,lng or address)'),
              const SizedBox(height: 12),
              _textField(_imageUrlCtrl, 'Cover Image URL'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _numberField(_maxParticipantsCtrl, 'Max Participants')),
                const SizedBox(width: 12),
                Expanded(child: _numberField(_feeCtrl, 'Fee (৳)', isDouble: true)),
              ]),
              const SizedBox(height: 12),
              _chips<EventCategory>(
                label: 'Category',
                values: EventCategory.values,
                selected: _category,
                toText: (c) => c.toString().split('.').last,
                onSelected: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 12),
              _dateRow('Start', _start, (d) => setState(() => _start = d)),
              const SizedBox(height: 8),
              _dateRow('End', _end, (d) => setState(() => _end = d)),
              const SizedBox(height: 8),
              _dateRow('Registration Deadline', _regDeadline, (d) => setState(() => _regDeadline = d), allowNull: true),
              const SizedBox(height: 12),
              _textField(_speakersCtrl, 'Speakers (comma separated)'),
              const SizedBox(height: 12),
              _textField(_requirementsCtrl, 'Requirements (comma separated)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Switch(
                    value: _requiresApproval,
                    onChanged: (v) => setState(() => _requiresApproval = v),
                  ),
                  const Text('Requires Approval'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(widget.event == null ? 'Create Event' : 'Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(TextEditingController c, String label, {int maxLines = 1, bool requiredField = false}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      maxLines: maxLines,
      validator: requiredField
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    );
  }

  Widget _numberField(TextEditingController c, String label, {bool isDouble = false}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        return isDouble ? (double.tryParse(v) == null ? 'Invalid' : null) : (int.tryParse(v) == null ? 'Invalid' : null);
      },
    );
  }

  Widget _chips<T>({
    required String label,
    required List<T> values,
    required T selected,
    required String Function(T) toText,
    required void Function(T) onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: values.map((v) {
            final sel = v == selected;
            return ChoiceChip(
              label: Text(toText(v)),
              selected: sel,
              onSelected: (_) => onSelected(v),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dateRow(String label, DateTime? date, ValueChanged<DateTime> onPick, {bool allowNull = false}) {
    return Row(
      children: [
        Expanded(child: Text('$label: ${date != null ? _fmt(date) : 'Not set'}')),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: date ?? now,
              firstDate: now.subtract(const Duration(days: 1)),
              lastDate: now.add(const Duration(days: 365 * 3)),
            );
            if (d == null) return;
            final t = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(date ?? now),
            );
            if (t == null) return;
            onPick(DateTime(d.year, d.month, d.day, t.hour, t.minute));
          },
          child: const Text('Pick'),
        ),
        if (allowNull) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => setState(() => _regDeadline = null),
            child: const Text('Clear'),
          ),
        ]
      ],
    );
  }

  String _fmt(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login required for admin actions')));
      return;
    }
    setState(() => _busy = true);
    try {
      final speakers = _speakersCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final reqs = _requirementsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final maxPart = int.tryParse(_maxParticipantsCtrl.text) ?? 100;
      final fee = double.tryParse(_feeCtrl.text);

      final base = EventModel(
        id: widget.event?.id ?? 'new',
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        agenda: _agendaCtrl.text.trim(),
        startDateTime: _start,
        endDateTime: _end.isAfter(_start) ? _end : _start.add(const Duration(hours: 2)),
        venue: _venueCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
        category: _category,
        status: EventStatus.upcoming,
        organizerName: 'DIU CPC',
        organizerEmail: FirebaseAuth.instance.currentUser?.email ?? 'admin@diu.edu.bd',
        speakers: speakers,
        maxParticipants: maxPart,
        currentParticipants: widget.event?.currentParticipants ?? 0,
        registeredUsers: widget.event?.registeredUsers ?? const [],
        waitlistUsers: widget.event?.waitlistUsers ?? const [],
        imageUrl: _imageUrlCtrl.text.trim().isEmpty ? null : _imageUrlCtrl.text.trim(),
        requirements: reqs,
        requiresApproval: _requiresApproval,
        registrationFee: fee == null || fee == 0 ? null : fee,
        registrationDeadline: _regDeadline,
        createdAt: widget.event?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: FirebaseAuth.instance.currentUser!.uid,
        additionalInfo: {
          ...(widget.event?.additionalInfo ?? {}),
          'approvalStatus': _requiresApproval ? 'pending' : 'approved',
        },
      );

      if (widget.event == null) {
        await EventService.createEvent(base);
      } else {
        await EventService.updateEvent(widget.event!.id, base);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event saved')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
