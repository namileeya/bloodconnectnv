import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _emailSent = false;

  // Show email sent dialog
  void _showEmailSentDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email icon
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDE0D0D),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFDE0D0D),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Success message
                const Text(
                  'Email Sent!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Password reset link sent to\n$email',
                  style: const TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Progress indicator
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDE0D0D)),
                  ),
                ),
                
                // Auto close after 2 seconds and navigate back
                FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back to login page
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Send password reset email
  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      
      // Send password reset email via Firebase
      await _auth.sendPasswordResetEmail(email: email);
      
      // Email sent successfully
      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
      
      // Show success dialog
      _showEmailSentDialog(context, email);
      
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      // Handle different Firebase errors
      String errorMessage = 'Failed to send reset email. Please try again.';
      
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your connection.';
          break;
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: const Color(0xFFDE0D0D),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An unexpected error occurred.'),
            backgroundColor: Color(0xFFDE0D0D),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Resend reset email
  void _resendEmail() {
    if (_emailController.text.isNotEmpty) {
      _sendResetEmail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address first.'),
          backgroundColor: Color(0xFFDE0D0D),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        'Forgot Password',
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
                        // Instructions text
                        const Text(
                          'Enter your email address',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email input field
                        Form(
                          key: _formKey,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 1,
                              ),
                            ),
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isLoading,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email address';
                                }
                                // Basic email validation
                                final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
                                );
                                if (!emailRegex.hasMatch(value.trim())) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                              decoration: const InputDecoration(
                                hintText: 'example@email.com',
                                hintStyle: TextStyle(
                                  color: Color(0xFFBDBDBD),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
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
                        ),
                        const SizedBox(height: 32),

                        // Description text
                        const Text(
                          'We will send you a password reset link to your email address. Check your inbox and follow the instructions.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        
                        // Success message (shown after email is sent)
                        if (_emailSent)
                          Column(
                            children: [
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF4CAF50),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF4CAF50),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Reset email sent to ${_emailController.text}. Check your inbox.',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        
                        const SizedBox(height: 48),

                        // Send Button
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
                            onPressed: _isLoading ? null : _sendResetEmail,
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
                                  : Text(
                                      _emailSent ? 'Resend Email' : 'Send Reset Link',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        
                        // Resend button (alternative)
                        if (_emailSent)
                          Column(
                            children: [
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading ? null : _resendEmail,
                                  child: Text(
                                    'Didn\'t receive the email? Send again',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isLoading 
                                          ? const Color(0xFFBDBDBD)
                                          : const Color(0xFFDE0D0D),
                                      fontWeight: FontWeight.w500,
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
    );
  }
}