import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/whatsapp_service.dart';
import 'appointments_screen.dart';
import 'appointment_payment_screen.dart';

class AppointmentBookingScreen extends StatefulWidget {
  final String doctorUid;
  final String doctorId;
  final String doctorName;
  final String specialization;
  final String hospital;
  final String consultationFee;
  final String doctorPhone;
  final List<String> availableDays;
  final List<String> availableTimeSlots;

  const AppointmentBookingScreen({
    super.key,
    this.doctorUid = '',
    this.doctorId = '',
    required this.doctorName,
    required this.specialization,
    this.hospital = 'MediCare Hospital',
    this.consultationFee = '500',
    this.doctorPhone = '',
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

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  DateTime? selectedDate;
  String? selectedTime;
  final TextEditingController reasonController = TextEditingController();

  bool isBooking = false;

  static const Color primaryColor = Color(0xFF0E9F9A);

  List<String> get effectiveTimeSlots => widget.availableTimeSlots.isNotEmpty
      ? widget.availableTimeSlots
      : const [
          '09:00 AM',
          '10:00 AM',
          '11:00 AM',
          '02:00 PM',
          '03:00 PM',
          '04:00 PM'
        ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  Future<void> selectDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF203333),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> confirmAppointment() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both an appointment date and time slot.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before booking an appointment.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final formattedDate =
        '${selectedDate!.day.toString().padLeft(2, '0')}/'
        '${selectedDate!.month.toString().padLeft(2, '0')}/'
        '${selectedDate!.year}';

    // Show appointment confirmation summary dialog first
    final confirmed = await _showSummaryDialog(formattedDate, selectedTime!);
    if (confirmed != true) return;

    setState(() => isBooking = true);

    try {
      // 1. Fetch patient profile with graceful fallback
      String patientName = user.displayName ?? 'Patient';
      String patientPhone = '';
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final patientData = userDoc.data();
        if (patientData?['name']?.toString().trim().isNotEmpty == true) {
          patientName = patientData!['name'].toString().trim();
        }
        patientPhone = patientData?['phone']?.toString().trim() ?? '';
      } catch (e) {
        debugPrint('Note: Profile fetch skipped: $e');
      }

      // 2. Prevent duplicate bookings:
      // First check if THIS patient already booked this exact slot
      try {
        final myExistingQuery = await FirebaseFirestore.instance
            .collection('appointments')
            .where('userId', isEqualTo: user.uid)
            .where('appointmentDate', isEqualTo: formattedDate)
            .where('appointmentTime', isEqualTo: selectedTime)
            .get();

        final hasMyDuplicate = myExistingQuery.docs.any((d) {
          final s = (d.data()['status'] ?? '').toString().toLowerCase();
          return s != 'cancelled';
        });

        if (hasMyDuplicate) {
          if (!mounted) return;
          await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Already Booked'),
              content: Text(
                'You already have an appointment booked on $formattedDate at $selectedTime.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('Patient self-duplicate check note: $e');
      }

      // Next check if the doctor has an active booking for this date & slot
      final String docUidToMatch = widget.doctorUid.isNotEmpty
          ? widget.doctorUid
          : widget.doctorId;

      if (docUidToMatch.isNotEmpty) {
        try {
          final existingQuery = await FirebaseFirestore.instance
              .collection('appointments')
              .where('doctorUid', isEqualTo: docUidToMatch)
              .where('appointmentDate', isEqualTo: formattedDate)
              .where('appointmentTime', isEqualTo: selectedTime)
              .get();

          final activeDuplicate = existingQuery.docs.any((d) {
            final s = (d.data()['status'] ?? '').toString().toLowerCase();
            return s != 'cancelled';
          });

          if (activeDuplicate) {
            if (!mounted) return;
            final docDisplayName = widget.doctorName.startsWith('Dr.')
                ? widget.doctorName
                : 'Dr. ${widget.doctorName}';
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Slot Unavailable'),
                content: Text(
                  'This time slot ($formattedDate at $selectedTime) is already booked for $docDisplayName. Please pick another time slot.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
        } catch (e) {
          // If security rules restrict querying other patients' appointments, continue
          debugPrint('Doctor slot duplicate check note: $e');
        }
      }

      // 3. Save new appointment with unique doc ID and consistent fields
      final appointmentRef =
          FirebaseFirestore.instance.collection('appointments').doc();

      final appointmentData = {
        'id': appointmentRef.id,
        'doctorUid': docUidToMatch,
        'doctorId': widget.doctorId,
        'patientUid': user.uid,
        'userId': user.uid, // backward compatibility with older queries
        'userEmail': user.email ?? '',
        'doctorName': widget.doctorName,
        'doctorPhone': widget.doctorPhone,
        'specialization': widget.specialization,
        'hospital': widget.hospital,
        'patientName': patientName,
        'patientEmail': user.email ?? '',
        'patientPhone': patientPhone,
        'appointmentDate': formattedDate,
        'appointmentTime': selectedTime,
        'consultationFee': widget.consultationFee,
        'reason': reasonController.text.trim(),
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'paymentReference': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await appointmentRef.set(appointmentData);

      if (!mounted) return;

      // 4. Show a demo appointment QR immediately after booking (no payment).
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentPaymentScreen(
            appointmentId: appointmentRef.id,
            doctorName: widget.doctorName,
            appointmentDate: formattedDate,
            appointmentTime: selectedTime!,
            consultationFee: widget.consultationFee,
          ),
        ),
      );
      if (!mounted) return;
      // Keep the existing appointment confirmation and WhatsApp support flow.
      await _showSuccessDialog(formattedDate, selectedTime!, appointmentRef.id);

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      debugPrint('Firestore Error on booking: ${e.code} - ${e.message}');
      final msg = e.code == 'permission-denied'
          ? 'Firebase denied permission. Please check Firestore security rules.'
          : 'Could not book appointment: ${e.message ?? e.code}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint('General error on booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => isBooking = false);
      }
    }
  }

  Future<bool?> _showSummaryDialog(String date, String time) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appointment Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryItem('Doctor', widget.doctorName),
              _summaryItem('Specialization', widget.specialization),
              _summaryItem('Hospital', widget.hospital),
              _summaryItem('Date', date),
              _summaryItem('Time Slot', time),
              _summaryItem('Consultation Fee', '₹${widget.consultationFee}'),
              if (reasonController.text.trim().isNotEmpty)
                _summaryItem('Reason', reasonController.text.trim()),
              const Divider(height: 20),
              const Text(
                'Status will initially be marked as Pending until confirmed by the doctor.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Edit Details'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF203333)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog(
      String date, String time, String appointmentId) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFE0F5F4),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: primaryColor,
                  size: 46,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Appointment Requested!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF203333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your appointment with ${widget.doctorName} has been submitted.\n\nDate: $date\nTime: $time\nStatus: Pending Approval',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 18),

              // WhatsApp Support button on confirmation screen
              OutlinedButton.icon(
                onPressed: () {
                  WhatsAppService.openSupportChat(
                    context,
                    message:
                        'Hello MediCare, I just booked appointment #$appointmentId with ${widget.doctorName} on $date. I would like assistance.',
                  );
                },
                icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                label: const Text(
                  'WhatsApp MediCare Support',
                  style: TextStyle(color: Color(0xFF1E824C)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF25D366)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppointmentsScreen(),
                ),
              );
            },
            child: const Text('View Appointments'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor header banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFE0F5F4),
                    child: Icon(
                      Icons.medical_services,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.specialization,
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.hospital,
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
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '₹${widget.consultationFee}',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Select Date
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203333),
              ),
            ),
            const SizedBox(height: 10),

            InkWell(
              onTap: isBooking ? null : selectDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedDate == null
                        ? Colors.grey.shade300
                        : primaryColor,
                    width: selectedDate == null ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedDate == null
                            ? 'Choose appointment date'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}/'
                                '${selectedDate!.month.toString().padLeft(2, '0')}/'
                                '${selectedDate!.year}',
                        style: TextStyle(
                          color: selectedDate == null
                              ? Colors.grey
                              : const Color(0xFF203333),
                          fontSize: 15,
                          fontWeight: selectedDate == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Select Time Slot
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203333),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: effectiveTimeSlots.map((time) {
                final selected = selectedTime == time;
                return ChoiceChip(
                  label: Text(time),
                  selected: selected,
                  selectedColor: primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: selected ? primaryColor : Colors.grey.shade300,
                  ),
                  onSelected: isBooking
                      ? null
                      : (val) {
                          setState(() {
                            selectedTime = val ? time : null;
                          });
                        },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Reason for Consultation
            const Text(
              'Reason for Visit (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF203333),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Briefly describe symptoms or questions for ${widget.doctorName.startsWith('Dr.') ? widget.doctorName : 'Dr. ${widget.doctorName}'}...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
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
                  borderSide: const BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: isBooking ? null : confirmAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: isBooking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'REVIEW & CONFIRM APPOINTMENT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
