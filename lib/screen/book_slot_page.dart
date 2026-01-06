import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_slot_confirmation_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';

class BookSlotPage extends StatefulWidget {
  final Map<String, dynamic> event;
  
  const BookSlotPage({super.key, required this.event});

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  String? _selectedTimeSlot;
  List<String> _availableTimeSlots = [];
  bool _isLoading = true;
  bool _hasExistingBooking = false;
  String? _errorMessage;

  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User data from Firebase
  String fullName = "";

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _initializePage();
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

  // Initialize page - check for existing booking and generate slots
  Future<void> _initializePage() async {
    setState(() => _isLoading = true);
    
    await _checkExistingBooking();
    
    if (!_hasExistingBooking) {
      _generateTimeSlots();
    }
    
    setState(() => _isLoading = false);
  }

  // Check if user already has a booking for this event
  Future<void> _checkExistingBooking() async {
    if (_currentUserId == null) {
      setState(() {
        _errorMessage = 'Please log in to book a slot';
        _hasExistingBooking = true;
      });
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('slot_bookings')
          .where('userId', isEqualTo: _currentUserId)
          .where('eventId', isEqualTo: widget.event['id'])
          .where('bookingStatus', isEqualTo: 'confirmed')
          .get();

      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _hasExistingBooking = true;
          _errorMessage = 'You have already booked a slot for this event';
        });
      }
    } catch (e) {
      print('Error checking existing booking: $e');
      setState(() {
        _errorMessage = 'Error checking booking status';
      });
    }
  }

  // Generate time slots based on event start and end time (30-min intervals)
  void _generateTimeSlots() {
    List<String> slots = [];
    
    // Parse event time (format: "10:00 - 15:00")
    String eventTime = widget.event['time'] ?? '10:00 - 15:00';
    List<String> timeParts = eventTime.split(' - ');
    
    if (timeParts.length == 2) {
      TimeOfDay startTime = _parseTime(timeParts[0].trim());
      TimeOfDay endTime = _parseTime(timeParts[1].trim());
      
      // Generate 30-minute intervals
      DateTime currentSlot = DateTime(2024, 1, 1, startTime.hour, startTime.minute);
      DateTime endSlot = DateTime(2024, 1, 1, endTime.hour, endTime.minute);
      
      while (currentSlot.isBefore(endSlot)) {
        String timeStr = _formatTime(TimeOfDay(hour: currentSlot.hour, minute: currentSlot.minute));
        slots.add(timeStr);
        
        // Add 30 minutes
        currentSlot = currentSlot.add(const Duration(minutes: 30));
      }
    }
    
    setState(() {
      _availableTimeSlots = slots;
    });
  }

  // Parse time string to TimeOfDay (handles both 24h and AM/PM format)
  TimeOfDay _parseTime(String timeString) {
    try {
      // Remove any extra spaces
      timeString = timeString.trim();
      
      // Check if it's AM/PM format
      bool isPM = timeString.toUpperCase().contains('PM');
      bool isAM = timeString.toUpperCase().contains('AM');
      
      // Remove AM/PM from string
      timeString = timeString.replaceAll(RegExp(r'(AM|PM|am|pm)', caseSensitive: false), '').trim();
      
      // Split by colon
      final parts = timeString.split(':');
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      
      // Convert to 24-hour format if PM
      if (isPM && hour != 12) {
        hour += 12;
      } else if (isAM && hour == 12) {
        hour = 0;
      }
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      print('Error parsing time: $timeString - $e');
      return const TimeOfDay(hour: 10, minute: 0);
    }
  }

  // Format TimeOfDay to string
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // Get user initials from full name
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

  // Required by NavigationHelper
  void _updateNavIndex(int index) {
    // Empty - required by NavigationHelper
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDE0D0D)),
            )
          : SafeArea(
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
                    
                    // Event card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event['title'] ?? 'University Blood Donation Campaign',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEventInfoRow(Icons.calendar_today, widget.event['date'] ?? 'May 3, 2025'),
                          const SizedBox(height: 4),
                          _buildEventInfoRow(Icons.location_on, widget.event['location'] ?? 'UKM Campus, Bangi'),
                          const SizedBox(height: 4),
                          _buildEventInfoRow(Icons.access_time, widget.event['time'] ?? '10:00 - 15:00'),
                          const SizedBox(height: 4),
                          _buildEventInfoRow(Icons.local_hospital, widget.event['organizers'] ?? 'UKM Medical Centre'),
                          const SizedBox(height: 8),
                          _buildEventInfoRow(
                            Icons.people,
                            'Capacity: ${widget.event['currentParticipants'] ?? 0}/${widget.event['expectedCapacity'] ?? 0}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Show error message or time slot selection
                    if (_hasExistingBooking)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage ?? 'Already booked',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDE0D0D),
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                ),
                                child: const Text(
                                  'Go Back',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      // Choose time slot section
                      const Text(
                        'Choose Time Slot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Time slots grid
                      Expanded(
                        child: _availableTimeSlots.isEmpty
                            ? Center(
                                child: Text(
                                  'No time slots available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Center(
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: _availableTimeSlots
                                        .map((time) => _buildTimeSlotButton(time))
                                        .toList(),
                                  ),
                                ),
                              ),
                      ),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
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
                              onPressed: _selectedTimeSlot != null
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => BookSlotConfirmationPage(
                                            event: widget.event, 
                                            selectedTimeSlot: _selectedTimeSlot!,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDE0D0D),
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Continue',
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
                  ],
                ),
              ),
            ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: -1,
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }

  Widget _buildTimeSlotButton(String time) {
    final bool isSelected = _selectedTimeSlot == time;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTimeSlot = time;
        });
      },
      child: Container(
        width: 100,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDE0D0D) : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.normal,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildEventInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}