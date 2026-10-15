import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/status_chip.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() => _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen> {
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
      final appointments = await ApiService.getDoctorAppointments();
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

  Future<void> _updateStatus(Appointment appointment, String status) async {
    try {
      await ApiService.updateAppointmentStatus(appointment.id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment ${status}')),
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
      appBar: AppBar(title: const Text('Appointments')),
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
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.teal.shade100,
                  child: const Icon(Icons.person, color: Colors.teal),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appointment.patientName ?? 'Patient',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(appointment.patientEmail ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    ],
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
                Text('${date.day}/${date.month}/${date.year}', style: TextStyle(color: Colors.grey.shade700)),
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
            if (appointment.status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _updateStatus(appointment, 'rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _updateStatus(appointment, 'accepted'),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                ],
              )
            else if (appointment.status == 'accepted')
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(appointment, 'completed'),
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Mark Completed'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
