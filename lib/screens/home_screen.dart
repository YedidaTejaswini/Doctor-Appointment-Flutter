import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/whatsapp_service.dart';
import 'doctors_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';
import 'doctor_details_screen.dart';
import 'appointment_booking_screen.dart';
import 'login_selection_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeContent(onNavigateToTab: _onTabSelected),
      const DoctorsScreen(),
      const AppointmentsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: const Color(0xFF0E9F9A),
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: _onTabSelected,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Doctors',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined),
              activeIcon: Icon(Icons.calendar_month),
              label: 'Appointments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOME CONTENT - REAL PATIENT NAME + ALL CATEGORIES + DYNAMIC DOCTORS
// ============================================================

class HomeContent extends StatefulWidget {
  final void Function(int tabIndex) onNavigateToTab;

  const HomeContent({super.key, required this.onNavigateToTab});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';
  String selectedSpecialization = '';

  static const Color primaryColor = Color(0xFF0E9F9A);

  // Full list of 8 medical categories as required
  final List<Map<String, dynamic>> categories = const [
    {'title': 'General Physician', 'icon': Icons.medical_information_outlined},
    {'title': 'Cardiologist', 'icon': Icons.favorite_outline},
    {'title': 'Dermatologist', 'icon': Icons.face_retouching_natural},
    {'title': 'Dentist', 'icon': Icons.health_and_safety_outlined},
    {'title': 'Pediatrician', 'icon': Icons.child_care},
    {'title': 'Orthopedic', 'icon': Icons.accessibility_new},
    {'title': 'Gynecologist', 'icon': Icons.pregnant_woman},
    {'title': 'Neurologist', 'icon': Icons.psychology_outlined},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of MediCare?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginSelectionScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5FAFA),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F5F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital_rounded,
                  color: primaryColor, size: 24),
            ),
            const SizedBox(width: 10),
            const Text(
              'MediCare',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Color(0xFF203333),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'WhatsApp Support',
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: () => WhatsAppService.openSupportChat(context),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic Welcome Message with Logged-in Patient Name
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: currentUser != null
                    ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .snapshots()
                    : null,
                builder: (context, snapshot) {
                  String patientName = currentUser?.displayName ?? 'Patient';
                  if (snapshot.hasData && snapshot.data?.data() != null) {
                    final data = snapshot.data!.data()!;
                    if (data['name']?.toString().trim().isNotEmpty == true) {
                      patientName = data['name'].toString().trim();
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, $patientName 👋',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF203333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Find trusted doctors & book appointments seamlessly',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // Search doctors input
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by doctor name, specialization, clinic...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: primaryColor),
                  suffixIcon: searchText.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchText = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: primaryColor, width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // WhatsApp Support Quick Banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F8F5), Color(0xFFD4EFE9)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFB5E5DA)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF25D366),
                      child: Icon(Icons.chat, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MediCare WhatsApp Helpdesk',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E824C),
                            ),
                          ),
                          Text(
                            'Need assistance with appointments? Tap to chat.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => WhatsAppService.openSupportChat(context),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1E824C),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: const Text('Chat Now',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Categories Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Doctor Categories',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203333),
                    ),
                  ),
                  if (selectedSpecialization.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() => selectedSpecialization = '');
                      },
                      child: const Text('Show All',
                          style: TextStyle(color: primaryColor)),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Categories Horizontal List (All 8 specializations)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final title = cat['title'] as String;
                    final icon = cat['icon'] as IconData;
                    final isSelected = selectedSpecialization == title;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedSpecialization = isSelected ? '' : title;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 110,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? primaryColor
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              color: primaryColor,
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: isSelected
                                    ? primaryColor
                                    : const Color(0xFF203333),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Quick Access Action Buttons (Appointments, Profile)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onNavigateToTab(2),
                      icon: const Icon(Icons.calendar_month,
                          size: 18, color: primaryColor),
                      label: const Text(
                        'My Bookings',
                        style: TextStyle(color: primaryColor, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => widget.onNavigateToTab(1),
                      icon: const Icon(Icons.search,
                          size: 18, color: primaryColor),
                      label: const Text(
                        'Browse Doctors',
                        style: TextStyle(color: primaryColor, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Featured Doctors Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedSpecialization.isNotEmpty
                        ? '$selectedSpecialization Specialists'
                        : searchText.isNotEmpty
                            ? 'Search Results'
                            : 'Featured Doctors',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203333),
                    ),
                  ),
                  if (searchText.isNotEmpty ||
                      selectedSpecialization.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {
                          searchText = '';
                          selectedSpecialization = '';
                        });
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: primaryColor)),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Live Firestore doctors stream
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('doctors')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Unable to load doctors.\nError: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );
                  }

                  final documents = snapshot.data?.docs ?? [];

                  final filtered = documents.where((doc) {
                    final data = doc.data();
                    final name =
                        (data['name'] ?? '').toString().toLowerCase();
                    final spec =
                        (data['specialization'] ?? '').toString().toLowerCase();
                    final hosp =
                        (data['hospital'] ?? '').toString().toLowerCase();

                    final matchesSearch = searchText.isEmpty ||
                        name.contains(searchText) ||
                        spec.contains(searchText) ||
                        hosp.contains(searchText);

                    final sel = selectedSpecialization.toLowerCase();
                    final matchesCategory = sel.isEmpty ||
                        spec.contains(sel) ||
                        (sel == 'general physician' &&
                            spec.contains('physician')) ||
                        (sel == 'cardiologist' &&
                            spec.contains('cardio')) ||
                        (sel == 'dermatologist' &&
                            spec.contains('derma')) ||
                        (sel == 'dentist' &&
                            (spec.contains('dent') ||
                                spec.contains('dental'))) ||
                        (sel == 'pediatrician' &&
                            spec.contains('pediatric')) ||
                        (sel == 'orthopedic' &&
                            spec.contains('ortho')) ||
                        (sel == 'gynecologist' &&
                            spec.contains('gynec')) ||
                        (sel == 'neurologist' &&
                            spec.contains('neuro'));

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off,
                              size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text(
                            'No doctors found matching your criteria.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203333),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try selecting another category or clear the search filters.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: filtered.map((doc) {
                      final data = doc.data();
                      final doctorUid = (data['uid'] ?? doc.id).toString();
                      final doctorId = doc.id;
                      final name = (data['name'] ?? 'Doctor').toString();
                      final spec =
                          (data['specialization'] ?? 'General Physician')
                              .toString();
                      final exp =
                          (data['experience'] ?? 'Not specified').toString();
                      final hospital =
                          (data['hospital'] ?? 'MediCare Hospital')
                              .toString();
                      final fee = (data['consultationFee'] ??
                              data['fee'] ??
                              '500')
                          .toString();
                      final phone = (data['phone'] ?? '').toString();
                      final qual = (data['qualifications'] ?? 'MBBS').toString();

                      final rawRating = data['rating'];
                      final double rating = rawRating is num
                          ? rawRating.toDouble()
                          : double.tryParse(rawRating?.toString() ?? '') ?? 4.8;

                      final List<String> days = (data['availableDays']
                              is List)
                          ? (data['availableDays'] as List)
                              .map((e) => e.toString())
                              .toList()
                          : const [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat'
                            ];

                      final List<String> slots = (data['availableTimeSlots']
                              is List)
                          ? (data['availableTimeSlots'] as List)
                              .map((e) => e.toString())
                              .toList()
                          : const [
                              '09:00 AM',
                              '10:00 AM',
                              '11:00 AM',
                              '02:00 PM',
                              '04:00 PM'
                            ];

                      return DoctorCard(
                        name: name,
                        specialization: spec,
                        hospital: hospital,
                        experience: exp,
                        rating: rating,
                        fee: fee,
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DoctorDetailsScreen(
                                doctorUid: doctorUid,
                                doctorId: doctorId,
                                name: name,
                                specialization: spec,
                                rating: rating.toString(),
                                experience: exp,
                                hospital: hospital,
                                consultationFee: fee,
                                doctorPhone: phone,
                                qualifications: qual,
                                availableDays: days,
                                availableTimeSlots: slots,
                              ),
                            ),
                          );
                        },
                        onBookAppointment: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppointmentBookingScreen(
                                doctorUid: doctorUid,
                                doctorId: doctorId,
                                doctorName: name,
                                specialization: spec,
                                hospital: hospital,
                                consultationFee: fee,
                                doctorPhone: phone,
                                availableDays: days,
                                availableTimeSlots: slots,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DOCTOR CARD COMPONENT WITH "BOOK APPOINTMENT" BUTTON & DETAILS
// ============================================================

class DoctorCard extends StatelessWidget {
  final String name;
  final String specialization;
  final String hospital;
  final String experience;
  final double rating;
  final String fee;
  final VoidCallback onViewDetails;
  final VoidCallback onBookAppointment;

  const DoctorCard({
    super.key,
    required this.name,
    required this.specialization,
    required this.hospital,
    required this.experience,
    required this.rating,
    required this.fee,
    required this.onViewDetails,
    required this.onBookAppointment,
  });

  static const Color primaryColor = Color(0xFF0E9F9A);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFE0F5F4),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      size: 32,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF203333),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          specialization,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          hospital,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Experience & Fee row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.work_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        experience.contains('Year')
                            ? experience
                            : '$experience Years',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Fee: ₹$fee',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF203333),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Buttons row: "View Details" and "Book Appointment"
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: onViewDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryColor,
                        side: const BorderSide(color: primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onBookAppointment,
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: const Text(
                        'Book Appointment',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
