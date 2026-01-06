import 'package:flutter/material.dart';
import '../screen/home_page.dart';
import '../screen/donation_history_page.dart';
import '../screen/donation_page.dart';
import '../screen/profile_page.dart';
import '../screen/information_page.dart';
import '../navigation_helper.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
  // Handle -1 currentIndex by setting it to 0 but keeping colors grey
  int safeCurrentIndex = currentIndex == -1 ? 0 : currentIndex;
  
  return BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedFontSize: 12,
    unselectedFontSize: 12,
    iconSize: 24,
    elevation: 8,
    currentIndex: safeCurrentIndex,
    // If currentIndex is -1, make selected colors grey too
    selectedItemColor: currentIndex == -1 ? Colors.grey : const Color(0xFFDE0D0D),
    unselectedItemColor: Colors.grey,
    backgroundColor: Colors.white,
    selectedLabelStyle: TextStyle(
      fontWeight: currentIndex == -1 ? FontWeight.normal : FontWeight.bold,
    ),
    items: [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: currentIndex == -1 
          ? const Icon(Icons.home_outlined, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home, color: Color(0xFFDE0D0D)),
            ),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.history_outlined),
        activeIcon: currentIndex == -1 
          ? const Icon(Icons.history_outlined, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Color(0xFFDE0D0D)),
            ),
        label: 'History',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.favorite_outline),
        activeIcon: currentIndex == -1 
          ? const Icon(Icons.favorite_outline, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Color(0xFFDE0D0D)),
            ),
        label: 'Donate',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.info_outline),
        activeIcon: currentIndex == -1 
          ? const Icon(Icons.info_outline, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info, color: Color(0xFFDE0D0D)),
            ),
        label: 'Info',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: currentIndex == -1 
          ? const Icon(Icons.person_outline, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Color(0xFFDE0D0D)),
            ),
        label: 'Profile',
      ),
    ],
    onTap: onTap,
  );
}
}

