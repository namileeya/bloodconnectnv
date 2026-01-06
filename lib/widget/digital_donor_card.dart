// File: digital_donor_card.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bloodconnect/user_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigitalDonorCardWidget extends StatefulWidget {
  final bool showQrCode;
  final VoidCallback? onTap;
  final bool forceRefresh;

  const DigitalDonorCardWidget({
    super.key,
    this.showQrCode = true,
    this.onTap,
    this.forceRefresh = false,
  });

  @override
  State<DigitalDonorCardWidget> createState() => _DigitalDonorCardWidgetState();
}

class _DigitalDonorCardWidgetState extends State<DigitalDonorCardWidget> {
  String donorName = '';
  String donorId = '';
  String bloodType = '';
  String lastDonation = 'No donations yet';
  String qrCodeData = '';
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await UserSession.getUser();
      
      if (userData != null) {
        setState(() {
          // Get user data from session
          donorName = userData['full_name'] ?? userData['name'] ?? 'Unknown User';
          donorId = userData['id_number'] ?? userData['ic'] ?? userData['id'] ?? '000000-00-0000';
          bloodType = userData['blood_group'] ?? userData['blood_type'] ?? userData['bloodType'] ?? 'Unknown';
          qrCodeData = userData['qr_code_data'] ?? 'BLOODCONNECT:USER:unknown';
        });
        
        // Fetch last donation from Firestore
        await _fetchLastDonation(userData);
        
        setState(() {
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        lastDonation = 'Error loading data';
      });
    }
  }

  // SIMPLIFIED: Fetch last donation from Firestore using the most reliable identifier
  Future<void> _fetchLastDonation(Map<String, dynamic> userData) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Try to get user ID from multiple possible fields
      final userId = userData['uid'] ?? 
                    userData['id'] ?? 
                    userData['user_id'] ??
                    FirebaseAuth.instance.currentUser?.uid;
      
      // Try to get email as backup
      final userEmail = userData['email'] ?? '';
      
      QuerySnapshot querySnapshot;
      
      // FIRST TRY: Query by user ID (most reliable)
      if (userId != null && userId.isNotEmpty) {
        querySnapshot = await firestore
            .collection('donations')
            .where('donor_id', isEqualTo: userId)
            .orderBy('donation_date', descending: true)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          _updateLastDonation(querySnapshot.docs.first);
          return;
        }
      }
      
      // SECOND TRY: Query by email (backup)
      if (userEmail.isNotEmpty) {
        querySnapshot = await firestore
            .collection('donations')
            .where('donor_email', isEqualTo: userEmail)
            .orderBy('donation_date', descending: true)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          _updateLastDonation(querySnapshot.docs.first);
          return;
        }
      }
      
      // THIRD TRY: Check donor_profiles for last donation date
      if (userId != null && userId.isNotEmpty) {
        final donorProfileDoc = await firestore
            .collection('donor_profiles')
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();
            
        if (donorProfileDoc.docs.isNotEmpty) {
          final profileData = donorProfileDoc.docs.first.data();
          final profileLastDonation = profileData['last_donation'];
          if (profileLastDonation != null && profileLastDonation != '') {
            setState(() {
              lastDonation = profileLastDonation.toString();
            });
            return;
          }
        }
      }
      
      // If we get here, no donations found
      setState(() {
        lastDonation = 'No donations yet';
      });
      
    } catch (e) {
      print('Error fetching last donation: $e');
      setState(() {
        lastDonation = 'Error loading history';
      });
    }
  }

  void _updateLastDonation(QueryDocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final donationDate = data['donation_date'];
      
      if (donationDate != null) {
        DateTime date;
        
        // Handle Timestamp or DateTime
        if (donationDate is Timestamp) {
          date = donationDate.toDate();
        } else if (donationDate is DateTime) {
          date = donationDate;
        } else {
          // Try to parse string
          date = DateTime.parse(donationDate.toString());
        }
        
        // Format date as "DD MMM YYYY"
        final formattedDate = _formatDate(date);
        
        setState(() {
          lastDonation = formattedDate;
        });
      }
    } catch (e) {
      print('Error formatting donation date: $e');
      setState(() {
        lastDonation = 'Date error';
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDE0D0D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        height: 150,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFDE0D0D),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Digital Donor Card',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Last Donation: $lastDonation',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  height: 60,
                  width: 60,
                  padding: const EdgeInsets.all(4),
                  child: widget.showQrCode 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: QrImageView(
                          data: qrCodeData,
                          version: QrVersions.auto,
                          size: 52,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFDE0D0D),
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                          padding: const EdgeInsets.all(2),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.qr_code,
                          size: 40,
                          color: Color(0xFFDE0D0D),
                        ),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 15,
              child: Text(
                bloodType,
                style: const TextStyle(
                  color: Color(0xFFDE0D0D),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              donorName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'ID: $donorId',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}