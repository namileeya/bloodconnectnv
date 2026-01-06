import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import 'package:bloodconnect/user_session.dart';

class FindDonorsPage extends StatefulWidget {
  const FindDonorsPage({super.key});

  @override
  State<FindDonorsPage> createState() => _FindDonorsPageState();
}

class _FindDonorsPageState extends State<FindDonorsPage> {
  String? _selectedLocation;
  final _nameController = TextEditingController();
  final _reasonsController = TextEditingController();
  String? _selectedBloodGroup;
  bool _termsAccepted = false;
  
  // State for the success dialog
  bool _showSuccessDialog = false;
  // State for error message
  String? _errorMessage;
  // State for submission loading
  bool _isSubmitting = false;

  // User data from session
  String? _userId;
  String _fullName = 'Guest User';
  bool _isLoading = true;

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> _locations = [
    'Kuala Lumpur',
    'Selangor',
    'Johor',
    'Penang',
    'Sabah',
    'Sarawak',
    'Perak',
    'Negeri Sembilan',
    'Pahang',
    'Terengganu',
    'Kelantan',
    'Malacca',
    'Kedah',
    'Perlis',
  ];

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from session
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await UserSession.getUser();
      
      if (userData == null) {
        throw Exception('No user data found');
      }
      
      setState(() {
        _userId = userData['user_id'];
        _fullName = userData['full_name'] ?? 'Guest User';
        _isLoading = false;
      });
      
      print('User data loaded: userId=$_userId, name=$_fullName');
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Failed to load user data. Please try logging in again.');
      }
    }
  }

  // Show error snackbar
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Get user initials from full name
  String _getUserInitials() {
    List<String> nameParts = _fullName.trim().split(' ');
    
    if (nameParts.isEmpty || _fullName == 'Guest User') return 'GU';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Submit blood request to database
  Future<void> _submitRequest() async {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });

    // Validate required fields
    if (_selectedLocation == null || 
        _nameController.text.trim().isEmpty || 
        _selectedBloodGroup == null || 
        !_termsAccepted) {
      setState(() {
        _errorMessage = 'Please fill all required fields and accept the terms';
      });
      return;
    }

    // Check if user is logged in
    if (_userId == null) {
      _showErrorSnackBar('User not logged in. Please log in again.');
      return;
    }

    // Set submitting state
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Submit blood request directly to Firestore
      DocumentReference docRef = await _firestore.collection('blood_requests').add({
        'user_id': _userId!,
        'requester_name': _fullName,
        'patient_name': _nameController.text.trim(),
        'patient_location': _selectedLocation!,
        'blood_group': _selectedBloodGroup!,
        'reasons': _reasonsController.text.trim().isNotEmpty 
            ? _reasonsController.text.trim() 
            : '',
        'status': 'pending', // Default status
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
      });

      print('Blood request submitted successfully with ID: ${docRef.id}');
      
      // Show success dialog
      setState(() {
        _showSuccessDialog = true;
      });
      
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      print('Error submitting blood request: $e');
      _showErrorSnackBar('An error occurred. Please try again.');
    }
  }

  // Update nav index (required by NavigationHelper)
  void _updateNavIndex(int index) {
    // Empty implementation as required by NavigationHelper
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while fetching user data
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFDE0D0D),
          ),
        ),
      );
    }

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
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'Find Donors',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Blood Request Form
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Blood Request Form',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Patient's Location
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDE0D0D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Patient\'s Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            borderRadius: BorderRadius.circular(12),
                            dropdownColor: Colors.white,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              hintText: 'Location',
                              border: InputBorder.none,
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            isExpanded: true,
                            items: _locations.map((location) {
                              return DropdownMenuItem<String>(
                                value: location,
                                child: Text(location),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedLocation = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Patient's Name
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDE0D0D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Patient\'s Name',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'Name',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Reasons (Optional)
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDE0D0D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_note,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reasons',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(Optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _reasonsController,
                            decoration: const InputDecoration(
                              hintText: 'Write a description',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: InputBorder.none,
                            ),
                            maxLines: 5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Blood Group
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDE0D0D),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.water_drop,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Blood Group',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Blood Group Selection
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _bloodGroups.map((group) {
                            final isSelected = _selectedBloodGroup == group;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBloodGroup = group;
                                });
                              },
                              child: Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    group,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? const Color(0xFFDE0D0D) : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        
                        // Information Text
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Once you submit this request, BloodConnect will inform suitable donors to assist with your blood needs.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        
                        // Disclaimer Text
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            'Please note: Each request will be validated by the respective hospital. Kindly ensure the request is for an actual patient.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Terms Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _termsAccepted,
                                onChanged: (value) {
                                  setState(() {
                                    _termsAccepted = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFFDE0D0D),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'I hereby confirm that the information provided above is true, accurate, and complete.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[900],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Buttons with error message
                        Column(
                          children: [
                            // Error message
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.shade300),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _isSubmitting ? null : () {
                                      Navigator.of(context).pop();
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      side: BorderSide(color: Colors.grey.shade300),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
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
                                    onPressed: _isSubmitting ? null : _submitRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDE0D0D),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      disabledBackgroundColor: Colors.grey,
                                    ),
                                    child: _isSubmitting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Text(
                                            'Submit',
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
                      ],
                    ),
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
        // Success popup overlay
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
                    'Request Submitted',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Additional message
                  Text(
                    'You will be notified when suitable donors are found for your request.',
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
                          setState(() {
                            _selectedLocation = null;
                            _nameController.clear();
                            _reasonsController.clear();
                            _selectedBloodGroup = null;
                            _termsAccepted = false;
                            _showSuccessDialog = false;
                          });
                          
                          // Navigate back to HomePage
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const HomePage()),
                            (Route<dynamic> route) => false,
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
}