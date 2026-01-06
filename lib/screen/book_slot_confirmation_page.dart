import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';

class BookSlotConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> event;
  final String selectedTimeSlot;

  const BookSlotConfirmationPage({
    super.key,
    required this.event,
    required this.selectedTimeSlot,
  });

  @override
  State<BookSlotConfirmationPage> createState() => _BookSlotConfirmationPageState();
}

class _BookSlotConfirmationPageState extends State<BookSlotConfirmationPage> {
  bool _showSuccessDialog = false;
  bool _isProcessing = false;
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // User data from Firebase
  String fullName = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user profile from Firebase
  Future<void> _loadUserProfile() async {
    if (_currentUserId == null) return;
    
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          fullName = userData['fullName'] ?? 'User';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        fullName = 'User';
      });
    }
  }

  // Get user initials from full name
  String _getUserInitials() {
    if (fullName.isEmpty) return 'U';
    
    List<String> nameParts = fullName.trim().split(' ');
    
    if (nameParts.isEmpty || nameParts[0].isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0].substring(0, 1).toUpperCase() : 'U';
    }
    
    String firstInitial = nameParts.first.isNotEmpty 
        ? nameParts.first.substring(0, 1).toUpperCase() 
        : '';
    
    String lastInitial = nameParts.last.isNotEmpty 
        ? nameParts.last.substring(0, 1).toUpperCase() 
        : '';
    
    if (firstInitial.isEmpty && lastInitial.isEmpty) return 'U';
    if (firstInitial.isEmpty) return lastInitial;
    if (lastInitial.isEmpty) return firstInitial;
    
    return '$firstInitial$lastInitial';
  }

  // Generate unique confirmation code
  String _generateConfirmationCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'BDC${timestamp.toString().substring(timestamp.toString().length - 8)}';
  }

  // Confirm booking and save to Firebase
  Future<void> _confirmBooking() async {
    if (_currentUserId == null) {
      _showErrorDialog('Please log in to confirm booking');
      return;
    }

    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Check if event is full
      final currentParticipants = widget.event['currentParticipants'] ?? 0;
      final expectedCapacity = widget.event['expectedCapacity'] ?? 0;
      
      if (currentParticipants >= expectedCapacity) {
        _showErrorDialog('Sorry, this event is now full');
        setState(() => _isProcessing = false);
        return;
      }

      // Check for duplicate booking (double-check)
      final existingBooking = await _firestore
          .collection('slot_bookings')
          .where('userId', isEqualTo: _currentUserId)
          .where('eventId', isEqualTo: widget.event['id'])
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();

      if (existingBooking.docs.isNotEmpty) {
        _showErrorDialog('You have already booked this event');
        setState(() => _isProcessing = false);
        return;
      }

      // Generate confirmation code
      final confirmationCode = _generateConfirmationCode();

      // Create booking document
      await _firestore.collection('slot_bookings').add({
        'userId': _currentUserId,
        'eventId': widget.event['id'],
        'selectedTime': widget.selectedTimeSlot,
        'bookingDate': widget.event['startDate'],
        'eventTitle': widget.event['title'],
        'eventLocation': widget.event['location'],
        'bookingStatus': 'pending', // Pending until admin confirms
        'confirmationCode': confirmationCode,
        'bookedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Increment currentParticipants in event
      await _firestore
          .collection('blood_drive_events')
          .doc(widget.event['id'])
          .update({
        'currentParticipants': FieldValue.increment(1),
      });

      // Show success dialog
      setState(() {
        _isProcessing = false;
        _showSuccessDialog = true;
      });

    } catch (e) {
      print('Error confirming booking: $e');
      setState(() => _isProcessing = false);
      _showErrorDialog('Failed to confirm booking. Please try again.');
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

  void _updateNavIndex(int index) {
    // Required by NavigationHelper
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main page content
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
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.black,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Blood Donation Events',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Slot details card
                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Slot Details',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Event details
                            _buildDetailRow('Event Name:', widget.event['title'] ?? 'Blood Donation Campaign'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Location:', widget.event['location'] ?? 'Location'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Date:', widget.event['date'] ?? widget.event['startDate'] ?? 'Date'),
                            const SizedBox(height: 16),
                            _buildDetailRow('Time:', widget.selectedTimeSlot),
                            
                            const SizedBox(height: 32),
                            
                            // Important information box
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.all(16),
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
                                  const SizedBox(height: 16),
                                  
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _confirmBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE0D0D),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Confirm Booking',
                                  style: TextStyle(
                                    fontSize: 16,
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
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: -1,
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        
        // Success dialog overlay
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }

  // Success Popup
  Widget _buildSuccessPopup() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        
        // Popup content
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
                  // Success icon
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
                    'Booking Successful',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Additional message
                  Text(
                    'You will be notified once the admin confirms your booking.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 3 seconds
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 3)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Navigate back to home page
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const HomePage()),
                            (route) => false,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
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
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}