import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Demo appointment QR screen. This is NOT a payment QR code.
/// It encodes appointment details only; it does not verify a booking by itself.
class AppointmentPaymentScreen extends StatelessWidget {
  final String appointmentId;
  final String doctorName;
  final String appointmentDate;
  final String appointmentTime;
  final String consultationFee;

  const AppointmentPaymentScreen({
    super.key,
    required this.appointmentId,
    required this.doctorName,
    required this.appointmentDate,
    required this.appointmentTime,
    required this.consultationFee,
  });

  static const Color teal = Color(0xFF0E9F9A);

  String get qrData => jsonEncode({
    'type': 'DEMO_APPOINTMENT',
    'appointmentId': appointmentId,
    'doctorName': doctorName,
    'date': appointmentDate,
    'time': appointmentTime,
    'consultationFee': consultationFee,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFA),
      appBar: AppBar(
        title: const Text('Appointment QR Code'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.qr_code_2, color: teal, size: 44),
                const SizedBox(height: 10),
                const Text(
                  'Your appointment QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Show this code to the clinic staff for demo appointment identification. No payment is made.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Center(
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
                const SizedBox(height: 18),
                _detail('Appointment ID', appointmentId),
                _detail('Doctor', 'Dr. $doctorName'),
                _detail('Date', appointmentDate),
                _detail('Time', appointmentTime),
                _detail('Consultation fee', consultationFee),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F7F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'DEMO ONLY • This QR code does not contain a UPI payment link and does not prove that an appointment is confirmed. The clinic must check the appointment in its booking system.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF176A66)),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Back to appointment flow'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 145, child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}
