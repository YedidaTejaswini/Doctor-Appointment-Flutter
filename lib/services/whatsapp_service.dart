import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  // Configurable MediCare support phone number (with country code, digits only)
  static const String defaultSupportPhone = '919948123198';

  /// Sanitizes phone number by removing non-digits and ensuring country code
  static String formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'\D'), '');
    // If it's a 10-digit number (common standard mobile), prepend default country code 91
    if (cleaned.length == 10) {
      cleaned = '91$cleaned';
    }
    return cleaned;
  }

  /// Launch WhatsApp chat with prefilled message
  static Future<void> launchWhatsApp({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final cleanPhone = formatPhoneNumber(phone);
    if (cleanPhone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number provided for WhatsApp.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final encodedMessage = Uri.encodeComponent(message);
    final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$encodedMessage');
    final webUri = Uri.parse(
        'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encodedMessage');

    try {
      final launched = await launchUrl(
        waUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Try web fallback
        final webLaunched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (!webLaunched && context.mounted) {
          _showFallbackDialog(context, cleanPhone, message);
        }
      }
    } catch (_) {
      try {
        final webLaunched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (!webLaunched && context.mounted) {
          _showFallbackDialog(context, cleanPhone, message);
        }
      } catch (e) {
        if (context.mounted) {
          _showFallbackDialog(context, cleanPhone, message);
        }
      }
    }
  }

  /// Contact patient support
  static Future<void> openSupportChat(
    BuildContext context, {
    String message = 'Hello MediCare, I need help with my appointment.',
    String? supportPhone,
  }) async {
    await launchWhatsApp(
      context: context,
      phone: supportPhone ?? defaultSupportPhone,
      message: message,
    );
  }

  /// Contact a specific doctor regarding an appointment
  static Future<void> openDoctorChat({
    required BuildContext context,
    required String doctorPhone,
    required String doctorName,
    String? date,
    String? time,
    String? appointmentId,
  }) async {
    final buffer = StringBuffer('Hello Dr. $doctorName, ');
    if (date != null && date.isNotEmpty) {
      buffer.write('regarding my appointment on $date');
      if (time != null && time.isNotEmpty) {
        buffer.write(' at $time');
      }
      buffer.write('.');
    } else {
      buffer.write('I am contacting you regarding MediCare consultation.');
    }
    if (appointmentId != null && appointmentId.isNotEmpty) {
      buffer.write(' (Ref: ${appointmentId.substring(0, appointmentId.length > 8 ? 8 : appointmentId.length)})');
    }

    await launchWhatsApp(
      context: context,
      phone: doctorPhone,
      message: buffer.toString(),
    );
  }

  /// Contact patient from doctor dashboard
  static Future<void> openPatientChat({
    required BuildContext context,
    required String patientPhone,
    required String patientName,
    required String doctorName,
    String? date,
    String? time,
  }) async {
    final buffer = StringBuffer('Hello $patientName, this is Dr. $doctorName from MediCare. ');
    if (date != null && date.isNotEmpty) {
      buffer.write('Regarding your scheduled appointment on $date');
      if (time != null && time.isNotEmpty) {
        buffer.write(' at $time.');
      }
    }

    await launchWhatsApp(
      context: context,
      phone: patientPhone,
      message: buffer.toString(),
    );
  }

  static void _showFallbackDialog(
    BuildContext context,
    String phone,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, color: Color(0xFF0E9F9A)),
            SizedBox(width: 8),
            Text('WhatsApp Unavailable'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not open the WhatsApp application on this device.',
            ),
            const SizedBox(height: 12),
            Text('Contact Number: +$phone',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: phone));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number copied to clipboard!')),
              );
            },
            child: const Text('Copy Number'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E9F9A),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
