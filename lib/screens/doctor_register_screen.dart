import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _specialization = TextEditingController(text: 'General Physician');
  final _qualifications = TextEditingController();
  final _experience = TextEditingController();
  final _hospital = TextEditingController();
  final _consultationFee = TextEditingController(text: '500');
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final List<String> _allDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  final Set<String> _selectedDays = {
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  };

  final List<String> _allSlots = [
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
    '05:00 PM',
  ];
  final Set<String> _selectedSlots = {
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:00 PM',
  };

  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Dermatologist',
    'Dentist',
    'Pediatrician',
    'Orthopedic',
    'Gynecologist',
    'Neurologist',
    'ENT Specialist',
    'Psychiatrist',
  ];

  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  static const Color teal = Color(0xFF0E9F9A);

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _specialization.dispose();
    _qualifications.dispose();
    _experience.dispose();
    _hospital.dispose();
    _consultationFee.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : teal,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.isEmpty) {
      _showMessage('Please select at least one available day', isError: true);
      return;
    }

    if (_selectedSlots.isEmpty) {
      _showMessage('Please select at least one available time slot',
          isError: true);
      return;
    }

    setState(() => _loading = true);

    User? newUser;

    try {
      final emailClean = _email.text.trim().toLowerCase();
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailClean,
        password: _password.text,
      );

      newUser = credential.user;

      if (newUser == null) {
        throw Exception('Firebase authentication did not return a user account.');
      }

      final docData = {
        'uid': newUser.uid,
        'name': _name.text.trim(),
        'email': emailClean,
        'phone': _phone.text.trim(),
        'specialization': _specialization.text.trim(),
        'qualifications': _qualifications.text.trim().isNotEmpty
            ? _qualifications.text.trim()
            : 'MBBS',
        'experience': _experience.text.trim().contains('Year')
            ? _experience.text.trim()
            : '${_experience.text.trim()} Years',
        'hospital': _hospital.text.trim(),
        'consultationFee': _consultationFee.text.trim(),
        'availableDays': _selectedDays.toList(),
        'availableTimeSlots': _selectedSlots.toList(),
        'role': 'doctor',
        'approvalStatus': 'pending',
        'rating': 5.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 1. Save doctor profile under users/{uid}
      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUser.uid)
          .set(docData, SetOptions(merge: true));

      // 2. Link or create corresponding record in 'doctors' collection
      final existingDoctorQuery = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: emailClean)
          .limit(1)
          .get();

      if (existingDoctorQuery.docs.isNotEmpty) {
        // Link to existing document (e.g. from bulk import)
        await existingDoctorQuery.docs.first.reference.set({
          'uid': newUser.uid,
          'name': _name.text.trim(),
          'email': emailClean,
          'phone': _phone.text.trim(),
          'specialization': _specialization.text.trim(),
          'qualifications': _qualifications.text.trim().isNotEmpty
              ? _qualifications.text.trim()
              : 'MBBS',
          'experience': _experience.text.trim().contains('Year')
              ? _experience.text.trim()
              : '${_experience.text.trim()} Years',
          'hospital': _hospital.text.trim(),
          'consultationFee': _consultationFee.text.trim(),
          'availableDays': _selectedDays.toList(),
          'availableTimeSlots': _selectedSlots.toList(),
          'approvalStatus': 'pending',
        }, SetOptions(merge: true));
      } else {
        // Create new document in doctors collection with doc ID = newUser.uid
        await FirebaseFirestore.instance
            .collection('doctors')
            .doc(newUser.uid)
            .set(docData, SetOptions(merge: true));
      }

      await newUser.updateDisplayName(_name.text.trim());

      // Sign out unapproved doctor immediately
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.access_time_filled,
            color: Colors.orange,
            size: 55,
          ),
          title: const Text(
            'Registration Submitted',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Your doctor account has been submitted for administrator verification.\n\n'
            'Your account is awaiting administrator approval. You will be able to log in to the doctor dashboard once approved.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Doctor registration failed.';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already registered in the system.';
      } else if (e.code == 'weak-password') {
        msg = 'Please choose a password with at least 6 characters.';
      } else if (e.message != null) {
        msg = e.message!;
      }
      _showMessage(msg, isError: true);
    } catch (e) {
      _showMessage('Registration failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator ??
          (value) => value == null || value.trim().isEmpty
              ? 'Please enter $label'
              : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: teal),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: teal, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text(
          'Doctor Registration',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5FAFA),
        foregroundColor: teal,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Color(0xFFE0F5F4),
                        child: Icon(
                          Icons.medical_services_rounded,
                          color: teal,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Join MediCare as a Doctor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF203333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register your professional credentials for administrator verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 24),

                    // Full Name
                    _field(
                      controller: _name,
                      label: 'Doctor Full Name (e.g. Dr. John Doe)',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 14),

                    // Email Address
                    _field(
                      controller: _email,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                .hasMatch(value.trim())) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // 10-digit Phone
                    _field(
                      controller: _phone,
                      label: '10-digit Phone Number (for WhatsApp/Calls)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                          return 'Enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Specialization Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _specialization.text,
                      decoration: InputDecoration(
                        labelText: 'Specialization',
                        prefixIcon: const Icon(
                          Icons.health_and_safety_outlined,
                          color: teal,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      items: _specializations
                          .map((spec) => DropdownMenuItem(
                                value: spec,
                                child: Text(spec),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _specialization.text = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Qualifications
                    _field(
                      controller: _qualifications,
                      label: 'Qualifications (e.g. MBBS, MD, MS, BDS)',
                      icon: Icons.school_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your medical qualifications';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Years of experience
                    _field(
                      controller: _experience,
                      label: 'Years of Experience (e.g. 8)',
                      icon: Icons.work_outline,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value?.trim() ?? '');
                        if (parsed == null || parsed < 0 || parsed > 70) {
                          return 'Enter a valid number of years';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Hospital or Clinic
                    _field(
                      controller: _hospital,
                      label: 'Hospital or Clinic Name',
                      icon: Icons.local_hospital_outlined,
                    ),
                    const SizedBox(height: 14),

                    // Consultation Fee
                    _field(
                      controller: _consultationFee,
                      label: 'Consultation Fee (₹)',
                      icon: Icons.currency_rupee,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final fee = int.tryParse(value?.trim() ?? '');
                        if (fee == null || fee <= 0) {
                          return 'Enter a valid consultation fee';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Available Days Section
                    const Text(
                      'Available Days',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF203333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _allDays.map((day) {
                        final isSelected = _selectedDays.contains(day);
                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          selectedColor: teal.withValues(alpha: 0.2),
                          checkmarkColor: teal,
                          labelStyle: TextStyle(
                            color: isSelected ? teal : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDays.add(day);
                              } else {
                                _selectedDays.remove(day);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Available Time Slots Section
                    const Text(
                      'Available Time Slots',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF203333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _allSlots.map((slot) {
                        final isSelected = _selectedSlots.contains(slot);
                        return FilterChip(
                          label: Text(slot),
                          selected: isSelected,
                          selectedColor: teal.withValues(alpha: 0.2),
                          checkmarkColor: teal,
                          labelStyle: TextStyle(
                            color: isSelected ? teal : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSlots.add(slot);
                              } else {
                                _selectedSlots.remove(slot);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Password
                    _field(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _hidePassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _hidePassword = !_hidePassword);
                        },
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    _field(
                      controller: _confirmPassword,
                      label: 'Confirm Password',
                      icon: Icons.lock_reset_outlined,
                      obscure: _hideConfirmPassword,
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(
                            () =>
                                _hideConfirmPassword = !_hideConfirmPassword,
                          );
                        },
                        icon: Icon(
                          _hideConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'SUBMIT DOCTOR REGISTRATION',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Doctor accounts require administrator approval before logging in to the dashboard.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B5800),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
