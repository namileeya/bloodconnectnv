import 'package:flutter/material.dart';

class PasswordResetPage extends StatefulWidget {
  const PasswordResetPage({super.key});

  @override
  _PasswordResetPageState createState() => _PasswordResetPageState();
}

class _PasswordResetPageState extends State<PasswordResetPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _showSuccessDialog = false;
  
  // Validation error messages
  String? _newPasswordError;
  String? _confirmPasswordError;

  // Show success dialog
  void _showPasswordChangedDialog(BuildContext context) {
    setState(() {
      _showSuccessDialog = true;
    });
  }

  // Validate new password
  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // Validate confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // Change password function
  void _changePassword() {
    // Clear previous errors
    setState(() {
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    // Validate fields
    String? newPasswordError = _validateNewPassword(_newPasswordController.text);
    String? confirmPasswordError = _validateConfirmPassword(_confirmPasswordController.text);

    if (newPasswordError != null || confirmPasswordError != null) {
      setState(() {
        _newPasswordError = newPasswordError;
        _confirmPasswordError = confirmPasswordError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate password change delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isLoading = false;
      });
      
      // Show success dialog
      _showPasswordChangedDialog(context);
      
      // Here you can add Firebase password update logic later
      // FirebaseAuth.instance.currentUser?.updatePassword(_newPasswordController.text);
    });
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main page content
        Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                Icons.arrow_back_ios,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 1),
                          const Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Center content
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // New password section
                            const Text(
                              'Type your new password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // New password input field
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _newPasswordError != null 
                                      ? Colors.red 
                                      : const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _newPasswordController,
                                obscureText: !_isNewPasswordVisible,
                                onChanged: (value) {
                                  // Clear error when user starts typing
                                  if (_newPasswordError != null) {
                                    setState(() {
                                      _newPasswordError = null;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '************',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isNewPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isNewPasswordVisible = !_isNewPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  filled: false,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            
                            // Error message for new password
                            if (_newPasswordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _newPasswordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            
                            const SizedBox(height: 8),
                            
                            // Password requirements hint
                            Text(
                              'Min 8 chars with uppercase, number & special char',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Confirm password section
                            const Text(
                              'Confirm password',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF9E9E9E),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm password input field
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _confirmPasswordError != null 
                                      ? Colors.red 
                                      : const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_isConfirmPasswordVisible,
                                onChanged: (value) {
                                  // Clear error when user starts typing
                                  if (_confirmPasswordError != null) {
                                    setState(() {
                                      _confirmPasswordError = null;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: '************',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFFBDBDBD),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isConfirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  filled: false,
                                ),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            
                            // Error message for confirm password
                            if (_confirmPasswordError != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _confirmPasswordError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 48),

                            // Change Password Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDE0D0D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: _isLoading ? null : _changePassword,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Change password',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Add some bottom spacing
                    const SizedBox(height: 140),
                  ],
                ),
              ),
              
              // Waves image positioned at the bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 125,
                child: Image.asset(
                  'assets/waves.png',
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),

        // Success dialog overlay
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }

  // Success Popup matching the booking confirmation style
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
                    'Password Changed Successfully',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  
                  // Additional message
                  Text(
                    'You can now login with your new password.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 3 seconds and navigate back to login
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 3)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Navigate back to login page (pop twice: once for dialog, once for this page)
                          setState(() {
                            _showSuccessDialog = false;
                          });
                          Navigator.of(context).pop(); 
                          Navigator.of(context).pop(); 
                          Navigator.of(context).pop(); 
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