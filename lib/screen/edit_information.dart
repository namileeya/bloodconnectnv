import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'donation_history_page.dart';
import 'donation_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../widget/bottom_navigation_bar.dart'; // Add this import

class EditInformation extends StatefulWidget {


  const EditInformation({
    super.key,
    this.idNumber = '',
    this.fullName = '',
    this.bloodBankId = '',
    this.gender = '',
    this.email = '',
    this.phoneNumber = '',
    this.address = '',
  });

  final String? idNumber;
  final String? fullName;
  final String? bloodBankId;
  final String? gender;
  final String? email;
  final String? phoneNumber;
  final String? address;

  @override
  _EditInformationState createState() => _EditInformationState();
}

class _EditInformationState extends State<EditInformation> {
  //final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
   final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User data
  Map<String, dynamic>? userData;
  Map<String, dynamic>? donorProfileData;
  bool isLoading = true;

  // Form key and controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _icNumberController;
  late final TextEditingController _idNumberController;
  late final TextEditingController _genderController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  // State variables
  bool _showSuccessDialog = false;
  String? _errorMessage;
  final int _selectedNavIndex = 4;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with passed data
    _nameController = TextEditingController(text: widget.fullName ?? '');
    _icNumberController = TextEditingController(text: widget.idNumber ?? '');
    _idNumberController = TextEditingController(text: widget.bloodBankId ?? '');
    _genderController = TextEditingController(text: widget.gender ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _phoneController = TextEditingController(text: widget.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.address ?? '');
    
    getUserDataFromFirebase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _icNumberController.dispose();
    _idNumberController.dispose();
    _genderController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Get current user ID from Firebase Auth
  String? get userId => _auth.currentUser?.uid;

  // Getters for header display
  String get fullName1 => donorProfileData?['full_name'] ?? 'Not provided';
  String get bloodType1 => donorProfileData?['blood_group'] ?? 'Not provided';

  // Fetch user data from Firebase
  Future<void> getUserDataFromFirebase() async {
    try {
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch from users collection
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      // Fetch from donor_profiles collection
      DocumentSnapshot donorDoc = await _firestore
          .collection('donor_profiles')
          .doc(userId)
          .get();

      if (userDoc.exists && donorDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
          donorProfileData = donorDoc.data() as Map<String, dynamic>?;
          
          // Update controllers if they are empty (or always to ensure freshness)
          if (donorProfileData != null) {
            if (_nameController.text.isEmpty) _nameController.text = donorProfileData!['full_name'] ?? '';
            if (_idNumberController.text.isEmpty) _idNumberController.text = donorProfileData!['blood_bank_id'] ?? '';
          }
          if (userData != null) {
            if (_icNumberController.text.isEmpty) _icNumberController.text = userData!['ic_number'] ?? '';
            if (_genderController.text.isEmpty) _genderController.text = userData!['gender'] ?? '';
            if (_emailController.text.isEmpty) _emailController.text = userData!['email'] ?? '';
            if (_phoneController.text.isEmpty) _phoneController.text = userData!['phone_number'] ?? '';
            if (_addressController.text.isEmpty) _addressController.text = userData!['address'] ?? '';
          }
          
          isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  // Email validation
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email address';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Phone validation
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    final phoneRegex = RegExp(r'^(01)[0-46-9]-*[0-9]{7,8}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  // Handle save with Firebase
 // Handle save with Firebase - MINIMAL FIX
Future<void> _handleSaveInformation() async {
  if (_formKey.currentState!.validate()) {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFDE0D0D),
            ),
          );
        },
      );

      // Update users collection
      await _firestore.collection('users').doc(userId).update({
        'email': _emailController.text,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
      });

      // Update donor_profiles collection  
      await _firestore.collection('donor_profiles').doc(userId).update({
        'full_name': _nameController.text,
        // Make sure this field name matches what's in your Firestore
        'blood_bank_id': _idNumberController.text,
      });

      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      setState(() {
        _showSuccessDialog = true;
      });

      // Navigate after showing popup
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ProfilePage()),
            (route) => false,
          );
        }
      });

    } catch (e) {
      // Hide loading indicator
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error updating profile: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}


// Navigation handler
  void _onNavItemTapped(int index) {
    if (index == _selectedNavIndex) {
      return;
    }

    switch (index) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DonationHistoryPage()),
          (route) => false,
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DonationPage()),
        );
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
        break;
    }
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main page content
        Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            toolbarHeight: 0,
            backgroundColor: const Color(0xFFDE0D0D),
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Red header with avatar and name
                _buildProfileHeader(),
                
                // Content card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Full Name
                            _buildFormField(
                              label: 'Full Name',
                              controller: _nameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // IC Number or Passport
                            _buildFormField(
                              label: 'IC Number or Passport',
                              controller: _icNumberController,
                              enabled: false, // Make this field read-only
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your IC number or passport';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // ID Number
                            _buildFormField(
                              label: 'ID Number',
                              controller: _idNumberController,
                              enabled: false, // Make this field read-only
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your ID number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Gender
                            _buildFormField(
                              label: 'Gender',
                              controller: _genderController,
                              enabled: false, // Make this field read-only
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your gender';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Email
                            _buildFormField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 20),
                            
                            // Phone Number
                            _buildFormField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              validator: _validatePhone,
                            ),
                            const SizedBox(height: 20),
                            
                            // Address
                            _buildFormField(
                              label: 'Address',
                              controller: _addressController,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            
                            // Error message display
                            if (_errorMessage != null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            
                            // Cancel and Save buttons
                            Row(
                              children: [
                                // Cancel Button
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      // Go back to the previous screen
                                      Navigator.pop(context);
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide(color: Colors.grey[400]!), 
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Save Button
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      _handleSaveInformation();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDE0D0D),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
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
                  ),
                ),
              ],
            ),
          ),
          // --------------------------- //
          bottomNavigationBar: CustomBottomNavigationBar(
  currentIndex: _selectedNavIndex,
  onTap: _onNavItemTapped,
),

        ),
        // Success dialog overlay
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }

  // Form field builder with consistent styling
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
            ),
          ),
          style: TextStyle(
            color: enabled ? Colors.black : Colors.grey[700],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Success Popup with green checkmark
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
              height: 280, // Increased height to accommodate additional message
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
                    'Information Updated',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Additional success message
                  const Text(
                    'Your profile has been updated successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 2 seconds
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 2)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // Navigate back to profile after delay
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
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

  // Red header with avatar and name - similar to the profile page
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      color: const Color(0xFFDE0D0D),
      child: Row(
        children: [
          // Circle avatar with initials
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "AM",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDE0D0D),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User name and blood type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AMMAL ALIYA BINTI MISRON",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "O- Blood Type",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Status pills
                Row(
                  children: [
                    _buildStatusPill("Regular Donor"),
                    const SizedBox(width: 8),
                    _buildStatusPill("1 Donation"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Status pill widgets (rounded rectangular badges)
  Widget _buildStatusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }

  // Handle saving information with form validatio
}