import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_time_slots_screen.dart';
import 'edit_doctor_profile_screen.dart';
import '../services/api_service.dart';
import '../widgets/life_line_logo.dart';

class DoctorDashboard extends StatefulWidget {
  final String email;
  final String? name;
  const DoctorDashboard({super.key, required this.email, this.name});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([ApiService.getDoctorStats(), ApiService.getDoctorProfile()]);
      if (mounted) {
        setState(() {
          _stats = results[0];
          _profile = results[1];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _openNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
  }

  String get _displayName {
    final profileName = _profile?['name'] ?? widget.name;
    if (profileName != null && profileName.toString().trim().isNotEmpty) {
      final raw = profileName.toString().trim();
      if (raw.toLowerCase().startsWith('dr.')) return raw;
      return 'Dr. $raw';
    }
    final emailPrefix = widget.email.split('@').first;
    return 'Dr. ${emailPrefix[0].toUpperCase()}${emailPrefix.substring(1)}';
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Welcome, $_displayName',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: _openNotifications,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Here is your daily overview', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today\'s Appointments',
                      '${_stats?['todayAppointments'] ?? 0}',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      '${_stats?['pendingAppointments'] ?? 0}',
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Accepted',
                      '${_stats?['acceptedAppointments'] ?? 0}',
                      Icons.check_circle_outline,
                      Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Completed',
                      '${_stats?['completedAppointments'] ?? 0}',
                      Icons.task_alt,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatCard(
                'Total Patients',
                '${_stats?['totalPatients'] ?? 0}',
                Icons.people,
                Colors.purple,
              ),
            ],
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildActionCard(
            Icons.event_note,
            'View Appointments',
            'Accept, reject or complete appointment requests',
            Colors.blue,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorAppointmentsScreen()));
            },
          ),
          _buildActionCard(
            Icons.schedule,
            'Manage Time Slots',
            'Set your weekly availability for bookings',
            Colors.teal,
            () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const DoctorTimeSlotsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildScheduleTab() {
    return const DoctorAppointmentsScreen();
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 16),
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.teal,
          child: Icon(Icons.medical_services, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            _displayName,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            _profile?['specialty'] ?? '',
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const SizedBox(height: 4),
        Center(child: Text(widget.email, style: const TextStyle(color: Colors.black54))),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _profileRow(Icons.star, 'Rating', _profile?['rating'] != null ? (_profile!['rating'] as num).toStringAsFixed(1) : '0.0'),
              const Divider(height: 1),
              _profileRow(Icons.location_on_outlined, 'Location', _profile?['location'] ?? 'Not set'),
              const Divider(height: 1),
              _profileRow(Icons.phone_outlined, 'Phone', _profile?['phone'] ?? 'Not set'),
              const Divider(height: 1),
              _profileRow(Icons.badge_outlined, 'License', _profile?['licenseNumber'] ?? 'Not set'),
              const Divider(height: 1),
              _profileRow(Icons.work_outline, 'Experience', _profile?['experienceYears'] != null ? '${_profile!['experienceYears']} years' : 'Not set'),
              const Divider(height: 1),
              _profileRow(Icons.attach_money, 'Consultation Fee', _profile?['consultationFee'] != null ? '\$${_profile!['consultationFee']}' : 'Not set'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditDoctorProfileScreen(profile: _profile ?? {})),
            );
            if (mounted) _load();
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profile'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_buildHomeTab(), _buildScheduleTab(), _buildProfileTab()];
    final titles = ['Overview', 'Appointments', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LifeLineLogo(size: 26, showText: false),
            const SizedBox(width: 8),
            Text(titles[_selectedIndex]),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(child: tabs[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
