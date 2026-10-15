import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DoctorTimeSlotsScreen extends StatefulWidget {
  const DoctorTimeSlotsScreen({super.key});

  @override
  State<DoctorTimeSlotsScreen> createState() => _DoctorTimeSlotsScreenState();
}

class _DoctorTimeSlotsScreenState extends State<DoctorTimeSlotsScreen> {
  final List<String> _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  List<TimeSlot> _slots = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final slots = await ApiService.getTimeSlots();
      if (mounted) {
        setState(() {
          _slots = slots;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _addSlot() async {
    final result = await showDialog<_SlotDraft>(
      context: context,
      builder: (context) => _AddSlotDialog(days: _days),
    );
    if (result == null) return;

    setState(() {
      _slots.add(TimeSlot(day: result.day, date: result.date, startTime: result.startTime, endTime: result.endTime));
    });
  }

  void _addQuickShift(String shiftName, String startTime, String endTime) {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
    setState(() {
      for (final day in weekdays) {
        if (!_slots.any((s) => s.day == day && s.startTime == startTime && s.endTime == endTime)) {
          _slots.add(TimeSlot(day: day, startTime: startTime, endTime: endTime));
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $shiftName for Mon-Fri. Tap "Save Time Slots" to persist.')),
    );
  }

  Future<void> _removeSlot(int index) async {
    setState(() => _slots.removeAt(index));
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ApiService.setTimeSlots(_slots.map((s) => s.toJson()).toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Time slots saved successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Time Slots')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlot,
        icon: const Icon(Icons.add),
        label: const Text('Add Slot'),
      ),
      body: _loading && _slots.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _slots.isEmpty
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Set your available days and time slots so patients can book appointments.',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            avatar: const Icon(Icons.wb_sunny_outlined, size: 16),
                            label: const Text('Morning Shift (09:00 - 13:00)'),
                            onPressed: () => _addQuickShift('Morning Shift', '09:00', '13:00'),
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.nights_stay_outlined, size: 16),
                            label: const Text('Evening Shift (16:00 - 20:00)'),
                            onPressed: () => _addQuickShift('Evening Shift', '16:00', '20:00'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_slots.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('No time slots set yet. Tap + Add Slot to configure availability.',
                              style: TextStyle(color: Colors.black54)),
                        ),
                      ),
                    ..._slots.asMap().entries.map((entry) {
                      final slot = entry.value;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.schedule, color: Colors.teal),
                          ),
                          title: Text(
                            slot.date != null && slot.date!.isNotEmpty
                                ? '${slot.day} (${slot.date})'
                                : slot.day,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${slot.startTime} - ${slot.endTime}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeSlot(entry.key),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('Save Time Slots', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }
}

class _SlotDraft {
  final String day;
  final String? date;
  final String startTime;
  final String endTime;
  _SlotDraft({required this.day, this.date, required this.startTime, required this.endTime});
}

class _AddSlotDialog extends StatefulWidget {
  final List<String> days;
  const _AddSlotDialog({required this.days});

  @override
  State<_AddSlotDialog> createState() => _AddSlotDialogState();
}

class _AddSlotDialogState extends State<_AddSlotDialog> {
  String? _day;
  DateTime? _date;
  TimeOfDay? _start;
  TimeOfDay? _end;

  Future<void> _pickTime(bool isStart) async {
    final initial = isStart ? (_start ?? const TimeOfDay(hour: 9, minute: 0)) : (_end ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? t) => t == null ? 'Select' : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Available Time Slot'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _day,
              decoration: const InputDecoration(labelText: 'Day of Week', prefixIcon: Icon(Icons.calendar_today)),
              items: widget.days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
              onChanged: (v) => setState(() => _day = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start Time'),
                    subtitle: Text(_formatTime(_start)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(true),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('End Time'),
                    subtitle: Text(_formatTime(_end)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            if (_day == null || _start == null || _end == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select day, start time and end time')),
              );
              return;
            }
            final startM = _start!.hour * 60 + _start!.minute;
            final endM = _end!.hour * 60 + _end!.minute;
            if (endM <= startM) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time')),
              );
              return;
            }
            Navigator.pop(
              context,
              _SlotDraft(
                day: _day!,
                date: _date != null ? '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}' : null,
                startTime: _formatTime(_start!),
                endTime: _formatTime(_end!),
              ),
            );
          },
          child: const Text('Add Slot'),
        ),
      ],
    );
  }
}
