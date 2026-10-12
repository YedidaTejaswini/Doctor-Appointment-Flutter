
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_selection_screen.dart';
import '../services/whatsapp_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color teal = Color(0xFF0E9F9A);
  static const Color background = Color(0xFFF5FAFA);

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginSelectionScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _resetPassword() async {
    final email = currentUser?.email;

    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email address found.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link sent to $email'),
          backgroundColor: teal,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Could not send the reset email.'),
        ),
      );
    }
  }

  Future<void> _editProfile(Map<String, dynamic> data) async {
    final user = currentUser;
    if (user == null) return;

    final nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final phoneController = TextEditingController(
      text: data['phone']?.toString() ?? '',
    );
    final addressController = TextEditingController(
      text: data['address']?.toString() ?? '',
    );

    String gender = data['gender']?.toString() ?? 'Not specified';
    String dateOfBirth = data['dateOfBirth']?.toString() ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Date of Birth',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: teal,
                      ),
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        dateOfBirth.isEmpty
                            ? 'Select Date of Birth'
                            : dateOfBirth,
                      ),
                      onPressed: () async {
                        DateTime initialDate = DateTime(2000, 1, 1);

                        try {
                          if (dateOfBirth.isNotEmpty) {
                            initialDate = DateTime.parse(dateOfBirth);
                          }
                        } catch (_) {}

                        final selectedDate = await showDatePicker(
                          context: dialogContext,
                          useRootNavigator: true,
                          initialDate: initialDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );

                        if (selectedDate != null) {
                          setDialogState(() {
                            dateOfBirth =
                                '${selectedDate.year}-'
                                '${selectedDate.month.toString().padLeft(2, '0')}-'
                                '${selectedDate.day.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: [
                        'Not specified',
                        'Male',
                        'Female',
                        'Other',
                      ].contains(gender)
                          ? gender
                          : 'Not specified',
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Not specified',
                          child: Text('Not specified'),
                        ),
                        DropdownMenuItem(
                          value: 'Male',
                          child: Text('Male'),
                        ),
                        DropdownMenuItem(
                          value: 'Female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => gender = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your full name.'),
                        ),
                      );
                      return;
                    }

                    final phone = phoneController.text.trim();
                    if (phone.isNotEmpty &&
                        !RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid 10-digit phone number.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'name': nameController.text.trim(),
                        'phone': phone,
                        'address': addressController.text.trim(),
                        'dateOfBirth': dateOfBirth,
                        'gender': gender,
                        'email': user.email ?? '',
                        'uid': user.uid,
                        'role': 'patient',
                      }, SetOptions(merge: true));

                      await user.updateDisplayName(
                        nameController.text.trim(),
                      );

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext, true);
                    } catch (e) {
                      if (!dialogContext.mounted) return;

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Could not update profile: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: teal,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: background,
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginSelectionScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Please Login'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: background,
        foregroundColor: teal,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load profile. Check your Firestore permissions.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: teal),
            );
          }

          final data = snapshot.data?.data() ?? <String, dynamic>{};
          final name = data['name']?.toString().trim().isNotEmpty == true
              ? data['name'].toString()
              : (user.displayName ?? 'Patient');
          final email = data['email']?.toString() ?? user.email ?? '';
          final phone = data['phone']?.toString() ?? '';
          final address = data['address']?.toString() ?? '';
          final dateOfBirth = data['dateOfBirth']?.toString() ?? '';
          final gender = data['gender']?.toString() ?? 'Not specified';

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: teal.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person,
                        size: 54,
                        color: teal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF203333),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Patient Account',
                        style: TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _editProfile(data),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(foregroundColor: teal),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _infoTile(Icons.person_outline, 'Full Name', name),
              _infoTile(Icons.email_outlined, 'Email', email),
              _infoTile(
                Icons.phone_outlined,
                'Phone Number',
                phone.isEmpty ? 'Not added' : phone,
              ),
              _infoTile(
                Icons.location_on_outlined,
                'Address',
                address.isEmpty ? 'Not added' : address,
              ),
              _infoTile(
                Icons.calendar_month_outlined,
                'Date of Birth',
                dateOfBirth.isEmpty ? 'Not added' : dateOfBirth,
              ),
              _infoTile(Icons.person_search_outlined, 'Gender', gender),
              const SizedBox(height: 22),
              const Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.lock_reset, color: teal),
                  title: const Text('Reset Password'),
                  subtitle: const Text('Receive a reset link by email'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _resetPassword,
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                  title: const Text('MediCare WhatsApp Support'),
                  subtitle: const Text('Chat with patient support on WhatsApp'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => WhatsAppService.openSupportChat(context),
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out of your account'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'MediCare • Your health, our priority',
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: teal),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF203333),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
