import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../screen/myreward_page.dart';
import '../screen/notification_page.dart';
import '../screen/login_page.dart';
import '../user_session.dart';
import '../screen/edit_information.dart';
import '../screen/change_password.dart';
import '../screen/information_page.dart';
import '../screen/profile_page.dart';



class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  final String? userInitials;
  final String? fullName; // Now optional since we'll fetch from Firestore
  final VoidCallback? onRewardsPressed;
  final VoidCallback? onNotificationsPressed;
  final VoidCallback? onProfilePressed;
  final String? currentPage;
  
  // Add Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  const CustomHeader({
    super.key,
    this.appName = 'BloodConnect',
    this.userInitials,
    this.fullName,
    this.onRewardsPressed,
    this.onNotificationsPressed,
    this.onProfilePressed,
    this.currentPage,
  });

  // Helper method to extract initials from full name
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Fetch user data from Firestore
  Future<Map<String, dynamic>?> _fetchUserDataFromFirestore() async {
    try {
      // Get current user ID from Firebase Auth
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        // Fallback to session data
        return await UserSession.getUser();
      }
      
      // Fetch from donor_profiles collection
      DocumentSnapshot userDoc = await _firestore
          .collection('donor_profiles')
          .doc(firebaseUser.uid)
          .get();
      
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Also update session with latest data
        await UserSession.saveUser({
          'userId': firebaseUser.uid,
          'fullName': userData['full_name'] ?? '',
          'bloodType': userData['blood_group'] ?? '',
          'email': firebaseUser.email ?? '',
        });
        
        return {
          'userId': firebaseUser.uid,
          'fullName': userData['full_name'] ?? 'Unknown User',
          'bloodType': userData['blood_group'] ?? 'Unknown',
          'email': firebaseUser.email ?? '',
        };
      } else {
        // If no donor profile, try users collection as fallback
        DocumentSnapshot usersDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        
        if (usersDoc.exists) {
          Map<String, dynamic> userData = usersDoc.data() as Map<String, dynamic>;
          await UserSession.saveUser({
            'userId': firebaseUser.uid,
            'fullName': userData['username'] ?? 'Unknown User',
            'bloodType': '',
            'email': userData['email'] ?? '',
          });
          
          return {
            'userId': firebaseUser.uid,
            'fullName': userData['username'] ?? 'Unknown User',
            'bloodType': '',
            'email': userData['email'] ?? '',
          };
        }
        
        // Fallback to session data
        return await UserSession.getUser();
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Fallback to session data on error
      return await UserSession.getUser();
    }
  }

  // Handle logout
  Future<void> _handleLogout(BuildContext context) async {
    try {
      // Sign out from Firebase Auth
      await _auth.signOut();
      
      // Clear session data
      await UserSession.logout();
      
      // Navigate to login page and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Replace with your actual LoginPage
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      // Even if Firebase logout fails, clear session and navigate
      await UserSession.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get initial data from constructor or generate placeholder
    String initialDisplayName = fullName ?? 'Unknown User';
    String initialDisplayInitials = userInitials ?? _getInitials(initialDisplayName);

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Image.asset(
            'assets/bloodconnect logo 5.png',
            width: 25,
            height: 25,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 4),
          Text(
            appName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.card_giftcard,
            color: currentPage == 'rewards' ? const Color(0xFFDE0D0D) : Colors.black,
            size: 24,
          ),
          onPressed: onRewardsPressed ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyRewardPage()),
            );
          },
        ),
        IconButton(
          icon: Icon(
            Icons.notifications_outlined,
            color: currentPage == 'notifications' ? const Color(0xFFDE0D0D) : Colors.black,
            size: 24,
          ),
          onPressed: onNotificationsPressed ?? () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationPage()),
            );
          },
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: onProfilePressed ?? () {
              _showProfileMenu(context, initialDisplayInitials);
            },
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 14,
              child: Text(
                initialDisplayInitials,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Updated profile menu with dynamic data
  void _showProfileMenu(BuildContext context, String initialInitials) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: _fetchUserDataFromFirestore(),
          builder: (context, snapshot) {
            // Handle loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildProfileMenuLoading(context, initialInitials);
            }
            
            // Handle error state
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildProfileMenuWithError(context, initialInitials);
            }
            
            // Success state - build with dynamic data
            final userData = snapshot.data!;
            final displayName = userData['fullName'] ?? 'Unknown User';
            final bloodType = userData['bloodType']?.toString().isNotEmpty == true 
                ? userData['bloodType'] 
                : 'Unknown';
            final displayInitials = _getInitials(displayName);
            
            return _buildProfileMenuContent(
              context, 
              displayName, 
              bloodType, 
              displayInitials
            );
          },
        );
      },
    );
  }

  Widget _buildProfileMenuLoading(BuildContext context, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDE0D0D),
                radius: 25,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading skeleton for name
                  SizedBox(
                    width: 150,
                    height: 16,
                    child: ColoredBox(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Loading skeleton for blood type
                  SizedBox(
                    width: 100,
                    height: 12,
                    child: ColoredBox(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileMenuWithError(BuildContext context, String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDE0D0D),
                radius: 25,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unknown User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Blood Type: Unknown',
                    style: const TextStyle(
                      color: Color(0xFFDE0D0D),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Failed to load profile data',
            style: TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 10),
          _profileMenuItem(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditInformation()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePassword()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodInfoPage()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenuContent(BuildContext context, String displayName, String bloodType, String displayInitials) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFDE0D0D),
                radius: 25,
                child: Text(
                  displayInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Blood Type: ${bloodType.isNotEmpty ? bloodType : 'Unknown'}',
                    style: const TextStyle(
                      color: Color(0xFFDE0D0D),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _profileMenuItem(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChangePassword()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodInfoPage()),
              );
            },
          ),
          _profileMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _profileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFFDE0D0D),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}