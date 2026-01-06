import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'book_slot_page.dart';
import 'create_new_event_page.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';

class BloodDrivePage extends StatefulWidget {
  const BloodDrivePage({super.key});

  @override
  State<BloodDrivePage> createState() => _BloodDrivePageState();
}

class _BloodDrivePageState extends State<BloodDrivePage> {
  int _selectedTabIndex = 0;
  String fullName = ""; // Load from Firebase session
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Data lists
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _pastEvents = [];
  List<Map<String, dynamic>> _myEvents = [];
  
  // Loading states
  bool _isLoadingUpcoming = true;
  bool _isLoadingPast = true;
  bool _isLoadingMyEvents = true;
  
  // Search query
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAllData();
  }

  // Load all data
  void _loadAllData() {
    _loadUpcomingEvents();
    _loadPastEvents();
    _loadMyEvents();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user profile from Firebase session
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

  // Load upcoming events (all events from today onwards)
  void _loadUpcomingEvents() async {
    if (_currentUserId == null) {
      print('DEBUG: No user logged in');
      return;
    }
    
    setState(() => _isLoadingUpcoming = true);
    
    try {
      // Get today's date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      print('DEBUG: Today date: $today');
      
      // Get ALL events (don't filter by status - show submitted, active, etc.)
      final QuerySnapshot snapshot = await _firestore
          .collection('blood_drive_events')
          .get();
      
      print('DEBUG: Total events in DB: ${snapshot.docs.length}');
      
      List<Map<String, dynamic>> events = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        print('DEBUG: Event - Title: ${data['title']}, Status: ${data['status']}, StartDate: ${data['startDate']}');
        
        // Parse the start date
        final startDate = _parseDate(data['startDate']);
        print('DEBUG: Parsed date: $startDate');
        
        // Only include events from today onwards (show all statuses for now)
        if (startDate != null && !startDate.isBefore(today)) {
          print('DEBUG: Adding event: ${data['title']}');
          events.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'date': data['startDate'] ?? '',
            'location': data['location'] ?? '',
            'time': '${data['startTime']} - ${data['endTime']}',
            'organizers': data['organizerName'] ?? '',
            'description': data['description'] ?? '',
            'currentParticipants': data['currentParticipants'] ?? 0,
            'expectedCapacity': data['expectedCapacity'] ?? 0,
            'startDate': data['startDate'],
            'endDate': data['endDate'],
            'startTime': data['startTime'],
            'endTime': data['endTime'],
          });
        } else {
          print('DEBUG: Skipping event. StartDate valid: ${startDate != null}, Is future: ${startDate != null && !startDate.isBefore(today)}, Status: ${data['status']}');
        }
      }
      
      // Sort by date (earliest first)
      events.sort((a, b) {
        final dateA = _parseDate(a['startDate']);
        final dateB = _parseDate(b['startDate']);
        if (dateA == null || dateB == null) return 0;
        return dateA.compareTo(dateB);
      });
      
      print('DEBUG: Total upcoming events found: ${events.length}');
      
      setState(() {
        _upcomingEvents = events;
        _isLoadingUpcoming = false;
      });
    } catch (e) {
      print('Error loading upcoming events: $e');
      setState(() => _isLoadingUpcoming = false);
    }
  }

  // Load past events (all events before today)
  void _loadPastEvents() async {
    if (_currentUserId == null) {
      print('DEBUG: No user logged in');
      return;
    }
    
    setState(() => _isLoadingPast = true);
    
    try {
      // Get today's date at midnight
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      print('DEBUG Past: Today date: $today');
      
      // Get ALL events from the database
      final QuerySnapshot snapshot = await _firestore
          .collection('blood_drive_events')
          .get();
      
      print('DEBUG Past: Total events in DB: ${snapshot.docs.length}');
      
      List<Map<String, dynamic>> events = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        print('DEBUG Past: Event - Title: ${data['title']}, StartDate: ${data['startDate']}');
        
        // Parse the end date (or start date if no end date)
        final endDate = _parseDate(data['endDate']) ?? _parseDate(data['startDate']);
        print('DEBUG Past: Parsed end date: $endDate');
        
        // Only include events that have ended (end date before today)
        if (endDate != null && endDate.isBefore(today)) {
          print('DEBUG Past: Adding past event: ${data['title']}');
          events.add({
            'id': doc.id,
            'title': data['title'] ?? '',
            'date': data['startDate'] ?? '',
            'location': data['location'] ?? '',
            'time': '${data['startTime']} - ${data['endTime']}',
            'organizers': data['organizerName'] ?? '',
            'description': data['description'] ?? '',
            'currentParticipants': data['currentParticipants'] ?? 0,
            'expectedCapacity': data['expectedCapacity'] ?? 0,
            'startDate': data['startDate'],
            'endDate': data['endDate'],
            'startTime': data['startTime'],
            'endTime': data['endTime'],
          });
        } else {
          print('DEBUG Past: Skipping event. EndDate valid: ${endDate != null}, Is past: ${endDate != null && endDate.isBefore(today)}');
        }
      }
      
      // Sort by date (most recent first)
      events.sort((a, b) {
        final dateA = _parseDate(a['endDate']) ?? _parseDate(a['startDate']);
        final dateB = _parseDate(b['endDate']) ?? _parseDate(b['startDate']);
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // Descending order (most recent first)
      });
      
      print('DEBUG Past: Total past events found: ${events.length}');
      
      setState(() {
        _pastEvents = events;
        _isLoadingPast = false;
      });
    } catch (e) {
      print('Error loading past events: $e');
      setState(() => _isLoadingPast = false);
    }
  }

  // Load my registered events from slot_bookings collection
  void _loadMyEvents() async {
    if (_currentUserId == null) {
      print('DEBUG My Events: No user logged in');
      return;
    }
    
    setState(() => _isLoadingMyEvents = true);
    
    try {
      print('DEBUG My Events: Loading bookings for user: $_currentUserId');
      
      // Get bookings from slot_bookings collection
      final QuerySnapshot snapshot = await _firestore
          .collection('slot_bookings')
          .where('userId', isEqualTo: _currentUserId)
          .get();
      
      print('DEBUG My Events: Found ${snapshot.docs.length} bookings');
      
      List<Map<String, dynamic>> events = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print('DEBUG My Events: Processing booking ${doc.id}, eventId: ${data['eventId']}');
        
        // Get the event details
        final eventId = data['eventId'];
        final eventDoc = await _firestore
            .collection('blood_drive_events')
            .doc(eventId)
            .get();
        
        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          print('DEBUG My Events: Event found: ${eventData['title']}');
          
          events.add({
            'id': eventDoc.id,
            'bookingId': doc.id,
            'title': eventData['title'] ?? data['eventTitle'] ?? '',
            'date': eventData['startDate'] ?? data['bookingDate'] ?? '',
            'location': eventData['location'] ?? data['eventLocation'] ?? '',
            'time': 'Booked: ${data['selectedTime'] ?? 'N/A'}',
            'organizers': eventData['organizerName'] ?? '',
            'status': _getBookingStatusText(data['bookingStatus'] ?? 'pending'),
            'bookingStatus': data['bookingStatus'] ?? 'pending',
            'selectedTimeSlot': data['selectedTime'] ?? '',
            'confirmationCode': data['confirmationCode'] ?? '',
            'bookedAt': data['bookedAt'] != null ? (data['bookedAt'] as Timestamp).toDate() : DateTime.now(),
          });
        } else {
          print('DEBUG My Events: Event not found for eventId: $eventId');
        }
      }
      
      // Sort by bookedAt date (most recent first)
      events.sort((a, b) => b['bookedAt'].compareTo(a['bookedAt']));
      
      print('DEBUG My Events: Total events loaded: ${events.length}');
      
      setState(() {
        _myEvents = events;
        _isLoadingMyEvents = false;
      });
    } catch (e) {
      print('Error loading my events: $e');
      setState(() => _isLoadingMyEvents = false);
    }
  }

  // Get user-friendly booking status text
  String _getBookingStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed - Ready to Donate';
      case 'pending':
        return 'Pending Admin Approval';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'no-show':
        return 'No Show';
      default:
        return 'Booked';
    }
  }

  // Parse date string to DateTime
  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    
    try {
      // Format 1: "25/12/2025" (DD/MM/YYYY)
      if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      }
      // Format 2: "May 3, 2025"
      else if (dateString.contains(',')) {
        final parts = dateString.split(',');
        final monthDay = parts[0].trim().split(' ');
        final year = int.parse(parts[1].trim());
        final day = int.parse(monthDay[1]);
        
        final monthMap = {
          'January': 1, 'February': 2, 'March': 3, 'April': 4,
          'May': 5, 'June': 6, 'July': 7, 'August': 8,
          'September': 9, 'October': 10, 'November': 11, 'December': 12
        };
        
        final month = monthMap[monthDay[0]] ?? 1;
        return DateTime(year, month, day);
      }
      // Format 3: "2025-05-03"
      else if (dateString.contains('-')) {
        return DateTime.parse(dateString);
      }
    } catch (e) {
      print('Error parsing date: $dateString, Error: $e');
    }
    
    return null;
  }

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

  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _navigateToCreateNewEvent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateNewEventPage(),
      ),
    );
    
    if (result != null) {
      // Reload data after creating new event
      _loadAllData();
    }
  }

  void _updateNavIndex(int index) {
    // Required by NavigationHelper
  }

  // Filter events based on search query
  List<Map<String, dynamic>> _filterEvents(List<Map<String, dynamic>> events) {
    if (_searchQuery.isEmpty) return events;
    
    return events.where((event) {
      final title = event['title']?.toString().toLowerCase() ?? '';
      final location = event['location']?.toString().toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || location.contains(query);
    }).toList();
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
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
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
              
              // Search box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search events by name or location',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 14),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Tab selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _buildTabButton('Upcoming', 0),
                    _buildTabButton('Past', 1),
                    _buildTabButton('My Events', 2),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Section header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedTabIndex == 2 ? 'My Booked Events' : 
                    _selectedTabIndex == 0 ? 'Upcoming Events' : 'Past Events',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // Create New button only on My Events tab
                  if (_selectedTabIndex == 2)
                    ElevatedButton.icon(
                      onPressed: _navigateToCreateNewEvent,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Create New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDE0D0D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Events list
              Expanded(
                child: _buildTabContent(),
              ),
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

  // Build content based on selected tab
  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      if (_isLoadingUpcoming) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
      }
      final filteredEvents = _filterEvents(_upcomingEvents);
      if (filteredEvents.isEmpty) {
        return _buildEmptyState('No upcoming events found');
      }
      return _buildEventList(filteredEvents, showBookButton: true);
    } else if (_selectedTabIndex == 1) {
      if (_isLoadingPast) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
      }
      final filteredEvents = _filterEvents(_pastEvents);
      if (filteredEvents.isEmpty) {
        return _buildEmptyState('No past donations found');
      }
      return _buildEventList(filteredEvents, showBookButton: false);
    } else {
      if (_isLoadingMyEvents) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
      }
      final filteredEvents = _filterEvents(_myEvents);
      if (filteredEvents.isEmpty) {
        return _buildNoEventsView();
      }
      return _buildEventList(filteredEvents, showBookButton: false, showStatus: true);
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEventsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Events Booked',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t booked any time slots yet',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE0D0D),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventList(List<Map<String, dynamic>> events, {required bool showBookButton, bool showStatus = false}) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        
        // Check if event is full (for Book Slot button)
        final isFull = showBookButton && 
            (event['currentParticipants'] ?? 0) >= (event['expectedCapacity'] ?? 0);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEventInfoRow(Icons.calendar_today, event['date']),
                const SizedBox(height: 4),
                _buildEventInfoRow(Icons.location_on, event['location']),
                const SizedBox(height: 4),
                _buildEventInfoRow(Icons.access_time, event['time']),
                const SizedBox(height: 4),
                _buildEventInfoRow(Icons.local_hospital, event['organizers']),
                if (showStatus && event.containsKey('status'))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: _getStatusColor(event['bookingStatus']),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Status: ${event['status']}',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (showBookButton) 
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isFull ? null : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookSlotPage(event: event),
                              ),
                            );
                            
                            // Reload data if booking was successful
                            if (result == true) {
                              _loadAllData();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE0D0D),
                            disabledBackgroundColor: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isFull ? 'Event Full' : 'Book Slot',
                            style: TextStyle(
                              color: isFull ? Colors.grey[600] : Colors.white,
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'no-show':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEventInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[800], fontSize: 14),
          ),
        ),
      ],
    );
  }
}