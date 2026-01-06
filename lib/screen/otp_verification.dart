import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'password_reset_page.dart';

class OTPVerificationPage extends StatefulWidget {
  final String phoneNumber;
  
  const OTPVerificationPage({
    super.key,
    required this.phoneNumber,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  // Show success dialog when verification is complete
  void _showSuccessDialog(BuildContext context) {
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
                // Success icon
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
                    Icons.check,
                    color: Color(0xFFDE0D0D),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Success message
                const Text(
                  'Verification Complete!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                const Text(
                  'Your phone number has been verified successfully',
                  style: TextStyle(
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
                
                // Auto close after 2 seconds
                FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 2)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.of(context).pop(); // Close dialog
                        // Navigate to password reset page
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const PasswordResetPage(),
                          ),
                        );
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

  // Resend OTP function
  void _resendOTP() {
    // Show resend confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verification code resent'),
        backgroundColor: Color(0xFFDE0D0D),
        duration: Duration(seconds: 2),
      ),
    );

    // Here you can add Firebase resend OTP logic later
    // FirebaseAuth.instance.verifyPhoneNumber(...)
  }

  // Verify OTP function
  void _verifyOTP() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Simulate verification delay
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
        
        // Show success dialog
        _showSuccessDialog(context);
        
        // Here you can add Firebase OTP verification logic later
        // PhoneAuthCredential credential = PhoneAuthProvider.credential(
        //   verificationId: verificationId,
        //   smsCode: _otpController.text,
        // );
      });
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
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
                          'Type a code',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // OTP input field and Resend button row
                        Form(
                          key: _formKey,
                          child: Row(
                            children: [
                              // OTP input field
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the verification code';
                                      }
                                      if (value.length != 6) {
                                        return 'Code must be 6 digits';
                                      }
                                      return null;
                                    },
                                    decoration: const InputDecoration(
                                      hintText: 'Code',
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
                                      counterText: '', // Hide character counter
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Resend button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDE0D0D),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(100, 52),
                                ),
                                onPressed: _resendOTP,
                                child: const Text(
                                  'Resend',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Phone number display and description
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                            children: [
                              const TextSpan(
                                text: 'We texted you a code to verify your phone number ',
                              ),
                              TextSpan(
                                text: widget.phoneNumber,
                                style: const TextStyle(
                                  color: Color(0xFFDE0D0D),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Expiry information
                        const Text(
                          'This code will expired 10 minutes after this message. If you don\'t get a message.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF757575),
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Submit Button
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
                            onPressed: _isLoading ? null : _verifyOTP,
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
                                      'Submit',
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
    );
  }
}