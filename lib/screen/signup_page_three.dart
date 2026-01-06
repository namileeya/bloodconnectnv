import 'package:bloodconnect/screen/login_page.dart';
import 'package:flutter/material.dart';
//import 'home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPageThree extends StatefulWidget {
  final String email;
final String username;
final String password;
 final String phone;
  final String address;
  final String state;
  final String postcode;

const SignupPageThree({
    required this.email,
    required this.username,
    required this.password,
    required this.phone,
    required this.address,
    required this.state,
    required this.postcode,
    super.key,
  });



  @override
  _SignupPageThreeState createState() => _SignupPageThreeState();
}

class _SignupPageThreeState extends State<SignupPageThree> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final int _totalSteps = 3;
  final int _currentStep = 3;

  String? _selectedBloodType;
  final List<String> _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  // Selected identification type
  String? _selectedIdType;

  // Form controllers
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _bloodBankIdController = TextEditingController();
  
  // For date of birth, height, weight
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();

  // Flag to show success popup
  bool _showSuccessPopup = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _idNumberController.dispose();
    _bloodBankIdController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
  if (_formKey.currentState!.validate()) {
    print('=== SIGNUP PROCESS STARTED ===');
    
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

    try {
      print('Step 1: Creating Firebase Auth user...');
      print('Email: ${widget.email}');
      
      // Create Firebase Auth user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      String userId = userCredential.user!.uid;
      print('✓ Auth user created successfully. UID: $userId');

      // Generate unique QR code data
      String qrCodeData = 'BLOODCONNECT:USER:$userId';
      print('Step 1.5: Generated QR code data: $qrCodeData');

      // Prepare users data - NOW INCLUDING QR CODE DATA
      Map<String, dynamic> usersData = {
        'email': widget.email,
        'username': widget.username,
        'phone_number': widget.phone,
        'address': widget.address,
        'state': widget.state,
        'postcode': widget.postcode,
        'qr_code_data': qrCodeData,  // ← ADD THIS LINE
        'role': 'blood_donor',
        'created_at': FieldValue.serverTimestamp(),
      };
      print('Step 2: Saving to users collection...');
      print('Users data: $usersData');

      // Store in 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set(usersData);
      print('✓ Users collection saved successfully');

      // Prepare donor profiles data - ALSO INCLUDING QR CODE DATA
      Map<String, dynamic> donorProfileData = {
        'user_id': userId,
        'full_name': _fullNameController.text.trim(),
        'gender': _selectedGender!,
        'id_type': _selectedIdType!,
        'id_number': _idNumberController.text.trim(),
        'blood_bank_id': _bloodBankIdController.text.trim().isEmpty 
            ? null 
            : _bloodBankIdController.text.trim(),
        'blood_group': _selectedBloodType!,
        'birth_date': _dobController.text,
        'weight': _weightController.text.trim(),
        'height': _heightController.text.trim(),
        'qr_code_data': qrCodeData,  // ← ADD THIS LINE
        'created_at': FieldValue.serverTimestamp(),
      };
      print('Step 3: Saving to donor_profiles collection...');
      print('Donor profile data: $donorProfileData');

      // Store in 'donor_profiles' collection
      await FirebaseFirestore.instance
          .collection('donor_profiles')
          .doc(userId)
          .set(donorProfileData);
      print('✓ Donor profiles collection saved successfully');

      print('=== SIGNUP COMPLETED SUCCESSFULLY ===');

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // Show success popup
      if (mounted) {
        setState(() {
          _showSuccessPopup = true;
        });
      }

      // Navigate to login after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      });

    } on FirebaseAuthException catch (authError) {
      print('❌ FIREBASE AUTH ERROR');
      print('Error Code: ${authError.code}');
      print('Error Message: ${authError.message}');
      print('Full Error: $authError');
      
      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Signup failed';
      
      switch (authError.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your connection';
          break;
        default:
          errorMessage = 'Auth error: ${authError.code}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

    } on FirebaseException catch (firestoreError) {
      print('❌ FIRESTORE ERROR');
      print('Error Code: ${firestoreError.code}');
      print('Error Message: ${firestoreError.message}');
      print('Error Plugin: ${firestoreError.plugin}');
      print('Full Error: $firestoreError');
      
      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      String errorMessage = 'Database error';
      
      switch (firestoreError.code) {
        case 'permission-denied':
          errorMessage = 'Permission denied. Check Firestore rules';
          break;
        case 'unavailable':
          errorMessage = 'Firestore service unavailable';
          break;
        case 'not-found':
          errorMessage = 'Collection not found';
          break;
        default:
          errorMessage = 'Database error: ${firestoreError.code}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

    } catch (error, stackTrace) {
      print('❌ UNEXPECTED ERROR');
      print('Error: $error');
      print('Stack trace: $stackTrace');
      
      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: ${error.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  } else {
    print('❌ Form validation failed');
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Bottom wave image as static background
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/waves.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0, bottom: 10.0),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop,
                          color: const Color(0xFFDE0D0D),
                          size: 30,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BloodConnect',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDE0D0D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 50.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'User Info',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Complete your donor profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Step $_currentStep/$_totalSteps',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Full Name
                              const Text('Full Name', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _fullNameController,
                                decoration: _inputDecoration('Full Name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Gender
                              const Text('Gender', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration('Gender'),
                                value: _selectedGender,
                                icon: const Icon(Icons.arrow_drop_down),
                                isExpanded: true,
                                hint: const Text('Select Gender'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your gender';
                                  }
                                  return null;
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                },
                                items: _genders.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Identification Type
                              const Text('Identification Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedIdType = 'IC Number';
                                          // Clear the field when changing type
                                          _idNumberController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: _selectedIdType == 'IC Number' ? Colors.white : Colors.black, 
                                        backgroundColor: _selectedIdType == 'IC Number' ? const Color(0xFFDE0D0D) : Colors.grey.shade200,
                                      ),
                                      child: const Text('IC Number'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _selectedIdType = 'Passport Number';
                                          // Clear the field when changing type
                                          _idNumberController.clear();
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: _selectedIdType == 'Passport Number' ? Colors.white : Colors.black, 
                                        backgroundColor: _selectedIdType == 'Passport Number' ? const Color(0xFFDE0D0D) : Colors.grey.shade200,
                                      ),
                                      child: const Text('Passport Number'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Identification Number - with null safety
                              Text(
                                _selectedIdType != null ? _selectedIdType! : 'Identification Number', 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _idNumberController,
                                decoration: _inputDecoration(_selectedIdType != null 
                                  ? 'Enter $_selectedIdType' 
                                  : 'Enter Identification Number'),
                                keyboardType: _selectedIdType == 'IC Number' 
                                  ? TextInputType.number 
                                  : TextInputType.text,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your ${_selectedIdType ?? 'identification number'}';
                                  }
                                  
                                  // Add specific validation for IC Number
                                  if (_selectedIdType == 'IC Number') {
                                    // Malaysian IC format validation (simplified)
                                    if (!RegExp(r'^\d{6}-\d{2}-\d{4}$').hasMatch(value) && 
                                        !RegExp(r'^\d{12}$').hasMatch(value)) {
                                      return 'Please enter a valid IC number (e.g., 020213-14-1084)';
                                    }
                                  }
                                  
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Blood Bank ID Number
                              const Text('Blood Bank ID Number (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _bloodBankIdController,
                                decoration: _inputDecoration('Blood Bank ID Number'),
                              ),
                              const SizedBox(height: 16),

                              // Blood Group
                              const Text('Blood Group', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration('Blood Group'),
                                value: _selectedBloodType,
                                icon: const Icon(Icons.arrow_drop_down),
                                isExpanded: true,
                                hint: const Text('Select Blood Group'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your blood group';
                                  }
                                  return null;
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedBloodType = newValue;
                                  });
                                },
                                items: _bloodTypes.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Date of Birth
                              const Text('Date of Birth', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _dobController,
                                decoration: _inputDecoration('Date of Birth').copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () => _selectDate(context),
                                  ),
                                ),
                                readOnly: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your date of birth';
                                  }
                                  return null;
                                },
                                onTap: () => _selectDate(context),
                              ),
                              const SizedBox(height: 16),

                              // Weight
                              const Text('Weight (kg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _weightController,
                                decoration: _inputDecoration('Weight in kg'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your weight';
                                  }
                                  // Validate minimum weight for blood donation
                                  try {
                                    double weight = double.parse(value);
                                    if (weight < 45) {
                                      return 'Weight must be at least 45kg to donate blood';
                                    }
                                  } catch (e) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Height
                              const Text('Height (cm)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _heightController,
                                decoration: _inputDecoration('Height in cm'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your height';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Finish Button
                              Container(
                                margin: const EdgeInsets.only(bottom: 20.0, top: 10.0),
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDE0D0D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Success Popup
          if (_showSuccessPopup)
            _buildSuccessPopup(),
        ],
      ),
    );
  }

  // Success popup with animation
  Widget _buildSuccessPopup() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          // ignore: deprecated_member_use
          color: Colors.black.withOpacity(0.5),
        ),
        
        // Popup content - white card with success message
        Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Green circle with white checkmark
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Account Created Successfully',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Welcome to BloodConnect!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      errorStyle: const TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
      isDense: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDE0D0D), width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFDE0D0D),
              onPrimary: Colors.white,
            ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }
}