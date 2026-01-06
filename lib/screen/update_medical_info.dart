import 'package:flutter/material.dart';
import 'donation_history_page.dart';
import 'donation_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import '../widget/bottom_navigation_bar.dart'; // Add this import
import '../widget/headertwo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UpdateMedicalInfo extends StatefulWidget {
  final String bloodType;
  final String rhesus;
  final String height;
  final String weight;
  final String medicalConditions;
  final String allergies;

  const UpdateMedicalInfo({
    super.key,
    required this.bloodType,
    required this.rhesus,
    required this.height,
    required this.weight,
    required this.medicalConditions,
    required this.allergies,
  });

  @override
  _UpdateMedicalInfoState createState() => _UpdateMedicalInfoState();
}

class _UpdateMedicalInfoState extends State<UpdateMedicalInfo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();

    // Initialize controllers with the passed values or empty strings
    _heightController = TextEditingController(text: widget.height.isNotEmpty ? widget.height : '');
    _weightController = TextEditingController(text: widget.weight.isNotEmpty ? widget.weight : '');
    _medicalConditionsController = TextEditingController(
      text: widget.medicalConditions.isNotEmpty && widget.medicalConditions != 'None' 
        ? widget.medicalConditions 
        : ''
    );
    _allergiesController = TextEditingController(
      text: widget.allergies.isNotEmpty && widget.allergies != 'None' 
        ? widget.allergies 
        : ''
    );

    // Only set if valid values are provided
    if (widget.bloodType.isNotEmpty && _bloodTypes.contains(widget.bloodType)) {
      _selectedBloodType = widget.bloodType;
    }
    if (widget.rhesus.isNotEmpty && _rhesusList.contains(widget.rhesus)) {
      _selectedRhesus = widget.rhesus;
    }

    getUserData();
  }

  // Get user data from Firebase
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

      DocumentSnapshot donorDoc = await _firestore
          .collection('donor_profiles')
          .doc(currentUser.uid)
          .get();

      if (donorDoc.exists) {
        Map<String, dynamic> data = donorDoc.data() as Map<String, dynamic>;
        
        setState(() {
          userData = data;
          userData!['id'] = currentUser.uid; // Add the user ID
          
          // Update dropdown values with data from database
          if (data['blood_group'] != null && _bloodTypes.contains(data['blood_group'])) {
            _selectedBloodType = data['blood_group'];
          }
          if (data['rhesus'] != null && _rhesusList.contains(data['rhesus'])) {
            _selectedRhesus = data['rhesus'];
          }
          
          // Update text controllers with data from database
          if (data['height'] != null && data['height'].toString().isNotEmpty) {
            _heightController.text = data['height'].toString();
          }
          if (data['weight'] != null && data['weight'].toString().isNotEmpty) {
            _weightController.text = data['weight'].toString();
          }
          if (data['medical_conditions'] != null && data['medical_conditions'] != 'None') {
            _medicalConditionsController.text = data['medical_conditions'];
          }
          if (data['allergies'] != null && data['allergies'] != 'None') {
            _allergiesController.text = data['allergies'];
          }
          
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User data not found')),
          );
        }
      }
    } catch (e) {
      print('Error getting user data: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  String get userId => userData?['id'] ?? '';
  String get fullName1 => userData?['full_name'] ?? '';
  String get bloodType1 => userData?['blood_group'] ?? '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Values for dropdown fields
  String _selectedBloodType = "O-";
  String _selectedRhesus = "Rh-positive";

  // Controllers for the text fields
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;

  // Lists of values for dropdown fields
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _rhesusList = ['Rh-positive', 'Rh-negative'];

  // State for the success dialog
  bool _showSuccessDialog = false;

  // Error message to display
  String? _errorMessage;

  // Selected nav index - Profile is at index 4
  final int _selectedNavIndex = 4;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _medicalConditionsController.dispose();
    _allergiesController.dispose();
    super.dispose();
  }

  // Height validation
  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your height';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    int height = int.parse(value);
    if (height < 100 || height > 250) {
      return 'Please enter a realistic height (100-250 cm)';
    }
    return null;
  }

  // Weight validation
  String? _validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your weight';
    }
    if (int.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    int weight = int.parse(value);
    if (weight < 30 || weight > 200) {
      return 'Please enter a realistic weight (30-200 kg)';
    }
    return null;
  }

  // Handle navigation when bottom nav bar items are tapped
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
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Red header with avatar and name - Using HeaderTwo widget
                      HeaderTwo(
                        fullName: fullName1,
                        bloodType: _selectedBloodType,
                        donorStatus: "Regular Donor",
                        // ------------------------------------- EDIT NANTI -------------------- //
                        donationCount: 1,
                      ),
                      
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
                                    'Medical Information',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Blood Type Dropdown
                                  _buildDropdownField(
                                    label: 'Blood Type',
                                    value: _selectedBloodType,
                                    items: _bloodTypes,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedBloodType = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Rhesus Dropdown
                                  _buildDropdownField(
                                    label: 'Rhesus',
                                    value: _selectedRhesus,
                                    items: _rhesusList,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRhesus = value!;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Height
                                  _buildFormField(
                                    label: 'Height (cm)',
                                    controller: _heightController,
                                    keyboardType: TextInputType.number,
                                    validator: _validateHeight,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Weight
                                  _buildFormField(
                                    label: 'Weight (kg)',
                                    controller: _weightController,
                                    keyboardType: TextInputType.number,
                                    validator: _validateWeight,
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Medical Conditions
                                  _buildFormField(
                                    label: 'Medical Conditions',
                                    controller: _medicalConditionsController,
                                    maxLines: 2,
                                    validator: (value) {
                                      // Allow empty - it will be set to "None" if empty
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  
                                  // Allergies
                                  _buildFormField(
                                    label: 'Allergies',
                                    controller: _allergiesController,
                                    maxLines: 2,
                                    validator: (value) {
                                      // Allow empty - it will be set to "None" if empty
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
                                  
                                  // Cancel and Save buttons (side by side)
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

  // Dropdown field builder with consistent styling
  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool enabled = true,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: enabled ? Colors.black : Colors.grey[700],
              fontSize: 16,
            ),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: Colors.white,
            elevation: 2,
            onChanged: enabled ? onChanged : null,
            items: items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
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
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
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
              height: 280,
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
                    'Medical Info Updated',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Additional success message
                  const Text(
                    'Your medical information has been updated successfully',
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

  // Handle saving information with form validation
  Future<void> _handleSaveInformation() async {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });
    
    // Validate the form first
    if (_formKey.currentState!.validate()) {
      try {
        User? currentUser = _auth.currentUser;
        
        if (currentUser == null) {
          setState(() {
            _errorMessage = 'No user logged in';
          });
          return;
        }
        
        // Prepare the update data
        Map<String, dynamic> updateData = {
          'blood_group': _selectedBloodType,
          'rhesus': _selectedRhesus,
          'height': _heightController.text.trim(),
          'weight': _weightController.text.trim(),
          'medical_conditions': _medicalConditionsController.text.trim().isEmpty 
              ? 'None' 
              : _medicalConditionsController.text.trim(),
          'allergies': _allergiesController.text.trim().isEmpty 
              ? 'None' 
              : _allergiesController.text.trim(),
          'updated_at': FieldValue.serverTimestamp(),
        };
        
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        
        // Update data in Firebase
        await _firestore
            .collection('donor_profiles')
            .doc(currentUser.uid)
            .update(updateData);
        
        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }
        
        // Update local userData
        setState(() {
          if (userData != null) {
            userData!.addAll(updateData);
          }
        });
        
        // Show success popup dialog
        setState(() {
          _showSuccessDialog = true;
        });
        
      } catch (e) {
        print('Error updating medical info: $e');
        
        // Close loading dialog if it's still showing
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        setState(() {
          _errorMessage = 'Failed to update medical information. Please try again.';
        });
      }
    }
  }
}