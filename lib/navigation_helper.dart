// lib/navigation_helper.dart
import 'package:flutter/material.dart';
import 'package:bloodconnect/screen/home_page.dart';
import 'package:bloodconnect/screen/donation_history_page.dart';
import 'package:bloodconnect/screen/donation_page.dart';
import 'package:bloodconnect/screen/information_page.dart';
import 'package:bloodconnect/screen/profile_page.dart';

class NavigationHelper {
  static void handleNavigation(BuildContext context, int index, Function(int) updateNavIndex) {
    updateNavIndex(index);
    
    switch (index) {
      case 0: // Home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      case 1: // History
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonationHistoryPage()),
        );
        break;
      case 2: // Donate
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DonationPage()),
        );
        break;
      case 3: // Info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BloodInfoPage()),
        );
        break;
      case 4: // Profile
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }
}