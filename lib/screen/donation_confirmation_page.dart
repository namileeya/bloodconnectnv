import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import 'package:bloodconnect/user_session.dart';

class DonationConfirmationPage extends StatefulWidget {
  final String selectedCenter;
  final String selectedAddress;
  final DateTime selectedDate;
  final String selectedTime;
  final String hospitalId;

  const DonationConfirmationPage({
    super.key,
    required this.selectedCenter,
    required this.selectedAddress,
    required this.selectedDate,
    required this.selectedTime,
    required this.hospitalId,
  });

  @override
  State<DonationConfirmationPage> createState() => _DonationConfirmationPageState();
}

class _DonationConfirmationPageState extends State<DonationConfirmationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final int _currentStep = 3;
  bool _showSuccessDialog = false;
  bool _isSaving = false;
  
  String fullName = "User";
  String? bloodType;

  int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      // Try to get from session first
      final userData = await UserSession.getUser();
      if (userData != null) {
        setState(() {
          fullName = userData['full_name'] ?? userData['fullName'] ?? 'User';
          bloodType = userData['blood_group'] ?? userData['bloodType']; // Optional field
        });
        return;
      }

      // If not in session, fetch from Firestore donor_profiles
      if (_currentUserId != null) {
        // Query donor_profiles collection where user_id matches
        final profileQuery = await _firestore
            .collection('donor_profiles')
            .where('user_id', isEqualTo: _currentUserId)
            .limit(1)
            .get();
        
        if (profileQuery.docs.isNotEmpty) {
          final data = profileQuery.docs.first.data();
          setState(() {
            fullName = data['full_name'] ?? 'User';
            bloodType = data['blood_group']; // Optional field
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        fullName = 'User';
      });
    }
  }

  // Save appointment to Firebase
  Future<void> _saveAppointment() async {
    if (_currentUserId == null) {
      _showErrorDialog('Please log in to book an appointment.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure user profile is loaded before saving
      if (fullName == "User") {
        await _loadUserProfile();
      }

      // Double check we have the user's name
      String userName = fullName;
      String? userBloodType = bloodType;
      
      if (userName == "User" && _currentUserId != null) {
        // Fetch directly from donor_profiles as a fallback
        final profileQuery = await _firestore
            .collection('donor_profiles')
            .where('user_id', isEqualTo: _currentUserId)
            .limit(1)
            .get();
        
        if (profileQuery.docs.isNotEmpty) {
          final data = profileQuery.docs.first.data();
          userName = data['full_name'] ?? 'User';
          userBloodType = data['blood_group'];
        }
      }

      // Create appointment document
      final appointmentData = {
        'userId': _currentUserId,
        'userName': userName,
        'hospitalId': widget.hospitalId,
        'hospitalName': widget.selectedCenter,
        'hospitalAddress': widget.selectedAddress,
        'appointmentDate': Timestamp.fromDate(widget.selectedDate),
        'timeSlot': widget.selectedTime,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Add blood type if available
      if (userBloodType != null && userBloodType.isNotEmpty) {
        appointmentData['bloodType'] = userBloodType;
      }

      // Save to Firestore
      await _firestore.collection('appointments').add(appointmentData);

      setState(() {
        _isSaving = false;
        _showSuccessDialog = true;
      });
    } catch (e) {
      print('Error saving appointment: $e');
      setState(() {
        _isSaving = false;
      });
      _showErrorDialog('Failed to book appointment. Please try again.');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _getUserInitials() {
    List<String> nameParts = fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: CustomHeader(
            appName: 'BloodConnect',
            userInitials: _getUserInitials(),
            onRewardsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyRewardPage()),
              );
            },
            onNotificationsPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildProgressIndicator(),
                  const SizedBox(height: 32),
                  
                  _buildConfirmationDetails(),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: _selectedNavIndex,
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        
        // Loading overlay
        if (_isSaving)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDE0D0D),
              ),
            ),
          ),
        
        // Success dialog overlay
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }

  Widget _buildSuccessPopup() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 300,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  
                  const Text(
                    'Booking Successful',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  Text(
                    'You will be notified once the admin confirms your appointment.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 3)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
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

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStepIndicator(1, 'Location', isPast: true),
        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFFDE0D0D),
          ),
        ),
        _buildStepIndicator(2, 'Date', isPast: true),
        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFFDE0D0D),
          ),
        ),
        _buildStepIndicator(3, 'Confirmation'),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, {bool isPast = false}) {
    final bool isCurrent = step == _currentStep;
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isPast 
                ? Colors.red 
                : (isCurrent ? const Color(0xFFDE0D0D) : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isPast || isCurrent ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirm Appointment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Appointment Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    _buildDetailRow('Location:', widget.selectedCenter),
                    const SizedBox(height: 12),
                    _buildDetailRow('Date:', _formatDate(widget.selectedDate)),
                    const SizedBox(height: 12),
                    _buildDetailRow('Time:', widget.selectedTime),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Important Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBulletPoint('Please bring a valid ID or Passport'),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Eat a healthy meal before donating'),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Drink plenty of fluids before and after'),
                    const SizedBox(height: 8),
                    _buildBulletPoint('Avoid strenuous activity for 24 hours after donating'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    List<String> weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    List<String> months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    
    String weekday = weekdays[date.weekday - 1];
    String day = date.day.toString();
    String month = months[date.month - 1];
    String year = date.year.toString();
    
    return '$weekday, $day $month, $year';
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveAppointment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}