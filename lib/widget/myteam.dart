import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_team.dart';

class MyTeamWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final Map<String, dynamic>? joinedTeam; // Currently selected team
  final List<Map<String, dynamic>> allUserTeams; // All teams user is part of
  final VoidCallback? onNoTeam; // Callback when user has no team
  final Function(Map<String, dynamic>)? onTeamSwitched; // Callback when switching teams
  
  const MyTeamWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.joinedTeam,
    required this.allUserTeams,
    this.onNoTeam,
    this.onTeamSwitched,
  });

  @override
  State<MyTeamWidget> createState() => _MyTeamWidgetState();
}

class _MyTeamWidgetState extends State<MyTeamWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? currentTeam;
  List<Map<String, dynamic>> teamMembers = [];
  bool isLoading = false;
  bool isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _initializeTeamData();
  }

  @override
  void didUpdateWidget(MyTeamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.joinedTeam != oldWidget.joinedTeam ||
        widget.allUserTeams.length != oldWidget.allUserTeams.length) {
      _initializeTeamData();
    }
  }

  void _initializeTeamData() {
    setState(() {
      currentTeam = widget.joinedTeam;
    });
    
    if (currentTeam != null) {
      _fetchTeamMembers();
    }
  }

  // Fetch team members from team_members sub-collection
  Future<void> _fetchTeamMembers() async {
    if (currentTeam == null) return;
    
    setState(() => isLoadingMembers = true);
    
    try {
      QuerySnapshot membersSnapshot = await _firestore
          .collection('teams')
          .doc(currentTeam!['teamId'])
          .collection('team_members')
          .orderBy('joinedAt', descending: false)
          .get();
      
      List<Map<String, dynamic>> members = [];
      
      for (var doc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = doc.data() as Map<String, dynamic>;
        memberData['memberId'] = doc.id;
        
        // Fetch additional user data if needed
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(doc.id)
              .get();
          
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            memberData['fullName'] = userData['fullName'] ?? memberData['userName'];
            memberData['initials'] = _getInitials(userData['fullName'] ?? memberData['userName']);
          } else {
            memberData['fullName'] = memberData['userName'];
            memberData['initials'] = _getInitials(memberData['userName']);
          }
        } catch (e) {
          memberData['fullName'] = memberData['userName'];
          memberData['initials'] = _getInitials(memberData['userName']);
        }
        
        members.add(memberData);
      }
      
      if (mounted) {
        setState(() {
          teamMembers = members;
          isLoadingMembers = false;
        });
      }
    } catch (e) {
      print('Error fetching team members: $e');
      if (mounted) {
        setState(() => isLoadingMembers = false);
      }
    }
  }

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

  // Leave team - remove from team_members sub-collection
  Future<void> _leaveTeamInFirebase() async {
    if (currentTeam == null) return;
    
    setState(() => isLoading = true);
    
    try {
      // Remove user from team_members sub-collection
      await _firestore
          .collection('teams')
          .doc(currentTeam!['teamId'])
          .collection('team_members')
          .doc(widget.userId)
          .delete();
      
      // Update team's memberCount
      await _firestore
          .collection('teams')
          .doc(currentTeam!['teamId'])
          .update({
        'memberCount': FieldValue.increment(-1),
      });
      
      // Check if user is the only member and should delete the team
      QuerySnapshot remainingMembers = await _firestore
          .collection('teams')
          .doc(currentTeam!['teamId'])
          .collection('team_members')
          .get();
      
      if (remainingMembers.docs.isEmpty) {
        // Delete the team if no members left
        await _firestore
            .collection('teams')
            .doc(currentTeam!['teamId'])
            .delete();
      }
      
      setState(() {
        currentTeam = null;
        teamMembers = [];
      });
      
      // Notify parent widget that user has no team (or switched to another)
      if (widget.onNoTeam != null) {
        widget.onNoTeam!();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully left the team'),
            backgroundColor: Color(0xFFDE0D0D),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Error leaving team: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave team: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDE0D0D),
        ),
      );
    }

    return SingleChildScrollView(
      child: currentTeam != null ? _buildTeamInfo() : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Team icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Three person icons arranged in a group
                    Positioned(
                      left: 15,
                      top: 20,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDE0D0D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 15,
                      top: 20,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDE0D0D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 25,
                      top: 20,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDE0D0D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Main team container
                    Positioned(
                      bottom: 15,
                      child: Container(
                        width: 45,
                        height: 35,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFDE0D0D),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Team details
              const Text(
                'Team Name:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const Text(
                '-',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Team Members:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Created:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const Text(
                          '-',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Message text
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'It appears you have not yet joined a team. You may create a new team or join an existing one to begin your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ),
        
        const SizedBox(height: 30),
        
        // Action buttons
        Column(
          children: [
            // Create Team button
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: () => _navigateToCreateTeam(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: const Text('Create Team'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Join Team button
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to Community+ tab
                  if (widget.onNoTeam != null) {
                    widget.onNoTeam!();
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDE0D0D),
                  side: const BorderSide(color: Color(0xFFDE0D0D)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                child: const Text('Join Existing Team'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamInfo() {
    return Column(
      children: [
        // Team switcher dropdown (if user has multiple teams)
        if (widget.allUserTeams.length > 1) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Color(0xFFDE0D0D), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Switch Team:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: currentTeam!['teamId'],
                    isExpanded: true,
                    underline: Container(),
                    items: widget.allUserTeams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team['teamId'],
                        child: Text(
                          team['name'],
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newTeamId) {
                      if (newTeamId != null) {
                        Map<String, dynamic>? selectedTeam = widget.allUserTeams
                            .firstWhere((team) => team['teamId'] == newTeamId);
                        
                        setState(() {
                          currentTeam = selectedTeam;
                        });
                        
                        _fetchTeamMembers();
                        
                        if (widget.onTeamSwitched != null) {
                          widget.onTeamSwitched!(selectedTeam);
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Team overview card
        Container(
          margin: const EdgeInsets.symmetric(vertical: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Team icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group,
                  size: 40,
                  color: Color(0xFFDE0D0D),
                ),
              ),
              const SizedBox(height: 24),
              
              // Team name
              const Text(
                'Team Name:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              Text(
                currentTeam!['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDE0D0D),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Team Members:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          '${currentTeam!['memberCount'] ?? teamMembers.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDE0D0D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Created:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _formatDate(currentTeam!['createdAt']),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDE0D0D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Team description card
        if (currentTeam!['description'] != null && currentTeam!['description'].toString().isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About Team',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentTeam!['description'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showLeaveTeamDialog(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDE0D0D),
                  side: const BorderSide(color: Color(0xFFDE0D0D)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Leave Team'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Team members section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Team Members',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${teamMembers.length} members',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (isLoadingMembers)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      color: Color(0xFFDE0D0D),
                    ),
                  ),
                )
              else if (teamMembers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No members found',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...teamMembers.map<Widget>((member) {
                  bool isCurrentUser = member['memberId'] == widget.userId;
                  bool isLeader = member['role'] == 'admin';
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFDE0D0D),
                          child: Text(
                            member['initials'] ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCurrentUser ? 'You' : (member['fullName'] ?? member['userName'] ?? 'Unknown'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Joined: ${_formatDate(member['joinedAt'])}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isLeader)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDE0D0D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Leader',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDE0D0D),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToCreateTeam() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: Colors.grey[100],
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
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
                const Text(
                  'Create Team',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CreateTeamWidget(
              userId: widget.userId,
              userName: widget.userName,
              onTeamCreated: (teamData) {
                Navigator.pop(context);
                
                // Update the current team state
                setState(() {
                  currentTeam = teamData;
                });
                
                // Fetch team members for the new team
                _fetchTeamMembers();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Team "${teamData['name']}" created successfully! 🎉'),
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
              },
              onCancel: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  void _showLeaveTeamDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Leave Team',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(
            'Are you sure you want to leave ${currentTeam!['name']}? You can always join another team later.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _leaveTeamInFirebase();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
}