import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'login_selection_screen.dart';

class HospitalAdminDashboardScreen extends StatelessWidget {
  const HospitalAdminDashboardScreen({super.key});

  static const Color teal = Color(0xFF0E9F9A);

  Future<void> _setStatus(BuildContext context, DocumentSnapshot<Map<String, dynamic>> doc, String status) async {
    try {
      await doc.reference.update({
        'status': status,
        'adminReviewedBy': FirebaseAuth.instance.currentUser?.uid,
        'adminReviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment ${status.toUpperCase()}.')));
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update appointment: ${e.message ?? e.code}')));
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginSelectionScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Admin Dashboard'),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        actions: [IconButton(tooltip: 'Logout', onPressed: () => _logout(context), icon: const Icon(Icons.logout))],
      ),
      body: user == null
          ? const Center(child: Text('Please sign in again.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('appointments').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Could not load appointments. Check Firestore rules.\n${snapshot.error}')));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                final pending = docs.where((d) => (d.data()['status'] ?? 'pending').toString().toLowerCase() == 'pending').length;
                return Column(children: [
                  Container(width: double.infinity, padding: const EdgeInsets.all(20), color: const Color(0xFFE8F6F4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Appointment management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Total appointments: ${docs.length}  •  Pending review: $pending'),
                  ])),
                  Expanded(child: docs.isEmpty
                      ? const Center(child: Text('No appointments found yet.'))
                      : ListView.builder(padding: const EdgeInsets.all(12), itemCount: docs.length, itemBuilder: (context, index) {
                          final doc = docs[index];
                          final d = doc.data();
                          final status = (d['status'] ?? 'pending').toString().toLowerCase();
                          final isPending = status == 'pending';
                          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Icon(Icons.event_note, color: teal, size: 30), const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text((d['patientName'] ?? 'Patient').toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                Text('Doctor: ${(d['doctorName'] ?? 'Not specified')}'),
                                Text('Date: ${(d['appointmentDate'] ?? d['date'] ?? 'N/A')}  •  Time: ${(d['appointmentTime'] ?? d['time'] ?? 'N/A')}'),
                                Text('Fee: ₹${d['consultationFee'] ?? 'N/A'}'),
                                if ((d['reason'] ?? '').toString().isNotEmpty) Text('Reason: ${d['reason']}'),
                                const SizedBox(height: 8),
                                Chip(label: Text(status.toUpperCase()), backgroundColor: status == 'confirmed' ? Colors.green.shade100 : status == 'rejected' || status == 'cancelled' ? Colors.red.shade100 : status == 'completed' ? Colors.blue.shade100 : Colors.orange.shade100),
                              ])),
                            ]),
                            if (isPending) ...[
                              const Divider(),
                              Wrap(spacing: 10, children: [
                                ElevatedButton.icon(onPressed: () => _setStatus(context, doc, 'confirmed'), icon: const Icon(Icons.check), label: const Text('Approve'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
                                OutlinedButton.icon(onPressed: () => _setStatus(context, doc, 'rejected'), icon: const Icon(Icons.close), label: const Text('Reject'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red)),
                              ]),
                            ],
                          ])));
                        })),
                ]);
              },
            ),
    );
  }
}
