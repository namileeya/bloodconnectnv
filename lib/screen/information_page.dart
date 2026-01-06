import 'package:flutter/material.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/header.dart';
import '../widget/process.dart';
import '../widget/manual.dart';
import '../widget/tips.dart'; 

// Information page for blood donation education and FAQs
class BloodInfoPage extends StatefulWidget {
  const BloodInfoPage({super.key});

  @override
  State<BloodInfoPage> createState() => _BloodInfoPageState();
}

class _BloodInfoPageState extends State<BloodInfoPage> {
  int _selectedTabIndex = 0; // Start with "Process" tab selected
  
  // Add user data (same as in other pages)
  final String fullName = "AMMAL ALIYA BINTI MISRON";
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 3; // Learn tab is selected (index 3)


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

  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  // Simplified navigation handler that updates the selected index
  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index; // Update the selected nav index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          // Simple header section
          Container(
            width: double.infinity,
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                    GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content area
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Tab selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton('Process', 0),
                          _buildTabButton('Manual', 1),
                          _buildTabButton('Tips', 2),
                        ],
                      ),
                    ),
                  ),

                  // In the expanded widget where you have the tab content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _selectedTabIndex == 0
                          ? const ProcessWidget()
                          : _selectedTabIndex == 1
                              ? const ManualWidget() // Use the new ManualWidget
                              : const TipsWidget(),
                    ),
                  ),
                ],
              ),
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

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}