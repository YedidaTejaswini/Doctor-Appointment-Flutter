import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'doctor_details_screen.dart';
import 'appointment_booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  static const Color primaryColor = Color(0xFF0E9F9A);
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text(
          'MediCare Specialists',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF5FAFA),
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: searchController,
              onChanged: (val) {
                setState(() => searchQuery = val.trim().toLowerCase());
              },
              decoration: InputDecoration(
                hintText: 'Search by doctor, specialization, or hospital...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: primaryColor),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
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
          ),

          // Doctors stream
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('doctors')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Unable to load doctors.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }

                final rawDoctors = snapshot.data?.docs ?? [];

                final doctors = rawDoctors.where((doc) {
                  if (searchQuery.isEmpty) return true;
                  final d = doc.data();
                  final name = (d['name'] ?? '').toString().toLowerCase();
                  final spec =
                      (d['specialization'] ?? '').toString().toLowerCase();
                  final hosp = (d['hospital'] ?? '').toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      spec.contains(searchQuery) ||
                      hosp.contains(searchQuery);
                }).toList();

                if (doctors.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'No doctors found.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203333),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final document = doctors[index];
                    final doctor = document.data();

                    final String doctorUid =
                        (doctor['uid'] ?? document.id).toString();
                    final String doctorId = document.id;
                    final String name =
                        doctor['name']?.toString() ?? 'Doctor';
                    final String specialization =
                        doctor['specialization']?.toString() ??
                            'General Physician';
                    final String experience =
                        doctor['experience']?.toString() ?? 'Not specified';
                    final String hospital =
                        doctor['hospital']?.toString() ?? 'MediCare Hospital';
                    final String fee = (doctor['consultationFee'] ??
                            doctor['fee'] ??
                            '500')
                        .toString();
                    final String phone = (doctor['phone'] ?? '').toString();
                    final String qualifications =
                        (doctor['qualifications'] ?? 'MBBS').toString();

                    final dynamic ratingValue = doctor['rating'];
                    final double rating = ratingValue is num
                        ? ratingValue.toDouble()
                        : double.tryParse(ratingValue?.toString() ?? '') ?? 4.8;

                    final List<String> days =
                        (doctor['availableDays'] is List)
                            ? (doctor['availableDays'] as List)
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

                    final List<String> slots =
                        (doctor['availableTimeSlots'] is List)
                            ? (doctor['availableTimeSlots'] as List)
                                .map((e) => e.toString())
                                .toList()
                            : const [
                                '09:00 AM',
                                '10:00 AM',
                                '11:00 AM',
                                '02:00 PM',
                                '04:00 PM'
                              ];

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor: const Color(0xFFE0F5F4),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        specialization,
                                        style: const TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            experience.contains('Year')
                                                ? experience
                                                : '$experience Years',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    hospital,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Fee: ₹$fee',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF203333),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: primaryColor,
                                      side: const BorderSide(
                                        color: primaryColor,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DoctorDetailsScreen(
                                            doctorUid: doctorUid,
                                            doctorId: doctorId,
                                            name: name,
                                            specialization: specialization,
                                            rating: rating.toString(),
                                            experience: experience,
                                            hospital: hospital,
                                            consultationFee: fee,
                                            doctorPhone: phone,
                                            qualifications: qualifications,
                                            availableDays: days,
                                            availableTimeSlots: slots,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('View Profile'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AppointmentBookingScreen(
                                            doctorUid: doctorUid,
                                            doctorId: doctorId,
                                            doctorName: name,
                                            specialization: specialization,
                                            hospital: hospital,
                                            consultationFee: fee,
                                            doctorPhone: phone,
                                            availableDays: days,
                                            availableTimeSlots: slots,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Book Now'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
