import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/whatsapp_service.dart';
import 'appointment_payment_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  static const Color primaryColor = Color(0xFF0E9F9A);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text(
          'My Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to view your appointments.',
                style: TextStyle(fontSize: 16),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // Query matching either userId or patientUid
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Unable to load appointments.\n\n${snapshot.error}',
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

                final appointments = snapshot.data?.docs ?? [];

                if (appointments.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_outlined,
                            size: 80,
                            color: primaryColor.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No appointments yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF203333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Book an appointment with our specialists and track your consultation status here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort appointments: newest first
                final sortedAppointments = [...appointments];
                sortedAppointments.sort((a, b) {
                  final aDate = a.data()['createdAt'] as Timestamp?;
                  final bDate = b.data()['createdAt'] as Timestamp?;
                  if (aDate == null && bDate == null) return 0;
                  if (aDate == null) return 1;
                  if (bDate == null) return -1;
                  return bDate.compareTo(aDate);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedAppointments.length,
                  itemBuilder: (context, index) {
                    final doc = sortedAppointments[index];
                    final data = doc.data();

                    final doctorName =
                        (data['doctorName'] ?? data['name'] ?? 'Doctor')
                            .toString();

                    final specialization = (data['specialization'] ??
                            'General Physician')
                        .toString();

                    final appointmentDate = (data['appointmentDate'] ??
                            data['date'] ??
                            'Not specified')
                        .toString();

                    final appointmentTime = (data['appointmentTime'] ??
                            data['time'] ??
                            'Not specified')
                        .toString();

                    final hospital = (data['hospital'] ?? 'MediCare Hospital')
                        .toString();

                    final reason = (data['reason'] ?? '').toString();
                    final doctorPhone = (data['doctorPhone'] ?? '').toString();

                    final rawStatus =
                        (data['status'] ?? 'pending').toString();
                    final normalizedStatus = rawStatus.toLowerCase();

                    // Status styling
                    Color statusColor;
                    Color statusBackground;
                    String displayStatus;

                    if (normalizedStatus == 'confirmed') {
                      statusColor = const Color(0xFF0E9F9A);
                      statusBackground = const Color(0xFFE0F5F4);
                      displayStatus = 'Confirmed';
                    } else if (normalizedStatus == 'completed') {
                      statusColor = Colors.blue.shade700;
                      statusBackground = Colors.blue.shade50;
                      displayStatus = 'Completed';
                    } else if (normalizedStatus == 'cancelled') {
                      statusColor = Colors.red.shade700;
                      statusBackground = Colors.red.shade50;
                      displayStatus = 'Cancelled';
                    } else {
                      statusColor = Colors.orange.shade800;
                      statusBackground = Colors.orange.shade50;
                      displayStatus = 'Pending';
                    }

                    final bool canCancel = normalizedStatus != 'cancelled' &&
                        normalizedStatus != 'completed';
                    final paymentStatus = (data['paymentStatus'] ?? 'unpaid').toString().toLowerCase();
                    final paymentLabel = paymentStatus == 'verified' ? 'Verified' : paymentStatus == 'submitted' ? 'Awaiting doctor verification' : 'Not paid';
                    final paymentColor = paymentStatus == 'verified' ? Colors.green.shade700 : paymentStatus == 'submitted' ? Colors.orange.shade800 : Colors.red.shade700;

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: Colors.grey.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Doctor header & status badge
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: const Color(0xFFE0F5F4),
                                  child: const Icon(
                                    Icons.medical_services_rounded,
                                    color: primaryColor,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctorName,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
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
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBackground,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 12),

                            // Date & Time rows
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  appointmentDate,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF203333),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.access_time,
                                  color: primaryColor,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  appointmentTime,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF203333),
                                  ),
                                ),
                              ],
                            ),

                            // Reason for visit
                            if (reason.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAFA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Reason: $reason',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: paymentColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                Icon(paymentStatus == 'verified' ? Icons.verified : paymentStatus == 'submitted' ? Icons.hourglass_top : Icons.payment, color: paymentColor, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text('Payment: $paymentLabel', style: TextStyle(color: paymentColor, fontWeight: FontWeight.w700, fontSize: 13))),
                                Text('₹${data['consultationFee'] ?? '500'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ]),
                            ),
                            const SizedBox(height: 14),

                            // Actions Row: payment, WhatsApp Doctor & Cancel Appointment
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                if (normalizedStatus != 'cancelled' && normalizedStatus != 'completed' && paymentStatus != 'verified')
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (_) => AppointmentPaymentScreen(appointmentId: doc.id, doctorName: doctorName, appointmentDate: appointmentDate, appointmentTime: appointmentTime, consultationFee: (data['consultationFee'] ?? '500').toString())));
                                    },
                                    icon: const Icon(Icons.qr_code_2, size: 18),
                                    label: Text(paymentStatus == 'submitted' ? 'View Payment' : 'Pay by QR'),
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  ),
                                // WhatsApp Button (Section 4 & 6)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    if (doctorPhone.trim().isNotEmpty) {
                                      WhatsAppService.openDoctorChat(
                                        context: context,
                                        doctorPhone: doctorPhone,
                                        doctorName: doctorName,
                                        date: appointmentDate,
                                        time: appointmentTime,
                                        appointmentId: doc.id,
                                      );
                                    } else {
                                      // Support fallback if doctor has no verified phone
                                      WhatsAppService.openSupportChat(
                                        context,
                                        message:
                                            'Hello MediCare, regarding my appointment ($appointmentDate at $appointmentTime) with $doctorName.',
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.chat,
                                      color: Color(0xFF25D366), size: 18),
                                  label: Text(
                                    doctorPhone.trim().isNotEmpty
                                        ? 'WhatsApp Doctor'
                                        : 'WhatsApp Support',
                                    style: const TextStyle(
                                      color: Color(0xFF1E824C),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFF25D366),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),

                                // Cancel Button
                                if (canCancel)
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Cancel Appointment?'),
                                          content: Text(
                                            'Are you sure you want to cancel your appointment with $doctorName on $appointmentDate?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Keep Appointment'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text(
                                                'Yes, Cancel',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm != true) return;

                                      try {
                                        final currentUser =
                                            FirebaseAuth.instance.currentUser;
                                        if (currentUser == null ||
                                            (data['userId'] != currentUser.uid &&
                                                data['patientUid'] !=
                                                    currentUser.uid)) {
                                          throw Exception(
                                              'You can only cancel your own appointments.');
                                        }

                                        await doc.reference.update({
                                          'status': 'cancelled',
                                          'updatedAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Appointment cancelled successfully.',
                                            ),
                                            backgroundColor: primaryColor,
                                          ),
                                        );
                                      } catch (e) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not cancel appointment: $e',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
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
    );
  }
}
