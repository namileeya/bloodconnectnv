import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../widget/header.dart';
import '../navigation_helper.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({super.key});

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _fullName = "";
  String _currentUserId = "";
  List<Map<String, dynamic>> _donationHistory = [];
  bool _isLoading = true;
  int _totalDonations = 0;
  double _totalBloodGiven = 0;
  int _livesSaved = 0;
  String _errorMessage = "";
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 1; // History tab is selected (index 1)

  @override
  void initState() {
    super.initState();
    _loadUserDataAndDonations();
  }

  Future<void> _loadUserDataAndDonations() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = "";
      });

      final currentUser = _auth.currentUser;
      print('Current user: ${currentUser?.uid}');
      
      if (currentUser == null) {
        setState(() {
          _errorMessage = "User not logged in";
          _isLoading = false;
          _fullName = "Guest User";
        });
        return;
      }

      _currentUserId = currentUser.uid;
      print('Fetching donations for user ID: $_currentUserId');

      // Get user data from Firestore (users collection)
      try {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        print('User document exists: ${userDoc.exists}');
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          print('User data: $userData');
          setState(() {
            _fullName = userData?['fullName'] ?? 
                       userData?['name'] ?? 
                       userData?['displayName'] ?? 
                       currentUser.displayName ?? 
                       "User";
          });
        } else {
          setState(() {
            _fullName = currentUser.displayName ?? "User";
          });
        }
      } catch (e) {
        print('Error fetching user data: $e');
        setState(() {
          _fullName = currentUser.displayName ?? "User";
        });
      }

      // Fetch donation history for current user
      print('Querying donations collection...');
      final donationsQuery = await _firestore
          .collection('donations')
          .where('donor_id', isEqualTo: currentUser.uid)
          .orderBy('donation_date', descending: true)
          .get();

      print('Total documents found: ${donationsQuery.docs.length}');
      
      final List<Map<String, dynamic>> donations = [];
      int totalDonations = 0;
      double totalBloodGiven = 0;
      int usedDonations = 0; // Count donations with "used" status

      for (final doc in donationsQuery.docs) {
        print('Processing document: ${doc.id}');
        final data = doc.data();
        print('Document data: $data');
        
        // Check if donation_date exists
        if (data['donation_date'] == null) {
          print('Skipping document ${doc.id}: donation_date is null');
          continue;
        }
        
        // Format dates for display
        final donationDate = (data['donation_date'] as Timestamp).toDate();
        final formattedDate = DateFormat('MMMM d, yyyy').format(donationDate);
        
        // Get event details if hospitalId exists and points to blood_drive_events
        String eventTitle = 'Blood Donation';
        String organizers = ''; // Changed from 'Hospital/Organization' to empty
        String location = ''; // Changed from 'Hospital/Clinic' to empty
        
        if (data['hospitalId'] != null && data['hospitalId'].toString().isNotEmpty) {
          try {
            final eventDoc = await _firestore.collection('blood_drive_events').doc(data['hospitalId'].toString()).get();
            if (eventDoc.exists) {
              final eventData = eventDoc.data()!;
              eventTitle = eventData['title'] ?? 'Blood Donation Event';
              organizers = eventData['organizerName'] ?? '';
              location = eventData['location'] ?? '';
            }
            // Removed else case - if not found, keep empty strings
          } catch (e) {
            print('Error fetching event details: $e');
          }
        }

        final donation = {
          'id': doc.id,
          'title': eventTitle,
          'date': formattedDate,
          'location': location,
          'organizers': organizers,
          'serialNumber': data['serial_number'] ?? 'N/A',
          'amountDonated': '${data['amount_ml']}ml',
          'amountMl': data['amount_ml'] ?? 0,
          'bloodType': data['blood_type'] ?? 'N/A',
          'donationDate': donationDate,
          'donorName': data['donor_name'] ?? 'N/A',
          'status': data['status'] ?? 'unknown',
          'used': data['used'] ?? false,
          'donorId': data['donor_id'] ?? 'N/A',
        };

        print('Adding donation: $donation');
        donations.add(donation);
        totalDonations++;
        totalBloodGiven += (data['amount_ml'] ?? 0) / 1000.0;
        
        // Count used donations for lives saved
        if (data['status'] == 'used' || data['used'] == true) {
          usedDonations++;
        }
      }

      // Calculate lives saved based on used donations only
      final int livesSaved = usedDonations;

      print('Final stats: donations=$totalDonations, blood=${totalBloodGiven}L, used donations=$usedDonations, lives=$livesSaved');

      setState(() {
        _donationHistory = donations;
        _totalDonations = totalDonations;
        _totalBloodGiven = totalBloodGiven;
        _livesSaved = livesSaved;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _errorMessage = 'Error loading data: $e';
        _isLoading = false;
        _fullName = "Error loading data";
      });
    }
  }

  // Add method to get user initials from full name
  String _getUserInitials() {
    if (_fullName.isEmpty) return 'U';
    
    List<String> nameParts = _fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    // Take first letter of first name and first letter of last name
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Navigation helper
  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  // Refresh function
  Future<void> _refreshData() async {
    await _loadUserDataAndDonations();
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
          ? _buildLoadingView()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'My Donation History',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    // Error message if any
                    if (_errorMessage.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    // Debug info (visible only in development)
                    if (_donationHistory.isEmpty && _currentUserId.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Debug Info:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'User ID: $_currentUserId',
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total donations: $_totalDonations (used: $_livesSaved)',
                              style: TextStyle(
                                color: Colors.amber[800],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Donation stats cards
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200!),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            '$_totalDonations',
                            'Donations',
                            Colors.red,
                          ),
                          _buildStatColumn(
                            '${_totalBloodGiven.toStringAsFixed(1)}L',
                            'Blood Given',
                            Colors.blue,
                          ),
                          _buildStatColumn(
                            '$_livesSaved',
                            'Lives Saved',
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Timeline title
                    const Text(
                      'My Timeline',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Timeline entries
                    Expanded(
                      child: _donationHistory.isEmpty
                          ? _buildNoHistoryView()
                          : _buildDonationHistoryList(_donationHistory),
                    ),
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

  // Loading view
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Loading donation history...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build stat columns
  Widget _buildStatColumn(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // No history placeholder view
  Widget _buildNoHistoryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Donation History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You haven\'t made any blood donations yet',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_currentUserId.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'User ID: $_currentUserId',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
            ),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  // Donation history list
  Widget _buildDonationHistoryList(List<Map<String, dynamic>> history) {
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final donation = history[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        donation['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(donation['status']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        donation['status'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Only show date row
                _buildDonationInfoRow(Icons.calendar_today, donation['date']),
                
                // Only show location if it's not empty
                if (donation['location'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDonationInfoRow(Icons.location_on, donation['location']),
                ],
                
                // Only show organizers if it's not empty
                if (donation['organizers'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _buildDonationInfoRow(Icons.local_hospital, donation['organizers']),
                ],
                
                const SizedBox(height: 12),
                Divider(color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Serial Number: ${donation['serialNumber']}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Amount Donated: ${donation['amountDonated']}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Blood Type: ${donation['bloodType']}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status: ${donation['status']}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'used':
        return Colors.green;
      case 'stored':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDonationInfoRow(IconData icon, String text) {
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