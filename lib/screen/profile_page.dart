import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'change_password.dart';
import 'landing_page.dart';
import 'edit_information.dart';
import 'update_medical_info.dart';
import 'donation_history_page.dart';
import '../widget/headertwo.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  Map<String, dynamic>? donorData;
  bool isLoading = true;
  
  // Donation statistics
  int donationCount = 0;
  double totalBloodDonated = 0.0; // in liters
  int livesSaved = 0;
  String lastDonationDate = 'No donations yet';
  String formattedLastDonation = '';

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  // Fetch user data directly from Firebase
  Future<void> getUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        return;
      }

      // Fetch from users collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      // Fetch from donor_profiles collection
      DocumentSnapshot donorDoc = await _firestore
          .collection('donor_profiles')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
          donorData = donorDoc.data() as Map<String, dynamic>?;
        });
      }

      // Fetch donation statistics
      await _fetchDonationStatistics(currentUser.uid);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
      }
    }
  }

  // Fetch donation statistics from Firestore
  Future<void> _fetchDonationStatistics(String userId) async {
    try {
      // Query ALL donations by donor_id
      QuerySnapshot donationsSnapshot = await _firestore
          .collection('donations')
          .where('donor_id', isEqualTo: userId)
          .orderBy('donation_date', descending: true)
          .get();

      // Calculate statistics
      int totalDonations = donationsSnapshot.docs.length;
      double totalML = 0.0;
      int usedDonationsCount = 0;
      
      // Calculate totals and find last donation
      DateTime? lastDonationDate;
      
      for (var doc in donationsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Add to total blood donated
        final amountML = data['amount_ml'] ?? 0;
        totalML += (amountML is int) ? amountML.toDouble() : (amountML as num).toDouble();
        
        // Count used donations for lives saved
        final status = data['status']?.toString().toLowerCase();
        final used = data['used'] ?? false;
        if (status == 'used' || used == true) {
          usedDonationsCount++;
        }
        
        // Get last donation date
        final donationDate = data['donation_date'];
        if (donationDate != null) {
          DateTime date;
          
          // Handle Timestamp or DateTime
          if (donationDate is Timestamp) {
            date = donationDate.toDate();
          } else if (donationDate is DateTime) {
            date = donationDate;
          } else {
            try {
              date = DateTime.parse(donationDate.toString());
            } catch (e) {
              continue; // Skip if date parsing fails
            }
          }
          
          // Update last donation date if this is more recent
          if (lastDonationDate == null || date.isAfter(lastDonationDate!)) {
            lastDonationDate = date;
            formattedLastDonation = _formatDate(date);
          }
        }
      }
      
      // Convert ml to liters
      double totalLiters = totalML / 1000;
      
      if (mounted) {
        setState(() {
          donationCount = totalDonations; // Total count of donations
          totalBloodDonated = totalLiters;
          livesSaved = usedDonationsCount; // Count of used donations only
        });
      }
      
    } catch (e) {
      print('Error fetching donation statistics: $e');
      // Keep default values
      if (mounted) {
        setState(() {
          donationCount = 0;
          totalBloodDonated = 0.0;
          livesSaved = 0;
          formattedLastDonation = '';
        });
      }
    }
  }

  // Helper function to format date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Helper to format blood donated for display
  String get formattedBloodDonated {
    if (totalBloodDonated < 1) {
      // Show as ml if less than 1 liter
      return '${(totalBloodDonated * 1000).round()}ml';
    } else if (totalBloodDonated == totalBloodDonated.truncate()) {
      // Show as whole number if exact liter
      return '${totalBloodDonated.toInt()}L';
    } else {
      // Show with one decimal place
      return '${totalBloodDonated.toStringAsFixed(1)}L';
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        return;
      }

      // Delete user data from Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();
      await _firestore.collection('donor_profiles').doc(currentUser.uid).delete();
      
      // Delete donations history
      QuerySnapshot donations = await _firestore
          .collection('donations')
          .where('donor_id', isEqualTo: currentUser.uid)
          .get();
      
      for (var doc in donations.docs) {
        await doc.reference.delete();
      }

      // Delete Firebase Auth user
      await currentUser.delete();

      if (mounted) {
        setState(() {
          _showDeleteAccountSuccessDialog = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.toString()}')),
        );
      }
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        setState(() {
          _showLogoutSuccessDialog = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: ${e.toString()}')),
        );
      }
    }
  }

  // User data getters
  String get email => userData?['email'] ?? 'Not provided';
  String get phoneNumber => userData?['phone_number'] ?? 'Not provided';
  String get address => userData?['address'] ?? 'Not provided';
  String get state => userData?['state'] ?? 'Not provided';
  String get postcode => userData?['postcode'] ?? 'Not provided';
 
  // Donor profile getters
  String get bloodType => donorData?['blood_group'] ?? 'Not provided';
  String get rhesus => donorData?['rhesus'] ?? 'Not provided';
  String get weight => donorData?['weight']?.toString() ?? 'Not provided';
  String get height => donorData?['height']?.toString() ?? 'Not provided';
  String get medicalConditions => donorData?['medical_conditions'] ?? 'None';
  String get allergies => donorData?['allergies'] ?? 'None';

  String get fullName => donorData?['full_name'] ?? 'Not provided';
  String get idNumber => donorData?['id_number'] ?? 'Not provided';
  String get bloodBankId => donorData?['blood_bank_id'] ?? 'Not provided';
  String get gender => donorData?['gender'] ?? 'Not provided';
  String get dateOfBirth => donorData?['birth_date'] ?? 'Not provided';
  
  // Toggle states for notification preferences

  
  // Selected nav index - Profile is at index 4
  final int _selectedNavIndex = 4;

  // State for success dialogs
  bool _showLogoutSuccessDialog = false;
  bool _showDeleteAccountSuccessDialog = false;

  // Simplified navigation handler that updates the selected index
  void _updateNavIndex(int index) {
    setState(() {
      // The navigation will be handled by the NavigationHelper
    });
  }

  // Show logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon in circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirmation text
                const Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    // Yes button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Show success dialog before navigating
                          setState(() {
                            _showLogoutSuccessDialog = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cancel button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  // Show delete account confirmation dialog
  void _showDeleteAccountConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon in circle
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high,
                      color: Colors.black,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Confirmation text
                const Text(
                  'Are you sure you want to delete your account?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Action buttons
                Row(
                  children: [
                    // Yes button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Show success dialog before navigating
                          setState(() {
                            _showDeleteAccountSuccessDialog = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Yes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Cancel button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDE0D0D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  // Logout Success Popup
  Widget _buildLogoutSuccessPopup() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5), // Semi-transparent barrier
        ),
        
        // Popup content - White card with green checkmark
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 250,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon (green checkmark in circle with border)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Success message
                  const Text(
                    'Logout Successful',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 2 seconds
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 2)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // Navigate to landing page after delay
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LandingPage()),
                            (route) => false, // Remove all previous routes
                          );
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Delete Account Success Popup
  Widget _buildDeleteAccountSuccessPopup() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5), // Semi-transparent barrier
        ),
        
        // Popup content - White card with green checkmark
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 250,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon (green checkmark in circle with border)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Success message
                  const Text(
                    'Account Deleted',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 2 seconds
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 2)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // Navigate to landing page after delay
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const LandingPage()),
                            (route) => false, // Remove all previous routes
                          );
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: const Color(0xFFDE0D0D),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Red header with profile info - UPDATED with real donation data
                HeaderTwo(
                  fullName: fullName,
                  bloodType: bloodType,
                  donorStatus: donationCount > 0 ? "Regular Donor" : "New Donor",
                  donationCount: donationCount, // Real donation count from database
                  //lastDonationDate: formattedLastDonation.isNotEmpty 
                      //? formattedLastDonation 
                     // : 'No donations yet',
                ),
                // Content cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // Personal Information Card
                      _buildInfoCard("Personal Information", [
                        _buildInfoRow("Full Name", fullName),
                        _buildInfoRow("IC Number or Passport", idNumber),
                        _buildInfoRow("ID Number", bloodBankId),
                        _buildInfoRow("Gender", gender),
                        _buildInfoRow("Date of Birth", dateOfBirth),
                        _buildInfoRow("Email", email),
                        _buildInfoRow("Phone Number", phoneNumber),
                         _buildInfoRow("Address", address),
                      ], "Edit Information", Colors.blue),
                        
                      const SizedBox(height: 16),
                        
                      // Medical Information Card
                      _buildInfoCard("Medical Information", [
                        _buildInfoRow("Blood Type", bloodType),
                        _buildInfoRow("Rhesus", rhesus),
                        _buildInfoRow("Height (cm)", height),
                        _buildInfoRow("Weight (kg)", weight),
                        _buildInfoRow("Medical Conditions", medicalConditions),
                        _buildInfoRow("Allergies", allergies),
                      ], "Update Medical Info", Colors.blue),
                        
                      const SizedBox(height: 16),

                      // Donation Statistics Card - UPDATED with real data
                      _buildDonationStatsCard(),

                      const SizedBox(height: 16),
                        
                      // Settings & Preferences Card
                      _buildSettingsCard(),
                        
                      const SizedBox(height: 16),
                        
                      // Account Action Buttons
                      _buildAccountActionButtons(),
                        
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _selectedNavIndex,
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        // Show success dialogs if activated
        if (_showLogoutSuccessDialog)
          _buildLogoutSuccessPopup(),
          
        if (_showDeleteAccountSuccessDialog)
          _buildDeleteAccountSuccessPopup(),
      ],
    );
  }


  // Information card with title, content and action button
  Widget _buildInfoCard(String title, List<Widget> content, String actionText, Color actionColor) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...content,
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                    if (actionText == "Edit Information") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditInformation(
                        fullName: fullName,
                        idNumber: idNumber,
                        bloodBankId: bloodBankId,
                        gender: gender,
                        email: email,
                        phoneNumber: phoneNumber,
                        address: address,
                      ),
                    ),
                  );
                } else if (actionText == "Update Medical Info") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UpdateMedicalInfo(
                         bloodType: bloodType,
                          rhesus: rhesus,
                          height: height,
                          weight: weight,
                          medicalConditions: medicalConditions,
                          allergies: allergies,
                      ),
                    ),
                  );
                }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(20, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: actionColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Single information row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Donation Statistics Card - UPDATED with real data
  Widget _buildDonationStatsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Donation Statistics",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Statistics row with REAL data
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(donationCount.toString(), "Total\nDonations"),
                _buildDivider(),
                _buildStatColumn(formattedBloodDonated, "Blood\nDonated"),
                _buildDivider(),
                _buildStatColumn(livesSaved.toString(), "Lives\nSaved"),
              ],
            ),
            
            // Last donation info
            if (formattedLastDonation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: Text(
                    "Last donation: $formattedLastDonation",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // View history button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DonationHistoryPage()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(20, 20),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "View Donation History",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Statistic column for donation stats
  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDE0D0D),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Vertical divider for statistics row
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[300],
    );
  }

  // Settings card with toggles
  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Change password button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to change password page
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePassword()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Change Password",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // Account action buttons (Delete Account, Log Out)
  Widget _buildAccountActionButtons() {
    return Row(
      children: [
        // Delete Account Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Show delete confirmation dialog
              _showDeleteAccountConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDE0D0D),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Delete Account",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Log Out Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Show logout confirmation dialog
              _showLogoutConfirmationDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDE0D0D),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Log Out",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}