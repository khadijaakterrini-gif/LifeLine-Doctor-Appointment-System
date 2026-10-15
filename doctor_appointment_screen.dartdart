import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/booking_success_dialog.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;
  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late Doctor _doctor;
  bool _loadingDoctor = true;
  DateTime? _selectedDate;
  String? _selectedTime;
  final _reasonController = TextEditingController();
  bool _booking = false;

  static const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _doctor = widget.doctor;
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    try {
      final updatedDoctor = await ApiService.getDoctorDetails(widget.doctor.userId);
      if (mounted) {
        setState(() {
          _doctor = updatedDoctor;
          _loadingDoctor = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDoctor = false);
    }
  }

  Set<int> get _availableWeekdays {
    return _doctor.timeSlots.map((s) => _days.indexOf(s.day) + 1).where((d) => d >= 1).toSet();
  }

  List<String> get _availableTimes {
    if (_selectedDate == null) return [];
    final dayName = _days[_selectedDate!.weekday - 1];
    final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

    final slots = _doctor.timeSlots.where((s) => s.day == dayName || (s.date != null && s.date == dateStr));
    final times = <String>{};
    for (final slot in slots) {
      final start = _toMinutes(slot.startTime);
      final end = _toMinutes(slot.endTime);
      for (var m = start; m < end; m += 30) {
        times.add(_fromMinutes(m));
      }
    }
    return times.toList()..sort();
  }

  static int _toMinutes(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static String _fromMinutes(int m) {
    final h = (m ~/ 60).toString().padLeft(2, '0');
    final min = (m % 60).toString().padLeft(2, '0');
    return '$h:$min';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final availableDays = _availableWeekdays;
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      selectableDayPredicate: (day) => availableDays.isEmpty || availableDays.contains(day.weekday),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
    }
  }

  Future<void> _book() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() => _booking = true);
    try {
      await ApiService.bookAppointment(
        doctorId: _doctor.userId,
        date: _selectedDate!,
        time: _selectedTime!,
        reason: _reasonController.text,
      );
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => BookingSuccessDialog(
            doctor: _doctor,
            date: _selectedDate!,
            time: _selectedTime!,
          ),
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: _loadingDoctor
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.medical_services, color: Colors.teal),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Dr. ${_doctor.name}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(_doctor.specialty ?? 'General Practitioner',
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_doctor.timeSlots.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: const Text(
                        'This doctor has not set any available time slots yet. Please check back later.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('Select Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.blue),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDate == null
                                ? 'Choose a date'
                                : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                                    '(${_weekdayName(_selectedDate!)})',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Select Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (_doctor.timeSlots.isEmpty)
                    const Text('This doctor has not set any time slots yet.', style: TextStyle(color: Colors.red))
                  else if (_selectedDate == null)
                    const Text('Select a date first to see available times (only days with availability are enabled)', style: TextStyle(color: Colors.black54))
                  else if (_availableTimes.isEmpty)
                    const Text('No time slots available on this day', style: TextStyle(color: Colors.black54))
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableTimes.map((time) {
                        final selected = _selectedTime == time;
                        return ChoiceChip(
                          label: Text(time),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedTime = time),
                          selectedColor: Colors.blue.shade100,
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  const Text('Reason for Visit (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Describe your symptoms or reason for visit...'),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: _booking
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _book,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  String _weekdayName(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}
