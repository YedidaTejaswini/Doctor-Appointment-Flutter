
import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';
import 'doctor_register_screen.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  static const Color teal = Color(0xFF0E9F9A);
  static const Color purple = Color(0xFF6658B5);
  static const Color background = Color(0xFFF5FAFA);

  void _openLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LoginScreen(expectedRole: role),
      ),
    );
  }

  void _openPatientRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  void _openDoctorRegistration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorRegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF5FAFA),
                Color(0xFFE8F6F4),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 760;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 48,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 950,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.local_hospital_rounded,
                              size: 76,
                              color: teal,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'MediCare',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF203333),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Your health, our priority',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'Welcome!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF203333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Choose your login type to continue.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (isWide)
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _buildCard(
                                      icon: Icons.person_outline_rounded,
                                      title: 'Patient Portal',
                                      description:
                                          'Book doctor appointments, track your healthcare visits, and manage your patient profile.',
                                      color: teal,
                                      buttonText: 'Patient Login',
                                      onPressed: () =>
                                          _openLogin(context, 'patient'),
                                      secondaryText:
                                          'New Patient? Register Account',
                                      onSecondaryPressed: () =>
                                          _openPatientRegistration(context),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildCard(
                                      icon: Icons.admin_panel_settings_rounded,
                                      title: 'Hospital Admin',
                                      description:
                                          'Review appointments and approve or reject booking requests.',
                                      color: const Color(0xFFB85C38),
                                      buttonText: 'Admin Login',
                                      onPressed: () =>
                                          _openLogin(context, 'hospitalAdmin'),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildCard(
                                      icon: Icons.medical_services_outlined,
                                      title: 'Doctor Portal',
                                      description:
                                          'For medical practitioners to manage assigned appointments, consult patients, and update schedules.',
                                      color: purple,
                                      buttonText: 'Doctor Login',
                                      onPressed: () =>
                                          _openLogin(context, 'doctor'),
                                      secondaryText:
                                          'New Doctor? Register for Approval',
                                      onSecondaryPressed: () =>
                                          _openDoctorRegistration(context),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  _buildCard(
                                    icon: Icons.person_outline_rounded,
                                    title: 'Patient Portal',
                                    description:
                                        'Book appointments and manage your health profile.',
                                    color: teal,
                                    buttonText: 'Patient Login',
                                    onPressed: () =>
                                        _openLogin(context, 'patient'),
                                    secondaryText:
                                        'New Patient? Register Account',
                                    onSecondaryPressed: () =>
                                        _openPatientRegistration(context),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildCard(
                                    icon: Icons.admin_panel_settings_rounded,
                                    title: 'Hospital Admin',
                                    description:
                                        'Review appointments and approve or reject booking requests.',
                                    color: const Color(0xFFB85C38),
                                    buttonText: 'Admin Login',
                                    onPressed: () =>
                                        _openLogin(context, 'hospitalAdmin'),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildCard(
                                    icon: Icons.medical_services_outlined,
                                    title: 'Doctor Portal',
                                    description:
                                        'Manage appointments and patient consultations.',
                                    color: purple,
                                    buttonText: 'Doctor Login',
                                    onPressed: () =>
                                        _openLogin(context, 'doctor'),
                                    secondaryText:
                                        'New Doctor? Register for Approval',
                                    onSecondaryPressed: () =>
                                        _openDoctorRegistration(context),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 28),
                            const Text(
                              'Secure access for patients, doctors, and hospital administrators',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String buttonText,
    required VoidCallback onPressed,
    String? secondaryText,
    VoidCallback? onSecondaryPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 52, color: color),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF203333),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              height: 1.5,
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (secondaryText != null &&
              onSecondaryPressed != null) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: onSecondaryPressed,
              child: Text(
                secondaryText,
                textAlign: TextAlign.center,
                style: TextStyle(color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
