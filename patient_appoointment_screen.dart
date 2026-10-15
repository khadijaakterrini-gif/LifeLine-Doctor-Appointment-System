import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/status_chip.dart';
import 'doctor_detail_screen.dart';
import 'rate_review_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  List<Appointment>? _appointments;
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
      final appointments = await ApiService.getPatientAppointments();
      if (mounted) {
        setState(() {
          _appointments = appointments;
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

  Future<void> _cancel(Appointment appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text('Are you sure you want to cancel your appointment with Dr. ${appointment.doctorName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiService.cancelAppointment(appointment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_appointments!.isEmpty) {
      return const Center(child: Text('No appointments yet', style: TextStyle(color: Colors.black54)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _appointments!.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final appointment = _appointments![index];
        return _buildCard(context, appointment);
      },
    );
  }

  Widget _buildCard(BuildContext context, Appointment appointment) {
    final date = appointment.date;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorDetailScreen(doctorId: appointment.doctorId),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.medical_services, color: Colors.blue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. ${appointment.doctorName ?? 'Doctor'}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(appointment.doctorSpecialty ?? '',
                                  style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StatusChip(status: appointment.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text('${date.day}/${date.month}/${date.year}',
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(width: 16),
                Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(appointment.time, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
            if (appointment.reason != null && appointment.reason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: ${appointment.reason}', style: TextStyle(color: Colors.grey.shade700)),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appointment.status == 'pending' || appointment.status == 'accepted')
                  TextButton.icon(
                    onPressed: () => _cancel(appointment),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                if (appointment.status == 'completed')
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RateReviewScreen(
                            doctorId: appointment.doctorId,
                            doctorName: appointment.doctorName ?? 'Doctor',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Rate & Review'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
