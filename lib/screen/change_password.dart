import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../user_session.dart';
import 'profile_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/headertwo.dart';

class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Controllers for the text fields
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Variables to control password visibility
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  
  // State for the success dialog
  bool _showSuccessDialog = false;
  
  // Error message to display
  String? _errorMessage;

  // Selected nav index - Profile is at index 4
  final int _selectedNavIndex = 4;

  // User data state variables
  String fullName = "Loading...";
  String bloodType = "-";
  int _donationCount = 0;
  bool isLoading = true;
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch donor profile for name and blood type
        final donorDoc = await FirebaseFirestore.instance
            .collection('donor_profiles')
            .doc(user.uid)
            .get();

        // Fetch donations for count
        final donationsQuery = await FirebaseFirestore.instance
            .collection('donations')
            .where('donor_id', isEqualTo: user.uid)
            .get();

        if (mounted) {
          setState(() {
            if (donorDoc.exists) {
              final data = donorDoc.data();
              fullName = data?['full_name'] ?? 'User';
              bloodType = data?['blood_group'] ?? '-';
            }
            _donationCount = donationsQuery.docs.length;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Simplified navigation handler that updates the selected index
  void _updateNavIndex(int index) {
    setState(() {
      // The navigation will be handled by the NavigationHelper
    });
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password validation logic (same as in signup_page.dart)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
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

  // Confirm password validation
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
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
                // Red header with avatar and name - Using HeaderTwo widget
                HeaderTwo(
                  fullName: fullName,
                  bloodType: bloodType,
                  donorStatus: _donationCount > 0 ? "Regular Donor" : "New Donor",
                  donationCount: _donationCount,
                ),
                
                // Content card - with WHITE background, not pink
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    color: Colors.white, // Explicitly set white background
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
                              'Change Password',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Current Password
                            const Text(
                              'Current Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _currentPasswordController,
                              isVisible: _currentPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _currentPasswordVisible = !_currentPasswordVisible;
                                });
                              },
                              hintText: 'Current Password',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            
                            // New Password
                            const Text(
                              'New Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _newPasswordController,
                              isVisible: _newPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _newPasswordVisible = !_newPasswordVisible;
                                });
                              },
                              hintText: 'New Password',
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 24),
                            
                            // Confirm New Password
                            const Text(
                              'Confirm New Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPasswordField(
                              controller: _confirmPasswordController,
                              isVisible: _confirmPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  _confirmPasswordVisible = !_confirmPasswordVisible;
                                });
                              },
                              hintText: 'Confirm New Password',
                              validator: _validateConfirmPassword,
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
                                    onPressed: _isUpdatingPassword ? null : () {
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
                                    onPressed: _isUpdatingPassword ? null : () {
                                      // Handle password change logic with validation
                                      _handlePasswordChange();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isUpdatingPassword 
                                          ? Colors.grey[400] 
                                          : const Color(0xFFDE0D0D),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: _isUpdatingPassword
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Text(
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
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        // Success dialog overlay - Similar to the booking confirmation page
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }

  // Success Popup with green checkmark similar to booking confirmation page
  Widget _buildSuccessPopup() {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5), // Semi-transparent barrier for blur effect
        ),
        
        // Popup content - White card with green outlined checkmark
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 250,
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
                    'Password Changed',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  const Text(
                    'Your password has been updated successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  
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

  // Custom password field with visibility toggle and validation
  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String hintText,
    required String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !isVisible,
      validator: validator,
      enabled: !_isUpdatingPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey[400],
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
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
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey[500],
          ),
          onPressed: _isUpdatingPassword ? null : onToggleVisibility,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(
          fontSize: 12,
          color: Colors.red,
        ),
      ),
    );
  }

  // Handle password change logic with form validation
  Future<void> _handlePasswordChange() async {
    // Clear any previous error message
    setState(() {
      _errorMessage = null;
    });
    
    // Validate the form first
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Get the values from the controllers
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    
    // Check if new password is same as current password
    if (currentPassword == newPassword) {
      setState(() {
        _errorMessage = 'New password must be different from current password';
      });
      return;
    }
    
    try {
      setState(() {
        _isUpdatingPassword = true;
      });
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'User not logged in. Please log in again.';
          _isUpdatingPassword = false;
        });
        return;
      }
      
      if (user.email == null || user.email!.isEmpty) {
        setState(() {
          _errorMessage = 'User email not found. Please log in again.';
          _isUpdatingPassword = false;
        });
        return;
      }
      
      // IMPORTANT: Firebase requires re-authentication before password change
      // This verifies the current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      
      // Re-authenticate user with current password
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Show success popup dialog
      setState(() {
        _showSuccessDialog = true;
        _isUpdatingPassword = false;
      });
      
      // Clear the password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect.';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak. Please choose a stronger password.';
          break;
        case 'requires-recent-login':
          errorMessage = 'This operation requires recent authentication. Please log out and log in again.';
          break;
        case 'invalid-credential':
          errorMessage = 'The current password is invalid.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = 'An error occurred: ${e.message}';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isUpdatingPassword = false;
      });
      
    } catch (e) {
      print("Error changing password: $e");
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isUpdatingPassword = false;
      });
    }
  }
}