import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'book_appointment_screen.dart';
import 'rate_review_screen.dart';

class DoctorDetailScreen extends StatefulWidget {
  final int doctorId;
  const DoctorDetailScreen({super.key, required this.doctorId});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  Doctor? _doctor;
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
      final doctor = await ApiService.getDoctorDetails(widget.doctorId);
      if (mounted) {
        setState(() {
          _doctor = doctor;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final doctor = _doctor!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(doctor),
                const SizedBox(height: 16),
                if (doctor.bio != null && doctor.bio!.isNotEmpty) _buildSection('About', Text(doctor.bio!)),
                const SizedBox(height: 16),
                _buildSection('Available Time Slots', _buildTimeSlots(doctor)),
                const SizedBox(height: 16),
                _buildSection('Reviews (${doctor.reviews.length})', _buildReviews(doctor)),
              ],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookAppointmentScreen(doctor: doctor),
                    ),
                  );
                },
                icon: const Icon(Icons.event_available),
                label: const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(Doctor doctor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Colors.teal.shade100,
          child: const Icon(Icons.medical_services, color: Colors.teal, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dr. ${doctor.name}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(doctor.specialty ?? 'General Practitioner', style: const TextStyle(color: Colors.black54, fontSize: 16)),
              if (doctor.location != null && doctor.location!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        doctor.location!,
                        style: const TextStyle(color: Colors.black54, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${doctor.rating.toStringAsFixed(1)} (${doctor.reviewCount} reviews)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildTimeSlots(Doctor doctor) {
    if (doctor.timeSlots.isEmpty) {
      return const Text('No time slots available yet', style: TextStyle(color: Colors.black54));
    }

    final byDay = <String, List<TimeSlot>>{};
    for (final slot in doctor.timeSlots) {
      byDay.putIfAbsent(slot.day, () => []).add(slot);
    }

    return Column(
      children: byDay.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 90,
                child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.value
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text('${s.startTime} - ${s.endTime}',
                                style: TextStyle(color: Colors.blue.shade900, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviews(Doctor doctor) {
    if (doctor.reviews.isEmpty) {
      return const Text('No reviews yet. Be the first to rate this doctor!', style: TextStyle(color: Colors.black54));
    }

    return Column(
      children: [
        ...doctor.reviews.map((r) => _buildReviewCard(r)),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RateReviewScreen(doctorId: doctor.userId, doctorName: doctor.name),
                ),
              );
            },
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Rate this doctor'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(review.patientName ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.orange,
                    size: 16,
                  )),
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(review.comment!, style: const TextStyle(color: Colors.black54)),
            ],
          ],
        ),
      ),
    );
  }
}
