import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/life_line_logo.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _licenseController = TextEditingController();
  final _experienceController = TextEditingController();
  final _locationController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _areaController = TextEditingController(text: 'Mirpur');
  final _feeController = TextEditingController(text: '1000');
  bool _isLoading = false;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await ApiService.register(
          role: widget.role,
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phone: _phoneController.text.isNotEmpty
              ? _phoneController.text
              : null,
          dob: widget.role == 'patient' && _dobController.text.isNotEmpty
              ? _dobController.text
              : null,
          gender: widget.role == 'patient' && _genderController.text.isNotEmpty
              ? _genderController.text
              : null,
          symptoms:
              widget.role == 'patient' && _symptomsController.text.isNotEmpty
              ? _symptomsController.text
              : null,
          specialty:
              widget.role == 'doctor' && _specialtyController.text.isNotEmpty
              ? _specialtyController.text
              : null,
          licenseNumber:
              widget.role == 'doctor' && _licenseController.text.isNotEmpty
              ? _licenseController.text
              : null,
          experienceYears: widget.role == 'doctor'
              ? int.tryParse(_experienceController.text)
              : null,
          location: widget.role == 'doctor' && _locationController.text.isNotEmpty
              ? _locationController.text
              : null,
          hospital: widget.role == 'doctor' && _hospitalController.text.isNotEmpty
              ? _hospitalController.text
              : null,
          area: widget.role == 'doctor' && _areaController.text.isNotEmpty
              ? _areaController.text
              : null,
          consultationFee: widget.role == 'doctor'
              ? double.tryParse(_feeController.text)
              : null,
        );

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(email: _emailController.text),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _specialtyController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    _symptomsController.dispose();
    _licenseController.dispose();
    _experienceController.dispose();
    _locationController.dispose();
    _hospitalController.dispose();
    _areaController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: LifeLineLogo(horizontal: true, size: 48)),
                const SizedBox(height: 24),
                Text(
                  'Register as a ${widget.role == 'patient' ? 'Patient' : 'Doctor'}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in your details below to get started.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) => value!.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value!.isEmpty ? 'Enter your phone number' : null,
                ),
                const SizedBox(height: 16),
                if (widget.role == 'patient') ...[
                  TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        _dobController.text =
                            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Select your date of birth' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      prefixIcon: Icon(Icons.person_pin_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _genderController.text = value;
                      }
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Select your gender'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'Current Symptoms / Reason for Visit',
                      prefixIcon: Icon(Icons.medical_information_outlined),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your symptoms' : null,
                  ),
                ],
                if (widget.role == 'doctor') ...[
                  DropdownButtonFormField<String>(
                    initialValue: _specialtyController.text.isNotEmpty ? _specialtyController.text : 'General Physician',
                    decoration: const InputDecoration(
                      labelText: 'Specialty',
                      prefixIcon: Icon(Icons.work_outline),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'General Physician', child: Text('General Physician')),
                      DropdownMenuItem(value: 'Medicine Specialist', child: Text('Medicine Specialist')),
                      DropdownMenuItem(value: 'Cardiologist', child: Text('Cardiologist')),
                      DropdownMenuItem(value: 'Neurologist', child: Text('Neurologist')),
                      DropdownMenuItem(value: 'Dermatologist', child: Text('Dermatologist')),
                      DropdownMenuItem(value: 'Ophthalmologist', child: Text('Ophthalmologist')),
                      DropdownMenuItem(value: 'ENT Specialist', child: Text('ENT Specialist')),
                      DropdownMenuItem(value: 'Orthopedic Specialist', child: Text('Orthopedic Specialist')),
                      DropdownMenuItem(value: 'Gynecologist', child: Text('Gynecologist')),
                      DropdownMenuItem(value: 'Pediatrician', child: Text('Pediatrician')),
                      DropdownMenuItem(value: 'Dentist', child: Text('Dentist')),
                      DropdownMenuItem(value: 'Psychiatrist', child: Text('Psychiatrist')),
                      DropdownMenuItem(value: 'Gastroenterologist', child: Text('Gastroenterologist')),
                      DropdownMenuItem(value: 'Urologist', child: Text('Urologist')),
                    ],
                    onChanged: (val) {
                      if (val != null) _specialtyController.text = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _hospitalController,
                    decoration: const InputDecoration(
                      labelText: 'Hospital / Clinic Name',
                      hintText: 'e.g. Popular Diagnostic Center',
                      prefixIcon: Icon(Icons.local_hospital_outlined),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter hospital/clinic name' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _areaController.text,
                    decoration: const InputDecoration(
                      labelText: 'Area / Neighborhood',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Mirpur', child: Text('Mirpur')),
                      DropdownMenuItem(value: 'Uttara', child: Text('Uttara')),
                      DropdownMenuItem(value: 'Dhanmondi', child: Text('Dhanmondi')),
                      DropdownMenuItem(value: 'Mohammadpur', child: Text('Mohammadpur')),
                      DropdownMenuItem(value: 'Gulshan', child: Text('Gulshan')),
                      DropdownMenuItem(value: 'Banani', child: Text('Banani')),
                    ],
                    onChanged: (val) {
                      if (val != null) _areaController.text = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feeController,
                    decoration: const InputDecoration(
                      labelText: 'Consultation Fee (BDT)',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter consultation fee' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    decoration: const InputDecoration(
                      labelText: 'Medical License Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter your license number' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _experienceController,
                    decoration: const InputDecoration(
                      labelText: 'Years of Experience',
                      prefixIcon: Icon(Icons.timeline_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value!.isEmpty ? 'Enter years of experience' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Full Address (Optional)',
                      hintText: 'e.g. House 12, Road 5, Mirpur, Dhaka',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'REGISTER',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
