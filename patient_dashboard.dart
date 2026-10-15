import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'search_doctors_screen.dart';
import 'doctor_detail_screen.dart';
import 'patient_appointments_screen.dart';
import 'edit_patient_profile_screen.dart';
import 'notifications_screen.dart';
import 'symptom_checker_screen.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/life_line_logo.dart';

class PatientDashboard extends StatefulWidget {
  final String email;
  final String? name;
  const PatientDashboard({super.key, required this.email, this.name});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard> {
  int _selectedIndex = 0;
  final _searchController = TextEditingController();
  List<Doctor>? _topDoctors;
  bool _loadingDoctors = true;

  final List<({String name, IconData icon, Color color})> _categories = [
    (name: 'Cardiology', icon: Icons.favorite, color: Colors.red),
    (name: 'Ophthalmology', icon: Icons.remove_red_eye, color: Colors.blue),
    (name: 'Dermatology', icon: Icons.face, color: Colors.orange),
    (name: 'Pediatrics', icon: Icons.child_care, color: Colors.green),
    (name: 'Neurology', icon: Icons.psychology, color: Colors.purple),
    (name: 'Orthopedics', icon: Icons.accessibility_new, color: Colors.brown),
    (name: 'Dentistry', icon: Icons.medical_services, color: Colors.teal),
  ];

  String? _patientName;

  @override
  void initState() {
    super.initState();
    _patientName = widget.name;
    _loadTopDoctors();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    try {
      final p = await ApiService.getPatientProfile();
      if (mounted && p['name'] != null && (p['name'] as String).isNotEmpty) {
        setState(() {
          _patientName = p['name'];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopDoctors() async {
    try {
      final doctors = await ApiService.searchDoctors();
      if (mounted) {
        setState(() {
          _topDoctors = doctors.take(5).toList();
          _loadingDoctors = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingDoctors = false);
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

  void _openSearch({String? query, String? specialty}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchDoctorsScreen(initialQuery: query, initialSpecialty: specialty),
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
  }

  void _openSymptomChecker() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SymptomCheckerScreen()));
  }

  Widget _buildHomeTab() {
    final nameToDisplay = _patientName ?? widget.email.split('@').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hello, $nameToDisplay',
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
          const Text('How are you feeling today?', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 16),

          // AI Symptom Checker Banner
          InkWell(
            onTap: _openSymptomChecker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0077B6), Color(0xFF00A896)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0077B6).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Symptom Recommendation',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enter symptoms to get ML-predicted doctor recommendation',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _openSearch(),
            borderRadius: BorderRadius.circular(12),
            child: AbsorbPointer(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for doctors, specialties, locations...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return InkWell(
                  onTap: () => _openSearch(specialty: category.name),
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(category.icon, color: category.color, size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Doctors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () => _openSearch(),
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingDoctors)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_topDoctors == null || _topDoctors!.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No doctors available yet', style: TextStyle(color: Colors.black54))),
            )
          else
            ..._topDoctors!.map((doctor) => _buildDoctorCard(context, doctor)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, Doctor doctor) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorDetailScreen(doctorId: doctor.userId)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person, color: Colors.blue, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dr. ${doctor.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(doctor.specialty ?? 'General Practitioner', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  const SizedBox(width: 4),
                  Text(doctor.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    return const PatientAppointmentsScreen();
  }

  Widget _buildProfileTab() {
    return FutureBuilder(
      future: ApiService.getPatientProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data ?? {};
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                profile['name'] ?? widget.email,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                  _profileRow(Icons.phone_outlined, 'Phone', profile['phone'] ?? 'Not set'),
                  const Divider(height: 1),
                  _profileRow(Icons.cake_outlined, 'Date of Birth', profile['dob'] ?? 'Not set'),
                  const Divider(height: 1),
                  _profileRow(Icons.wc_outlined, 'Gender', profile['gender'] ?? 'Not set'),
                  const Divider(height: 1),
                  _profileRow(Icons.home_outlined, 'Address', profile['address'] ?? 'Not set'),
                  const Divider(height: 1),
                  _profileRow(Icons.healing_outlined, 'Symptoms', profile['symptoms'] ?? 'Not set'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPatientProfileScreen(profile: profile),
                  ),
                );
                if (mounted) setState(() {});
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
      },
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [_buildHomeTab(), _buildAppointmentsTab(), _buildProfileTab()];
    final titles = ['Home', 'Appointments', 'Profile'];

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
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
