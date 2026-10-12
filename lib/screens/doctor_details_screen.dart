import 'package:flutter/material.dart';
import '../services/whatsapp_service.dart';
import 'appointment_booking_screen.dart';

class DoctorDetailsScreen extends StatelessWidget {
  final String doctorUid;
  final String doctorId;
  final String name;
  final String specialization;
  final String rating;
  final String experience;
  final String hospital;
  final String consultationFee;
  final String doctorPhone;
  final String qualifications;
  final List<String> availableDays;
  final List<String> availableTimeSlots;

  const DoctorDetailsScreen({
    super.key,
    this.doctorUid = '',
    this.doctorId = '',
    required this.name,
    required this.specialization,
    required this.rating,
    required this.experience,
    required this.hospital,
    this.consultationFee = '500',
    this.doctorPhone = '',
    this.qualifications = 'MBBS',
    this.availableDays = const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
    this.availableTimeSlots = const [
      '09:00 AM',
      '10:00 AM',
      '11:00 AM',
      '02:00 PM',
      '03:00 PM',
      '04:00 PM'
    ],
  });

  static const Color teal = Color(0xFF0E9F9A);

  @override
  Widget build(BuildContext context) {
    final double numericRating = double.tryParse(rating) ?? 4.8;
    final String cleanPhone = doctorPhone.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              decoration: const BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFFE0F5F4),
                      child: const Icon(
                        Icons.person,
                        size: 55,
                        color: teal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    specialization,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (qualifications.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        qualifications,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        numericRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '• Verified Specialist',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats row
                  Row(
                    children: [
                      Expanded(
                        child: _metricBox(
                          'Experience',
                          experience.contains('Year')
                              ? experience
                              : '$experience Years',
                          Icons.work_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricBox(
                          'Consultation',
                          '₹$consultationFee',
                          Icons.payments_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Practice Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203333),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _infoCard(
                    icon: Icons.local_hospital_outlined,
                    title: 'Hospital / Clinic',
                    value: hospital.isEmpty ? 'MediCare Hospital' : hospital,
                  ),

                  _infoCard(
                    icon: Icons.calendar_today_outlined,
                    title: 'Available Days',
                    value: availableDays.join(', '),
                  ),

                  _infoCard(
                    icon: Icons.access_time_outlined,
                    title: 'Visiting Hours',
                    value: availableTimeSlots.isEmpty
                        ? '09:00 AM - 05:00 PM'
                        : '${availableTimeSlots.first} to ${availableTimeSlots.last}',
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'About Doctor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF203333),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    '$name is a certified $specialization with $experience of clinical expertise at $hospital. Specialized in evidence-based patient healthcare and comprehensive consultations.',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // WhatsApp Doctor Contact Button (if doctor phone is available)
                  if (cleanPhone.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          WhatsAppService.openDoctorChat(
                            context: context,
                            doctorPhone: cleanPhone,
                            doctorName: name,
                          );
                        },
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                        label: const Text(
                          'Contact Doctor on WhatsApp',
                          style: TextStyle(
                            color: Color(0xFF1E824C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFF25D366),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // BOOK APPOINTMENT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentBookingScreen(
                              doctorUid: doctorUid,
                              doctorId: doctorId,
                              doctorName: name,
                              specialization: specialization,
                              hospital: hospital,
                              consultationFee: consultationFee,
                              doctorPhone: cleanPhone,
                              availableDays: availableDays,
                              availableTimeSlots: availableTimeSlots,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month),
                      label: const Text(
                        'BOOK APPOINTMENT',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: teal.withValues(alpha: 0.12),
            child: Icon(icon, color: teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF203333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: teal.withValues(alpha: 0.1),
            child: Icon(icon, color: teal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF203333),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}