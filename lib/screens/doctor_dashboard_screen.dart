import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/whatsapp_service.dart';
import 'login_selection_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  static const Color teal = Color(0xFF0E9F9A);
  static const Color background = Color(0xFFF5FAFA);

  String selectedFilter = 'all'; // 'all', 'pending', 'confirmed', 'completed', 'cancelled'

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out of the Doctor Dashboard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
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
      (_) => false,
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> appointmentDoc,
    String newStatus,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = appointmentDoc.data();
    if (data?['doctorId'] !=
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get()
        .then((snapshot) => snapshot.data()?['doctorId'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unauthorized: You can only update appointments assigned to you.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await appointmentDoc.reference.update({
        'status': newStatus.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment marked as ${newStatus.toUpperCase()}.'),
          backgroundColor: teal,
        ),
      );
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update status: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyPayment(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> appointmentDoc,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final data = appointmentDoc.data();
    if (user == null || data?['doctorUid'] != user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can only verify payments for your own appointments.')));
      return;
    }
    if ((data?['paymentReference'] ?? '').toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No transaction reference was submitted.')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify payment?'),
        content: Text('Confirm that you checked your UPI/bank account and received ₹${data?['consultationFee'] ?? '500'}. Reference: ${data?['paymentReference']}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Verify received payment')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await appointmentDoc.reference.update({
        'paymentStatus': 'verified',
        'paymentVerifiedBy': user.uid,
        'paymentVerifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment verified.'), backgroundColor: teal));
    } on FirebaseException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not verify payment: ${e.message ?? e.code}'), backgroundColor: Colors.red));
    }
  }

  void _showAppointmentDetails(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Booking ID', id),
              _detailRow('Patient Name', data['patientName'] ?? 'Not specified'),
              _detailRow('Patient Email', data['patientEmail'] ?? data['userEmail'] ?? 'Not specified'),
              _detailRow('Patient Phone', data['patientPhone'] ?? 'Not provided'),
              _detailRow('Date', data['appointmentDate'] ?? data['date'] ?? 'N/A'),
              _detailRow('Time Slot', data['appointmentTime'] ?? data['time'] ?? 'N/A'),
              _detailRow('Fee', '₹${data['consultationFee'] ?? '500'}'),
              _detailRow('Status', (data['status'] ?? 'pending').toString().toUpperCase()),
              _detailRow('Payment Status', (data['paymentStatus'] ?? 'unpaid').toString().toUpperCase()),
              _detailRow('Payment Reference', (data['paymentReference'] ?? 'Not submitted').toString()),
              if ((data['reason'] ?? '').toString().isNotEmpty)
                _detailRow('Reason for Visit', data['reason'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF203333)),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    String uid,
    Map<String, dynamic> currentData,
  ) async {
    final phoneCtrl = TextEditingController(text: currentData['phone']?.toString() ?? '');
    final hospitalCtrl = TextEditingController(text: currentData['hospital']?.toString() ?? '');
    final qualCtrl = TextEditingController(text: currentData['qualifications']?.toString() ?? 'MBBS');
    final feeCtrl = TextEditingController(text: currentData['consultationFee']?.toString() ?? '500');
    final expCtrl = TextEditingController(
      text: (currentData['experience']?.toString() ?? '').replaceAll(' Years', '').replaceAll('Year', '').trim(),
    );

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Edit Doctor Profile'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (10 digits)',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) => v == null || !RegExp(r'^[0-9]{10}$').hasMatch(v.trim())
                      ? 'Enter a valid 10-digit phone number'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: qualCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Qualifications (e.g. MBBS, MD)',
                    prefixIcon: Icon(Icons.school),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter qualifications' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: expCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Years of Experience',
                    prefixIcon: Icon(Icons.work),
                  ),
                  validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Enter valid years' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: hospitalCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Hospital or Clinic',
                    prefixIcon: Icon(Icons.local_hospital),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter hospital name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Fee (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Enter valid fee' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final updateData = {
                'phone': phoneCtrl.text.trim(),
                'qualifications': qualCtrl.text.trim(),
                'experience': '${expCtrl.text.trim()} Years',
                'hospital': hospitalCtrl.text.trim(),
                'consultationFee': feeCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              try {
                // Update in users collection
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set(updateData, SetOptions(merge: true));

                // Also update in doctors collection (find doc with uid == uid)
                final docQuery = await FirebaseFirestore.instance
                    .collection('doctors')
                    .where('uid', isEqualTo: uid)
                    .get();

                for (final doc in docQuery.docs) {
                  await doc.reference.set(updateData, SetOptions(merge: true));
                }

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Doctor profile updated successfully!'),
                    backgroundColor: teal,
                  ),
                );
              } catch (e) {
                if (!dialogCtx.mounted) return;
                ScaffoldMessenger.of(dialogCtx).showSnackBar(
                  SnackBar(
                    content: Text('Error updating profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    phoneCtrl.dispose();
    hospitalCtrl.dispose();
    qualCtrl.dispose();
    feeCtrl.dispose();
    expCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in again.')),
      );
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Doctor Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return const Center(child: Text('Could not load doctor account.'));
          }

          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: teal));
          }

          final userData = userSnapshot.data!.data();

          if (userData == null || userData['role'] != 'doctor') {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Access denied: doctor account required.'),
              ),
            );
          }

          // Approval Guard
          final approval = userData['approvalStatus']?.toString().toLowerCase();
          if (approval != 'approved') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_filled, color: Colors.orange, size: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'Account Awaiting Approval',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Your doctor account is awaiting administrator approval. You will be able to manage your patient appointments once approved.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white),
                      onPressed: () => _logout(context),
                      child: const Text('Return to Login'),
                    ),
                  ],
                ),
              ),
            );
          }

          final doctorName = (userData['name'] ?? 'Doctor').toString();
          final email = (userData['email'] ?? user.email ?? '').toString();
          final phone = (userData['phone'] ?? '').toString();
          final spec = (userData['specialization'] ?? 'General Physician').toString();
          final qual = (userData['qualifications'] ?? 'MBBS').toString();
          final exp = (userData['experience'] ?? 'Not specified').toString();
          final hospital = (userData['hospital'] ?? 'MediCare Hospital').toString();
          final fee = (userData['consultationFee'] ?? '500').toString();
          final daysList = (userData['availableDays'] is List)
              ? (userData['availableDays'] as List).join(', ')
              : 'Mon, Tue, Wed, Thu, Fri, Sat';

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('appointments')
                
.where(
  'doctorId',
  isEqualTo: userData['doctorId'] ?? 'dr_tejaswini_yedida',
)

                .snapshots(),
            builder: (context, apptSnapshot) {
              final allDocs = apptSnapshot.data?.docs ?? [];

              // Summary Counts
              int pendingCount = 0;
              int confirmedCount = 0;
              int completedCount = 0;
              int cancelledCount = 0;

              for (final d in allDocs) {
                final s = (d.data()['status'] ?? '').toString().toLowerCase();
                if (s == 'pending') {
                  pendingCount++;
                } else if (s == 'confirmed') {
                  confirmedCount++;
                } else if (s == 'completed') {
                  completedCount++;
                } else if (s == 'cancelled') {
                  cancelledCount++;
                }
              }

              // Filtered list
              final filteredDocs = allDocs.where((d) {
                if (selectedFilter == 'all') return true;
                final s = (d.data()['status'] ?? '').toString().toLowerCase();
                return s == selectedFilter;
              }).toList();

              // Sort newest first
              filteredDocs.sort((a, b) {
                final aDate = a.data()['createdAt'] as Timestamp?;
                final bDate = b.data()['createdAt'] as Timestamp?;
                if (aDate == null && bDate == null) return 0;
                if (aDate == null) return 1;
                if (bDate == null) return -1;
                return bDate.compareTo(aDate);
              });

              return CustomScrollView(
                slivers: [
                  // Profile Header
                  SliverToBoxAdapter(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDFF3F1),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                child: const Icon(Icons.person, color: teal, size: 36),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. $doctorName',
                                      style: const TextStyle(
                                        fontSize: 21,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF203333),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$spec • $qual',
                                      style: const TextStyle(color: teal, fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    Text(
                                      hospital,
                                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Edit Profile',
                                onPressed: () => _editProfile(context, user.uid, userData),
                                icon: const Icon(Icons.edit_note, color: teal, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('📞 ${phone.isEmpty ? "Phone not set" : phone}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('✉️ $email',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Exp: $exp',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              Text('Fee: ₹$fee',
                                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Available Days: $daysList',
                              style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),

                  // Dashboard Summary Cards
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Appointments Overview',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203333)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _statCard('Pending', pendingCount, Colors.orange, () {
                                setState(() => selectedFilter = 'pending');
                              }),
                              const SizedBox(width: 10),
                              _statCard('Confirmed', confirmedCount, teal, () {
                                setState(() => selectedFilter = 'confirmed');
                              }),
                              const SizedBox(width: 10),
                              _statCard('Completed', completedCount, Colors.blue, () {
                                setState(() => selectedFilter = 'completed');
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Filter Chips Row
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All (${allDocs.length})', 'all'),
                            const SizedBox(width: 8),
                            _filterChip('Pending ($pendingCount)', 'pending'),
                            const SizedBox(width: 8),
                            _filterChip('Confirmed ($confirmedCount)', 'confirmed'),
                            const SizedBox(width: 8),
                            _filterChip('Completed ($completedCount)', 'completed'),
                            const SizedBox(width: 8),
                            _filterChip('Cancelled ($cancelledCount)', 'cancelled'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Appointments List
                  if (apptSnapshot.connectionState == ConnectionState.waiting)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: teal)),
                    )
                  else if (filteredDocs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 14),
                              Text(
                                selectedFilter == 'all'
                                    ? 'No appointments yet'
                                    : 'No $selectedFilter appointments',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF203333)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Appointments booked by patients for your profile will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = filteredDocs[index];
                            final data = doc.data();

                            final patientName = (data['patientName'] ?? 'Patient').toString();
                            final patientEmail = (data['patientEmail'] ?? data['userEmail'] ?? '').toString();
                            final patientPhone = (data['patientPhone'] ?? '').toString();
                            final date = (data['appointmentDate'] ?? data['date'] ?? '').toString();
                            final time = (data['appointmentTime'] ?? data['time'] ?? '').toString();
                            final reason = (data['reason'] ?? '').toString();
                            final status = (data['status'] ?? 'pending').toString().toLowerCase();
                            final paymentStatus = (data['paymentStatus'] ?? 'unpaid').toString().toLowerCase();
                            final paymentReference = (data['paymentReference'] ?? '').toString();

                            Color statusColor;
                            Color statusBg;
                            if (status == 'confirmed') {
                              statusColor = teal;
                              statusBg = const Color(0xFFE0F5F4);
                            } else if (status == 'completed') {
                              statusColor = Colors.blue.shade700;
                              statusBg = Colors.blue.shade50;
                            } else if (status == 'cancelled') {
                              statusColor = Colors.red.shade700;
                              statusBg = Colors.red.shade50;
                            } else {
                              statusColor = Colors.orange.shade800;
                              statusBg = Colors.orange.shade50;
                            }

                            return Card(
                              color: Colors.white,
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade200),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Patient & Status Header
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            patientName,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF203333),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusBg,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    // Patient Contact Info
                                    if (patientEmail.isNotEmpty || patientPhone.isNotEmpty)
                                      Row(
                                        children: [
                                          if (patientPhone.isNotEmpty) ...[
                                            const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(patientPhone, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            const SizedBox(width: 10),
                                          ],
                                          if (patientEmail.isNotEmpty) ...[
                                            const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                patientEmail,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),

                                    const SizedBox(height: 10),
                                    const Divider(height: 1),
                                    const SizedBox(height: 10),

                                    // Date & Time
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_month, color: teal, size: 18),
                                        const SizedBox(width: 6),
                                        Text(date.isEmpty ? 'Date not set' : date,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        const SizedBox(width: 14),
                                        const Icon(Icons.access_time, color: teal, size: 18),
                                        const SizedBox(width: 6),
                                        Text(time.isEmpty ? 'Time not set' : time,
                                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),

                                    if (reason.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7FAFA),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Reason: $reason',
                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 10),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(color: paymentStatus == 'verified' ? Colors.green.shade50 : paymentStatus == 'submitted' ? Colors.orange.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(9)),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text('Payment: ${paymentStatus == 'verified' ? 'VERIFIED' : paymentStatus == 'submitted' ? 'AWAITING VERIFICATION' : 'NOT PAID'}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: paymentStatus == 'verified' ? Colors.green.shade800 : paymentStatus == 'submitted' ? Colors.orange.shade900 : Colors.black54)),
                                        if (paymentReference.isNotEmpty) Text('Reference: $paymentReference', style: const TextStyle(fontSize: 12)),
                                      ]),
                                    ),
                                    const SizedBox(height: 14),

                                    // Action buttons for doctor
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (paymentStatus == 'submitted')
                                          ElevatedButton.icon(
                                            onPressed: () => _verifyPayment(context, doc),
                                            icon: const Icon(Icons.verified, size: 16),
                                            label: const Text('Verify Payment'),
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                          ),
                                        // Pending -> Confirm or Reject
                                        if (status == 'pending') ...[
                                          ElevatedButton.icon(
                                            onPressed: () => _updateStatus(context, doc, 'confirmed'),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Confirm'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: teal,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _updateStatus(context, doc, 'cancelled'),
                                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                                            label: const Text('Reject', style: TextStyle(color: Colors.red)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],

                                        // Confirmed -> Complete or Cancel
                                        if (status == 'confirmed') ...[
                                          ElevatedButton.icon(
                                            onPressed: () => _updateStatus(context, doc, 'completed'),
                                            icon: const Icon(Icons.done_all, size: 16),
                                            label: const Text('Mark Completed'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue.shade700,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: () => _updateStatus(context, doc, 'cancelled'),
                                            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.red),
                                            label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Colors.red),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ],

                                        // WhatsApp patient
                                        if (patientPhone.isNotEmpty)
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              WhatsAppService.openPatientChat(
                                                context: context,
                                                patientPhone: patientPhone,
                                                patientName: patientName,
                                                doctorName: doctorName,
                                                date: date,
                                                time: time,
                                              );
                                            },
                                            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 16),
                                            label: const Text(
                                              'WhatsApp',
                                              style: TextStyle(color: Color(0xFF1E824C)),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(color: Color(0xFF25D366)),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),

                                        // View Details
                                        TextButton(
                                          onPressed: () => _showAppointmentDetails(context, doc.id, data),
                                          child: const Text('Details', style: TextStyle(color: teal)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          childCount: filteredDocs.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _statCard(String title, int count, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: teal,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? teal : Colors.grey.shade300,
      ),
      onSelected: (val) {
        if (val) setState(() => selectedFilter = value);
      },
    );
  }
}
