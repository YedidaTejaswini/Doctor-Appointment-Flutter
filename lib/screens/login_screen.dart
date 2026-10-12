
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'doctor_dashboard_screen.dart';
import 'hospital_admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final String expectedRole;

  const LoginScreen({
    super.key,
    required this.expectedRole,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  static const Color teal = Color(0xFF0E9F9A);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Unable to sign in. Please try again.');
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      Map<String, dynamic>? data = userDoc.data();
      String? role = data?['role']?.toString().toLowerCase();

      // Support linking legacy/imported doctor records where users doc might be missing
      if (!userDoc.exists && widget.expectedRole == 'doctor') {
        final doctorQuery = await FirebaseFirestore.instance
            .collection('doctors')
            .where('email', isEqualTo: user.email?.toLowerCase())
            .limit(1)
            .get();

        if (doctorQuery.docs.isNotEmpty) {
          final docData = doctorQuery.docs.first.data();
          role = 'doctor';
          final approvalStatus =
              docData['approvalStatus']?.toString().toLowerCase() ?? 'approved';
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'uid': user.uid,
            'name': docData['name'] ?? user.displayName ?? 'Doctor',
            'email': user.email ?? '',
            'role': 'doctor',
            'approvalStatus': approvalStatus,
            'specialization': docData['specialization'] ?? 'General Physician',
            'hospital': docData['hospital'] ?? 'MediCare Hospital',
            'experience': docData['experience'] ?? '',
          }, SetOptions(merge: true));

          await doctorQuery.docs.first.reference.set({
            'uid': user.uid,
          }, SetOptions(merge: true));

          data = {
            'role': 'doctor',
            'approvalStatus': approvalStatus,
          };
        }
      }

      if (data == null || role == null) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account profile not found. Please register first.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (role != widget.expectedRole.toLowerCase()) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        final message = switch (widget.expectedRole) {
          'doctor' => 'This account is not registered as a doctor.',
          'hospitalAdmin' => 'This account is not registered as a Hospital Admin.',
          _ => 'This account is not registered as a patient.',
        };

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check doctor approval status
      if (role == 'doctor') {
        final approvalStatus =
            data['approvalStatus']?.toString().toLowerCase();
        if (approvalStatus != 'approved') {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your account is awaiting administrator approval. You will be able to log in once an administrator approves your account.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
          return;
        }
      }

      if (!mounted) return;

      final Widget destination = switch (role) {
        'doctor' => const DoctorDashboardScreen(),
        'hospitaladmin' => const HospitalAdminDashboardScreen(),
        _ => const HomeScreen(),
      };
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'Login failed. Please try again.';

      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firebase denied access. Check Firestore security rules.'
                : 'Unable to check account role: ${e.message ?? e.code}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.expectedRole == 'doctor';
    final isAdmin = widget.expectedRole == 'hospitalAdmin';

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: Text(isAdmin ? 'Hospital Admin Login' : isDoctor ? 'Doctor Login' : 'Patient Login'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  isAdmin ? Icons.admin_panel_settings : isDoctor ? Icons.medical_services : Icons.person,
                  size: 75,
                  color: teal,
                ),
                const SizedBox(height: 18),
                Text(
                  isAdmin ? 'Welcome, Hospital Admin' : isDoctor ? 'Welcome, Doctor' : 'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? 'Sign in with your Hospital Admin account'
                      : isDoctor
                          ? 'Sign in with your approved doctor account'
                          : 'Login to manage your health appointments',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() => hidePassword = !hidePassword);
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = emailController.text.trim();

                      if (email.isEmpty || !email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter your email first to reset your password.',
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        await FirebaseAuth.instance
                            .sendPasswordResetEmail(email: email);

                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Password reset email sent.'),
                          ),
                        );
                      } on FirebaseAuthException catch (e) {
                        if (!context.mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.message ?? 'Unable to reset password.'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: teal),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: loading ? null : login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: teal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            height: 23,
                            width: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
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
