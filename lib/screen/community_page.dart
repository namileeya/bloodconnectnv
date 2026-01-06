import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/stories.dart'; 
import '../widget/communityplus.dart';
import '../widget/myteam.dart';

// Community page with stories, community+, and my team tabs
class CommunityPage extends StatefulWidget {
  final int initialTabIndex;
  const CommunityPage({super.key, this.initialTabIndex = 0});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Team state management
  Map<String, dynamic>? _currentUserTeam;
  List<Map<String, dynamic>> _userTeams = []; // Store all user's teams
  late AnimationController _tabAnimationController;
  late Animation<double> _tabAnimation;
  
  // User data
  String fullName = "User";
  String userId = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Set the initial tab index from the parameter
    _selectedTabIndex = widget.initialTabIndex;
    
    // Initialize animation controller for smooth tab transitions
    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Start animation
    _tabAnimationController.forward();
    
    // Initialize user data and team status from Firebase
    _initializeData();
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    super.dispose();
  }

  // Initialize user data and team status
  Future<void> _initializeData() async {
    try {
      // Get current user
      User? currentUser = _auth.currentUser;
      
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No user logged in')),
          );
        }
        return;
      }

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists && mounted) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userId = currentUser.uid;
          fullName = userData['fullName'] ?? 'User';
        });
      }

      // Fetch user's teams
      await _fetchUserTeams();

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing data: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  // Fetch all teams where user is a member
  Future<void> _fetchUserTeams() async {
    try {
      if (userId.isEmpty) return;

      List<Map<String, dynamic>> teams = [];

      // Get all teams
      QuerySnapshot teamsSnapshot = await _firestore.collection('teams').get();

      // Check each team for user membership
      for (var teamDoc in teamsSnapshot.docs) {
        // Check if user exists in team_members sub-collection
        DocumentSnapshot memberDoc = await _firestore
            .collection('teams')
            .doc(teamDoc.id)
            .collection('team_members')
            .doc(userId)
            .get();

        if (memberDoc.exists) {
          Map<String, dynamic> teamData = teamDoc.data() as Map<String, dynamic>;
          teamData['teamId'] = teamDoc.id;
          teams.add(teamData);
        }
      }

      if (mounted) {
        setState(() {
          _userTeams = teams;
          // Set current team to first team if available
          _currentUserTeam = teams.isNotEmpty ? teams[0] : null;
        });
      }
    } catch (e) {
      print('Error fetching user teams: $e');
    }
  }

  // Get user initials from full name
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
    
    // Restart animation for smooth transition
    _tabAnimationController.reset();
    _tabAnimationController.forward();
  }

  // Handle when user joins a team from Community+
  void _onTeamJoined(Map<String, dynamic> teamData) async {
    // Refresh user's teams
    await _fetchUserTeams();
    
    setState(() {
      // Set the newly joined team as current
      _currentUserTeam = teamData;
      // Automatically switch to My Team tab to show the joined team
      _selectedTabIndex = 2;
    });
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Welcome to ${teamData['name']}! 🎉'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDE0D0D),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Handle when user leaves team or has no team
  void _onNoTeam() async {
    // Refresh user's teams
    await _fetchUserTeams();
    
    setState(() {
      // If user has other teams, set to first team, otherwise null
      _currentUserTeam = _userTeams.isNotEmpty ? _userTeams[0] : null;
      
      // If no teams at all, switch to Community+ tab
      if (_userTeams.isEmpty) {
        _selectedTabIndex = 1;
      }
    });
  }

  // Handle team switching in My Team tab
  void _onTeamSwitched(Map<String, dynamic> teamData) {
    setState(() {
      _currentUserTeam = teamData;
    });
  }

  // Add this method for NavigationHelper compatibility
  void _updateNavIndex(int index) {
    // This method can be empty since we're not updating any state for this page
    // It's just required by the NavigationHelper
  }

  // Get appropriate content widget based on selected tab
  Widget _getTabContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDE0D0D),
        ),
      );
    }

    switch (_selectedTabIndex) {
      case 0:
        return StoriesWidget(userId: userId);
      case 1:
        return CommunityPlusWidget(
          userId: userId,
          userName: fullName,
          onTeamJoined: _onTeamJoined,
          userTeams: _userTeams,
        );
      case 2:
        return MyTeamWidget(
          userId: userId,
          userName: fullName,
          joinedTeam: _currentUserTeam,
          allUserTeams: _userTeams,
          onNoTeam: _onNoTeam,
          onTeamSwitched: _onTeamSwitched,
        );
      default:
        return StoriesWidget(userId: userId);
    }
  }

  // Get section header text
  String _getSectionHeader() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Stories from Our Donors';
      case 1:
        return ''; // Community+ has its own header
      case 2:
        return 'My Teams';
      default:
        return '';
    }
  }

  // Get section subtitle
  String _getSectionSubtitle() {
    switch (_selectedTabIndex) {
      case 0:
        return 'Hear firsthand from people like you who have experienced blood donation.';
      case 1:
        return '';
      case 2:
        return _userTeams.isNotEmpty 
            ? 'Manage your teams and track your collective impact.'
            : '';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Use CustomHeader
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with back button to home page
            Row(
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
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Community',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Add team status indicator
                if (_userTeams.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE0D0D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDE0D0D).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group,
                          size: 14,
                          color: Color(0xFFDE0D0D),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_userTeams.length} Team${_userTeams.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDE0D0D),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Tab selector with enhanced animation
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabButton(0),
                  _buildTabButton(1),
                  _buildTabButton(2),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Section header with fade animation
            if (_getSectionHeader().isNotEmpty) ...[
              FadeTransition(
                opacity: _tabAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getSectionHeader(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (_getSectionSubtitle().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _getSectionSubtitle(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Content based on selected tab with slide animation
            Expanded(
              child: FadeTransition(
                opacity: _tabAnimation,
                child: _getTabContent(),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: -1, // Set to -1 to keep all icons grey/unselected
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }

  // Enhanced tab button with better visual feedback
  Widget _buildTabButton(int index) {
    final bool isSelected = _selectedTabIndex == index;
    final bool hasTeamNotification = index == 2 && _userTeams.isNotEmpty;
    final String title = _getTabTitle(index);
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFDE0D0D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFDE0D0D).withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              // Team status indicator
              if (hasTeamNotification && !isSelected)
                Positioned(
                  top: 0,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDE0D0D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Get tab title
  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return 'Stories';
      case 1:
        return 'Community+';
      case 2:
        return 'My Team';
      default:
        return '';
    }
  }
}