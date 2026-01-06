import 'package:flutter/material.dart';
import '../screen/notification_page.dart';
import '../screen/myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../widget/header.dart';

class DonateNowTutorial extends StatefulWidget {
  const DonateNowTutorial({super.key});

  @override
  State<DonateNowTutorial> createState() => _DonateNowTutorialState();
}

class _DonateNowTutorialState extends State<DonateNowTutorial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Add user data (same as in BloodInfoPage)
  final String fullName = "AMMAL ALIYA BINTI MISRON";
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 3; // Learn tab is selected (index 3)

  // Tutorial steps data - Updated with correct image paths
  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'step': 1,
      'title': 'Click \'Donate Now\' to Start',
      'subtitle': 'Access the donation feature from homepage',
      'description': 'From the main dashboard, you can see various features organized in a grid layout. The "Donate Now" button is prominently displayed with a heart icon. This red-highlighted button in the center-right section will take you to the blood donation process. Tap on it to begin your journey as a blood donor.',
      'image': 'assets/donate_now_1.png',
      'hasMultipleImages': false,
    },
    {
      'step': 2,
      'title': 'Choose Your Donation Venue',
      'subtitle': 'Select from available blood donation centers',
      'description': 'Browse through the list of available donation venues. Each venue shows its full name, location details, and has a distinctive icon (HK for Hospital Kuala Lumpur, HS for Hospital Sultanah Aminah, etc.). You can see venues like Hospital Kuala Lumpur, Hospital Sultanah Aminah, Pusat Darah Negara, and Hospital Penang. Select your preferred venue by tapping on it, then tap "Next" to continue.',
      'image': 'assets/donate_now_2.png',
      'hasMultipleImages': false,
    },
    {
      'step': 3,
      'title': 'Read Important Information',
      'subtitle': 'Understanding blood donation requirements',
      'description': 'You will encounter important information screens about blood donation. The first screen explains that blood donation is a noble act that saves lives, covering health requirements and the pre-screening process. The second screen provides detailed information about the donation process, emphasizing the importance of honesty during interviews. Read through all information carefully and check the acknowledgment box before proceeding.',
      'image': 'assets/donate_now_3.png',
      'image2': 'assets/donate_now_4.png',
      'hasMultipleImages': true,
    },
    {
      'step': 4,
      'title': 'Complete Pre-Screening Questions',
      'subtitle': 'Answer health and eligibility questions',
      'description': 'You will complete comprehensive pre-screening questionnaires across multiple screens. This includes "General Health" questions about wellness, flu/infections, chronic diseases, and cancer history. You will also answer COVID-19 related questions and women-specific questions covering pregnancy, breastfeeding, and menstrual cycle. Answer all questions honestly by selecting "Yes" or "No" for each question.',
      'image': 'assets/donate_now_5.png',
      'image2': 'assets/donate_now_6.png',
      'hasMultipleImages': true,
    },
    {
      'step': 5,
      'title': 'Request Submitted Successfully',
      'subtitle': 'Your donation request has been processed',
      'description': 'Congratulations! Your donation request has been successfully submitted. The system shows a green checkmark with the message "Request Submitted" and "One step closer to saving lives. Thank you!" This confirmation indicates that your pre-screening has been completed and your request is now in the system. The blood donation center will process your request and contact you with further instructions.',
      'image': 'assets/donate_now_7.png',
      'hasMultipleImages': false,
    },
  ];

  // Method to get user initials from full name
  String _getUserInitials() {
    List<String> nameParts = fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    // Take first letter of first name and first letter of last name
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Simplified navigation handler that updates the selected index
  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  // Enhanced phone mockup widget with better error handling
  Widget _buildPhoneMockup(String imagePath) {
    return Container(
      width: 272,
      height: 560,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4D000000), // 30% opacity black
            spreadRadius: 0,
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x1A000000), // 10% opacity black
            spreadRadius: 0,
            blurRadius: 45,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Screen area
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: FutureBuilder<bool>(
                  future: _checkImageExists(imagePath),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!) {
                      return Image.asset(
                        imagePath,
                        fit: BoxFit.fitHeight,
                        alignment: Alignment.center,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderContent();
                        },
                      );
                    } else {
                      return _buildPlaceholderContent();
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Dynamic Island / Notch
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Extracted placeholder content to avoid duplication
  Widget _buildPlaceholderContent() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0x1ADE0D0D), // 10% opacity of red color
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bloodtype,
              size: 60,
              color: Color(0xFFDE0D0D),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tutorial Step',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${_currentPage + 1} of ${_tutorialSteps.length}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // Method to check if image exists
  Future<bool> _checkImageExists(String imagePath) async {
    try {
      await DefaultAssetBundle.of(context).load(imagePath);
      return true;
    } catch (e) {
      debugPrint('Image not found: $imagePath');
      return false;
    }
  }

  // Dual phone mockup widget for steps with multiple images - now vertical layout
Widget _buildDualPhoneMockup(String imagePath1, String imagePath2) {
  final step = _tutorialSteps[_currentPage];
  
  return Column(
    children: [
      // First phone mockup
      _buildPhoneMockup(imagePath1),
      
      const SizedBox(height: 16),
      
      // First explanation
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x19DE0D0D),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14808080),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x19DE0D0D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'STEP ${step['step']}A',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDE0D0D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step['description1'] ?? _getFirstHalfDescription(step['description']),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      
      const SizedBox(height: 24),
      
      // Second phone mockup
      _buildPhoneMockup(imagePath2),
      
      const SizedBox(height: 16),
      
      // Second explanation
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0x19DE0D0D),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14808080),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x19DE0D0D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'STEP ${step['step']}B',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDE0D0D),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step['description2'] ?? _getSecondHalfDescription(step['description']),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Helper method to split description into first half
String _getFirstHalfDescription(String fullDescription) {
  List<String> sentences = fullDescription.split('. ');
  int midPoint = (sentences.length / 2).ceil();
  return sentences.take(midPoint).join('. ') + (sentences.length > 1 ? '.' : '');
}

// Helper method to split description into second half  
String _getSecondHalfDescription(String fullDescription) {
  List<String> sentences = fullDescription.split('. ');
  int midPoint = (sentences.length / 2).ceil();
  if (sentences.length <= 1) return '';
  return sentences.skip(midPoint).join('. ') ;
}

  Widget _buildStepIndicator(int stepNumber, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFFDE0D0D) : Colors.grey[200],
        boxShadow: isActive ? [
          BoxShadow(
            color: const Color(0x4DDE0D0D),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          stepNumber.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
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
      body: Column(
        children: [
          // Enhanced header section
          Container(
            width: double.infinity,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'How to Donate Blood Now',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Progress indicator
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _tutorialSteps.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildStepIndicator(index + 1, index == _currentPage),
                ),
              ),
            ),
          ),
          
          // Content area
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Step title card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14808080), // 8% opacity grey
                              spreadRadius: 0,
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0x19DE0D0D),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'STEP ${step['step']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDE0D0D),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              step['title'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              step['subtitle'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone mockup (single or dual based on step)
                      step['hasMultipleImages'] == true
                          ? _buildDualPhoneMockup(step['image'], step['image2'])
                          : _buildPhoneMockup(step['image']),
                      
                      // Description card - only show for single image steps
                      if (step['hasMultipleImages'] != true) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0x19DE0D0D),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x14808080), // 8% opacity grey
                                spreadRadius: 0,
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            step['description'],
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey[700],
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Navigation controls
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                _currentPage > 0
                    ? TextButton.icon(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(Icons.arrow_back_ios, size: 16),
                        label: const Text('Previous'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      )
                    : const SizedBox(width: 80),
                
                // Page indicators (dots)
                Row(
                  children: List.generate(
                    _tutorialSteps.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: index == _currentPage ? 20 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: index == _currentPage 
                            ? const Color(0xFFDE0D0D) 
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
                
                // Next button
                _currentPage < _tutorialSteps.length - 1
                    ? TextButton.icon(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        label: const Text('Next'),
                        icon: const Icon(Icons.arrow_forward_ios, size: 16),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFDE0D0D),
                          backgroundColor: const Color(0x19DE0D0D),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )
                    : TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: const Color(0xFFDE0D0D),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          _updateNavIndex(index);
          // Add your navigation logic here
          switch (index) {
            case 0:
              // Navigate to Home
              break;
            case 1:
              // Navigate to History
              break;
            case 2:
              // Navigate to Favorites
              break;
            case 3:
              // Current page (Learn)
              break;
            case 4:
              // Navigate to Profile
              break;
          }
        },
      ),
    );
  }
}