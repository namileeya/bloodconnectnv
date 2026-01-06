import 'package:flutter/material.dart';
import '../screen/notification_page.dart';
import '../screen/myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/header.dart';

class FindDonorsTutorial extends StatefulWidget {
  const FindDonorsTutorial({super.key});

  @override
  State<FindDonorsTutorial> createState() => _FindDonorsTutorialState();
}

class _FindDonorsTutorialState extends State<FindDonorsTutorial> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Add user data (same as in BloodInfoPage)
  final String fullName = "AMMAL ALIYA BINTI MISRON";
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 3; // Learn tab is selected (index 3)

  // Tutorial steps data
  final List<Map<String, dynamic>> _tutorialSteps = [
    {
      'step': 1,
      'title': 'Click \'Find Donors\' to Start',
      'subtitle': 'Access the donor search feature from homepage',
      'description': 'From the main dashboard, you can see various features like Blood Journey, Snap and Share, Raise Awareness, and Community. Look for the "Find Donors" button with a magnifying glass icon in the bottom section to begin searching for blood donors who can help with urgent blood needs.',
      'image': 'assets/find_donors_1.png',
    },
    {
      'step': 2,
      'title': 'Fill Blood Request Form',
      'subtitle': 'Enter patient location and basic details',
      'description': 'Start by filling out the Blood Request Form. First, select the patient\'s location from the dropdown menu - this helps find nearby donors. Then enter the patient\'s name in the required field. You can also add optional reasons or description in the text area to provide more context about the blood request.',
      'image': 'assets/find_donors_2.png',
    },
    {
      'step': 3,
      'title': 'Select Blood Group & Review',
      'subtitle': 'Choose the required blood type and confirm details',
      'description': 'Scroll down to see all available blood group options: A+, A-, B+, B-, O+, O-, AB+, and AB-. Select the specific blood group that the patient needs. This is crucial information as donors must match the required blood type. Check the confirmation checkbox to verify that all information provided is true, accurate, and complete. Note that each request will be validated by the respective hospital.',
      'image': 'assets/find_donors_3.png',
    },
    {
      'step': 4,
      'title': 'Request Successfully Submitted',
      'subtitle': 'Your donor request is now active',
      'description': 'Congratulations! Your blood donor request has been successfully submitted to the BloodConnect system. The success modal with green checkmark confirms your submission. You will receive notifications when suitable donors are found who match your requirements. The system will inform potential donors about your request, and they can choose to help based on their availability and compatibility.',
      'image': 'assets/find_donors_4.png',
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

  // Enhanced phone mockup widget with better fitted image
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
            color: const Color.fromARGB(76, 0, 0, 0),
            spreadRadius: 0,
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color.fromRGBO(0, 0, 0, 0.1),
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
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.fitHeight,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone_android,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Image Loading...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
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
                      'How to Find Donors',
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
                              color: Colors.grey.withValues(alpha: 0.08),
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
                      
                      // Phone mockup
                      _buildPhoneMockup(step['image']),
                      
                      const SizedBox(height: 24),
                      
                      // Description card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0x19DE0D0D) ,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
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
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }
}