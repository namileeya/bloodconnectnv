import 'package:flutter/material.dart';
import 'signup_page_three.dart'; // You'll need to create this for the final step

class SignupPageTwo extends StatefulWidget {
  
  final String email;
final String username;
final String password;


  const SignupPageTwo({
    required this.email,
    required this.username,
    required this.password,
    super.key,
  });

  @override
  _SignupPageTwoState createState() => _SignupPageTwoState();
}

class _SignupPageTwoState extends State<SignupPageTwo> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final int _totalSteps = 3;
  final int _currentStep = 2;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _postcodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedState;

  // List of capitals for dropdown (States of Malaysia)
  final List<String> _states = [
    'Johor Bahru', 'Kuala Lumpur', 'Kota Kinabalu', 'Kuching', 'Shah Alam', 
    'George Town', 'Melaka', 'Ipoh', 'Kota Bharu', 'Alor Setar', 'Putrajaya',
    'Seremban', 'Labuan', 'Kuala Terengganu', 'Kuantan', 'Batu Pahat', 'Muar',
    'Sandakan', 'Tawau', 'Sibu'
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _postcodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      // Save the data or pass it to the next page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignupPageThree(
      email: widget.email,
      username: widget.username,
      password: widget.password,
      phone: _phoneController.text,
      address: _addressController.text,
      state: _selectedState!,
      postcode: _postcodeController.text,
          ),
        ),
      );
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
                    child: Text(
                      'Bloodconnect',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDE0D0D),
                      ),
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
                          // Add smaller bottom padding
                          padding: const EdgeInsets.only(bottom: 50.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Contact Info',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Signup for a new account',
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

                              // Address
                              const Text('Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _addressController,
                                decoration: _inputDecoration('Address'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Capital (Dropdown)
                              const Text('States', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                decoration: _inputDecoration('States'),
                                value: _selectedState,
                                icon: const Icon(Icons.arrow_drop_down),
                                isExpanded: true,
                                hint: const Text('Select State'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a state';
                                  }
                                  return null;
                                },
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedState = newValue;
                                  });
                                },
                                items: _states.map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),

                              // Postcode
                              const Text('Postcode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _postcodeController,
                                decoration: _inputDecoration('Postcode'),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your postcode';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone Number
                              const Text('Phone Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _inputDecoration('Phone Number'),
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  // Simple phone validation - you might want to enhance this
                                  if (!RegExp(r'^\d{10,15}$').hasMatch(value)) {
                                    return 'Please enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Next Button
                              Container(
                                margin: const EdgeInsets.only(bottom: 20.0, top: 10.0),
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _handleNext,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDE0D0D),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    'Next',
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
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      errorStyle: TextStyle(
        color: Colors.red,
        fontSize: 12,
      ),
      isDense: true, // Makes the field more compact
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
}
