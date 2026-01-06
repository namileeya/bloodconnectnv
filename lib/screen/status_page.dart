import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User data
  String fullName = "Loading...";
  String userId = "";
  
  // Selected filter
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Approved', 'Rejected'];
  
  // Loading and error states
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  
  // Requests data
  List<Map<String, dynamic>> _allRequests = [];
  
  // Refresh state
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeUserAndData();
  }

  // Initialize user data and fetch requests
  Future<void> _initializeUserAndData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Get current user
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }
      
      userId = user.uid;
      
      // Fetch user details
      await _fetchUserDetails();
      
      // Fetch all requests
      await _fetchAllRequests();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Failed to load data: ${e.toString()}";
      });
    }
  }

  // Fetch user details from donor_profiles collection
  Future<void> _fetchUserDetails() async {
    try {
      final doc = await _firestore
          .collection('donor_profiles')
          .doc(userId)
          .get();
          
      if (doc.exists) {
        setState(() {
          fullName = doc.data()?['full_name'] ?? "User";
        });
      } else {
        // Fallback to user email or display name
        final user = _auth.currentUser;
        fullName = user?.displayName ?? 
                   user?.email?.split('@').first ?? 
                   "User";
      }
    } catch (e) {
      // Use auth user info as fallback
      final user = _auth.currentUser;
      fullName = user?.displayName ?? 
                 user?.email?.split('@').first ?? 
                 "User";
    }
  }

  // Fetch all requests from different collections
  Future<void> _fetchAllRequests() async {
    try {
      _allRequests.clear();
      
      // Fetch from multiple collections in parallel
      await Future.wait([
        _fetchSlotBookings(),
        _fetchEligibilityRequests(),
        _fetchBloodRequests(),
        _fetchAppointments(),
        _fetchBloodDriveEvents(),
        _fetchTeams(),
        _fetchStories(),
      ]);
      
      // Sort by date (most recent first)
      _allRequests.sort((a, b) {
        final dateA = a['date'] as Timestamp? ?? Timestamp.now();
        final dateB = b['date'] as Timestamp? ?? Timestamp.now();
        return dateB.compareTo(dateA);
      });
      
      setState(() {});
    } catch (e) {
      throw Exception("Failed to fetch requests: $e");
    }
  }

  // Fetch slot bookings
  Future<void> _fetchSlotBookings() async {
    try {
      final querySnapshot = await _firestore
          .collection('slot_bookings')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapSlotBookingStatus(data['bookingStatus'] ?? 'pending');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Event Slot Booking',
          'title': data['eventTitle'] ?? 'Manual Donation Entry',
          'description': data['notes'] ?? 'Event slot booking',
          'status': status,
          'date': data['bookedAt'] ?? Timestamp.now(),
          'responseDate': data['updatedAt'],
          'icon': Icons.event,
          'collection': 'slot_bookings',
          'details': {
            'event': data['eventTitle'] ?? 'Manual Donation Entry',
            'location': data['eventLocation'] ?? 'Manual Entry',
            'date': _formatDate(data['bookingDate']),
            'timeSlot': data['selectedTime'] ?? 'N/A',
            'confirmationCode': data['confirmationCode'],
          }
        });
      }
    } catch (e) {
      print('Error fetching slot bookings: $e');
    }
  }

  // Fetch eligibility requests
  Future<void> _fetchEligibilityRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('eligibility_requests')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapEligibilityStatus(
          data['status'] ?? 'pending',
          data['admin_decision'] ?? ''
        );
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Eligibility Application',
          'title': data['hospitalName'] ?? 'Hospital',
          'description': 'Eligibility application review',
          'status': status,
          'date': data['submittedDate'] ?? Timestamp.now(),
          'responseDate': data['decision_date'],
          'icon': Icons.medical_services,
          'collection': 'eligibility_requests',
          'canResubmit': status == 'Rejected',
          'details': {
            'hospital': data['hospitalName'] ?? 'Hospital',
            'submittedDate': _formatTimestamp(data['submittedDate']),
            'gender': data['gender'] ?? 'Not specified',
            'decision': data['admin_decision'] ?? 'Pending',
            'reason': data['admin_notes'] ?? 'No reason provided',
          }
        });
      }
    } catch (e) {
      print('Error fetching eligibility requests: $e');
    }
  }

  // Fetch blood requests
  Future<void> _fetchBloodRequests() async {
    try {
      final querySnapshot = await _firestore
          .collection('blood_requests')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapBloodRequestStatus(data['status'] ?? 'pending');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Blood Request',
          'title': 'Patient: ${data['patient_name'] ?? 'Unknown'}',
          'description': data['reasons'] ?? 'Blood request',
          'status': status,
          'date': data['created_at'] ?? Timestamp.now(),
          'responseDate': data['updated_at'],
          'icon': Icons.local_hospital,
          'collection': 'blood_requests',
          'details': {
            'patient': data['patient_name'] ?? 'Unknown',
            'bloodType': data['blood_group'] ?? 'Not specified',
            'location': data['patient_location'] ?? 'Not specified',
            'reason': data['reasons'] ?? 'Not specified',
            'requester': data['requester_name'] ?? 'Unknown',
          }
        });
      }
    } catch (e) {
      print('Error fetching blood requests: $e');
    }
  }

  // Fetch appointments
  Future<void> _fetchAppointments() async {
    try {
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapAppointmentStatus(data['status'] ?? 'pending');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Hospital Appointment',
          'title': data['hospitalName'] ?? 'Hospital',
          'description': 'Blood donation appointment',
          'status': status,
          'date': data['appointmentDate'] ?? Timestamp.now(),
          'icon': Icons.calendar_today,
          'collection': 'appointments',
          'details': {
            'hospital': data['hospitalName'] ?? 'Hospital',
            'date': _formatTimestamp(data['appointmentDate']),
            'time': data['timeSlot'] ?? 'Not specified',
            'address': data['hospitalAddress'] ?? 'Not specified',
          }
        });
      }
    } catch (e) {
      print('Error fetching appointments: $e');
    }
  }

  // Fetch blood drive events
  Future<void> _fetchBloodDriveEvents() async {
    try {
      final querySnapshot = await _firestore
          .collection('blood_drive_events')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapEventStatus(data['status'] ?? 'submitted');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Event Creation',
          'title': data['title'] ?? 'Blood Drive Event',
          'description': data['description'] ?? 'Event creation request',
          'status': status,
          'date': data['createdAt'] ?? Timestamp.now(),
          'icon': Icons.campaign,
          'collection': 'blood_drive_events',
          'details': {
            'event': data['title'] ?? 'Blood Drive Event',
            'organizer': data['organizerName'] ?? 'Unknown',
            'location': data['location'] ?? 'Not specified',
            'capacity': '${data['expectedCapacity'] ?? 0} people',
            'dates': '${data['startDate']} - ${data['endDate']}',
          }
        });
      }
    } catch (e) {
      print('Error fetching blood drive events: $e');
    }
  }

  // Fetch teams
  Future<void> _fetchTeams() async {
    try {
      final querySnapshot = await _firestore
          .collection('teams')
          .where('createdById', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapTeamStatus(data['status'] ?? 'active');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Team Creation',
          'title': data['name'] ?? 'Team',
          'description': data['description'] ?? 'Team creation request',
          'status': status,
          'date': data['createdAt'] ?? Timestamp.now(),
          'icon': Icons.group,
          'collection': 'teams',
          'details': {
            'teamName': data['name'] ?? 'Team',
            'members': '${data['memberCount'] ?? 1} members',
            'description': data['description'] ?? 'No description',
          }
        });
      }
    } catch (e) {
      print('Error fetching teams: $e');
    }
  }

  // Fetch stories
  Future<void> _fetchStories() async {
    try {
      final querySnapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final status = _mapStoryStatus(data['status'] ?? 'pending');
        
        _allRequests.add({
          'id': doc.id,
          'type': 'Story Submission',
          'title': data['title'] ?? 'My Story',
          'description': data['description'] ?? 'Personal donation story',
          'status': status,
          'date': data['createdAt'] ?? Timestamp.now(),
          'responseDate': data['statusChangedAt'],
          'icon': Icons.book,
          'collection': 'stories',
          'details': {
            'title': data['title'] ?? 'My Story',
            'category': data['category'] ?? 'General',
            'status': data['status'] ?? 'pending',
            'submitted': _formatTimestamp(data['createdAt']),
          }
        });
      }
    } catch (e) {
      print('Error fetching stories: $e');
    }
  }

  // Status mapping functions
  String _mapSlotBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return 'Approved';
      case 'cancelled':
      case 'rejected':
        return 'Rejected';
      case 'pending':
      default:
        return 'Pending';
    }
  }

  String _mapEligibilityStatus(String status, String decision) {
    if (decision.toLowerCase() == 'approved') return 'Approved';
    if (decision.toLowerCase() == 'deferred') return 'Rejected';
    return 'Pending';
  }

  String _mapBloodRequestStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
      case 'cancelled':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _mapAppointmentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        return 'Approved';
      case 'cancelled':
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _mapEventStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return 'Approved';
      case 'rejected':
      case 'cancelled':
        return 'Rejected';
      case 'submitted':
      default:
        return 'Pending';
    }
  }

  String _mapTeamStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return 'Approved';
      case 'rejected':
      case 'inactive':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _mapStoryStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'published':
        return 'Approved';
      case 'rejected':
      case 'declined':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  // Helper methods
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    return dateString;
  }

  String _getUserInitials() {
    if (fullName == "Loading...") return "U";
    
    List<String> nameParts = fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Add this method for NavigationHelper compatibility
  void _updateNavIndex(int index) {
    // This method can be empty since we're not updating any state for this page
    // It's just required by the NavigationHelper
  }

  // Filter requests based on selected filter
  List<Map<String, dynamic>> _getFilteredRequests() {
    if (_selectedFilter == 'All') return _allRequests;
    return _allRequests.where((req) => req['status'] == _selectedFilter).toList();
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status icon
  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Handle refresh
  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await _fetchAllRequests();
    } catch (e) {
      print('Refresh error: $e');
    }
    
    setState(() {
      _isRefreshing = false;
    });
  }

  // Handle resubmission
  void _handleResubmission(Map<String, dynamic> request) {
    if (request['collection'] == 'eligibility_requests') {
      // TODO: Navigate to eligibility form for resubmission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to eligibility form...'),
          backgroundColor: Color(0xFFDE0D0D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredRequests = _getFilteredRequests();
    
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
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _buildContent(filteredRequests),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: -1,
        onTap: (index) {
          // Custom navigation for Status page since it's not in bottom nav
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            // Donation History - not applicable for Status page
            // You can navigate to history or stay here
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MyRewardPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFFDE0D0D),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading your requests...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initializeUserAndData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> filteredRequests) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFFDE0D0D),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
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
                      'Status',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Track your submission status and approvals',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      final count = filter == 'All' 
                          ? _allRequests.length 
                          : _allRequests.where((req) => req['status'] == filter).length;
                          
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: FilterChip(
                          label: Text('$filter ($count)'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFDE0D0D).withOpacity(0.1),
                          checkmarkColor: const Color(0xFFDE0D0D),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFDE0D0D) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Request list
                Expanded(
                  child: filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = filteredRequests[index];
                            return _buildRequestCard(request);
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Refresh overlay
          if (_isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                color: const Color(0xFFDE0D0D),
                backgroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    
    switch (_selectedFilter) {
      case 'Pending':
        message = 'No pending requests';
        subtitle = 'All your requests have been processed';
        break;
      case 'Approved':
        message = 'No approved requests';
        subtitle = 'You don\'t have any approved requests yet';
        break;
      case 'Rejected':
        message = 'No rejected requests';
        subtitle = 'Great! None of your requests were rejected';
        break;
      default:
        message = 'No requests found';
        subtitle = 'You haven\'t submitted any requests yet';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_allRequests.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Explore Features'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final date = request['date'] as Timestamp? ?? Timestamp.now();
    final responseDate = request['responseDate'] as Timestamp?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  request['icon'],
                  color: statusColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['type'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        request['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  request['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Request details
                _buildRequestDetails(request),
                
                const SizedBox(height: 16),
                
                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _buildDateInfo(
                        'Submitted',
                        _formatTimestamp(date),
                        Icons.upload,
                        Colors.blue,
                      ),
                    ),
                    if (responseDate != null) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateInfo(
                          'Responded',
                          _formatTimestamp(responseDate),
                          Icons.reply,
                          statusColor,
                        ),
                      ),
                    ],
                  ],
                ),
                
                // Action buttons for specific statuses
                if (status == 'Rejected' && request['canResubmit'] == true)
                  _buildActionButton(request),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetails(Map<String, dynamic> request) {
    final details = request['details'] as Map<String, dynamic>;
    final type = request['type'] as String;
    
    final List<Widget> detailWidgets = [];
    
    details.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        detailWidgets.add(_buildDetailRow('${_capitalize(key)}:', value.toString()));
      }
    });
    
    return Column(
      children: detailWidgets,
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).replaceAll('_', ' ');
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            date,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> request) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _handleResubmission(request),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Resubmit Request'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDE0D0D),
            side: const BorderSide(color: Color(0xFFDE0D0D)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}