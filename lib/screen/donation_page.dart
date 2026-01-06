import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_date_page.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/header.dart';
import 'package:bloodconnect/user_session.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String fullName = "User";
  final int _currentStep = 1;
  
  // Selected donation center data
  String? _selectedCenterId;
  String? _selectedCenter;
  String? _selectedAddress;
  String? _selectedStartTime;
  String? _selectedEndTime;
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 2;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Hospital list
  List<Map<String, dynamic>> _hospitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadHospitals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      // Try to get from session first
      final userData = await UserSession.getUser();
      if (userData != null && userData['fullName'] != null) {
        setState(() {
          fullName = userData['fullName'];
        });
        return;
      }

      // If not in session, fetch from Firestore
      if (_currentUserId != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            fullName = data['fullName'] ?? 'User';
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

  // Load hospitals from Firebase
  Future<void> _loadHospitals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final QuerySnapshot snapshot = await _firestore
          .collection('hospitals')
          .get();

      List<Map<String, dynamic>> hospitalsList = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        hospitalsList.add({
          'id': doc.id,
          'name': data['name'] ?? '',
          'address': data['address'] ?? '',
          'city': data['city'] ?? '',
          'state': data['state'] ?? '',
          'officeStartTime': data['officeStartTime'] ?? '08:00',
          'officeEndTime': data['officeEndTime'] ?? '17:00',
        });
      }

      setState(() {
        _hospitals = hospitalsList;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading hospitals: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading hospitals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  // Check if hospital is currently open
  bool _isHospitalOpen(String startTime, String endTime) {
    try {
      final now = TimeOfDay.now();
      final start = _parseTime(startTime);
      final end = _parseTime(endTime);
      
      final nowMinutes = now.hour * 60 + now.minute;
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes = end.hour * 60 + end.minute;
      
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } catch (e) {
      return false;
    }
  }

  // Parse time string to TimeOfDay
  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  // Filter hospitals by search query
  List<Map<String, dynamic>> _getFilteredHospitals() {
    if (_searchQuery.isEmpty) {
      return _hospitals;
    }
    
    return _hospitals.where((hospital) {
      final name = hospital['name'].toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  // Navigation handler
  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
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
      body: SingleChildScrollView(
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
                    'Book Appointment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Progress Indicator
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              
              // Content based on current step
              _currentStep == 1 ? _buildLocationStep() : Container(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStepIndicator(1, 'Location'),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[300],
          ),
        ),
        _buildStepIndicator(2, 'Date'),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[300],
          ),
        ),
        _buildStepIndicator(3, 'Confirmation'),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final bool isActive = step == _currentStep;
    final bool isPast = step < _currentStep;
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive 
                ? const Color(0xFFDE0D0D) 
                : (isPast ? Colors.green : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive || isPast ? Colors.white : Colors.black54,
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
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    final filteredHospitals = _getFilteredHospitals();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Donation Center',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Search for location',
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Loading indicator or hospital list
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFFDE0D0D),
                  ),
                ),
              )
            : filteredHospitals.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        _searchQuery.isEmpty 
                            ? 'No donation centers available'
                            : 'No results found for "$_searchQuery"',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var hospital in filteredHospitals) ...[
                        _buildDonationCenterCard(
                          hospital['id'],
                          hospital['name'],
                          hospital['address'],
                          '${hospital['officeStartTime']} - ${hospital['officeEndTime']}',
                          _isHospitalOpen(
                            hospital['officeStartTime'],
                            hospital['officeEndTime'],
                          ),
                          hospital['officeStartTime'],
                          hospital['officeEndTime'],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
        
        const SizedBox(height: 40),
        
        // Continue button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _selectedCenter != null 
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationDatePage(
                        hospitalId: _selectedCenterId!,
                        selectedCenter: _selectedCenter!,
                        selectedAddress: _selectedAddress!,
                        officeStartTime: _selectedStartTime!,
                        officeEndTime: _selectedEndTime!,
                      ),
                    ),
                  );
                }
              : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedCenter != null 
                  ? const Color(0xFFDE0D0D) 
                  : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _selectedCenter != null ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonationCenterCard(
    String id,
    String name,
    String address,
    String hours,
    bool isOpen,
    String startTime,
    String endTime,
  ) {
    final bool isSelected = _selectedCenterId == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCenterId = id;
          _selectedCenter = name;
          _selectedAddress = address;
          _selectedStartTime = startTime;
          _selectedEndTime = endTime;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hours,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOpen ? 'OPEN' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOpen ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}