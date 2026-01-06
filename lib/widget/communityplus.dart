import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_team.dart';

class CommunityPlusWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final List<Map<String, dynamic>> userTeams; // Teams user has already joined
  final Function(Map<String, dynamic>)? onTeamJoined; // Callback when team is joined
  
  const CommunityPlusWidget({
    super.key,
    required this.userId,
    required this.userName,
    required this.userTeams,
    this.onTeamJoined,
  });

  @override
  State<CommunityPlusWidget> createState() => _CommunityPlusWidgetState();
}

class _CommunityPlusWidgetState extends State<CommunityPlusWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  
  bool isLoading = true;
  List<Map<String, dynamic>> _allTeams = [];
  List<Map<String, dynamic>> _filteredTeams = [];

  @override
  void initState() {
    super.initState();
    _fetchTeamsFromFirebase();
  }

  @override
  void didUpdateWidget(CommunityPlusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh teams if user's teams changed
    if (widget.userTeams.length != oldWidget.userTeams.length) {
      _fetchTeamsFromFirebase();
    }
  }

  // Fetch teams from Firebase
  Future<void> _fetchTeamsFromFirebase() async {
    setState(() => isLoading = true);
    
    try {
      // Get all teams from Firestore
      QuerySnapshot teamsSnapshot = await _firestore
          .collection('teams')
          .orderBy('memberCount', descending: true)
          .get();
      
      List<Map<String, dynamic>> teams = [];
      
      for (var doc in teamsSnapshot.docs) {
        Map<String, dynamic> teamData = doc.data() as Map<String, dynamic>;
        teamData['teamId'] = doc.id;
        
        // Get member count from team_members sub-collection
        QuerySnapshot membersSnapshot = await _firestore
            .collection('teams')
            .doc(doc.id)
            .collection('team_members')
            .get();
        
        teamData['memberCount'] = membersSnapshot.size;
        
        // Check if user is already in this team
        bool isUserInTeam = widget.userTeams.any((team) => team['teamId'] == doc.id);
        
        // Only add teams user hasn't joined
        if (!isUserInTeam) {
          teams.add(teamData);
        }
      }
      
      if (mounted) {
        setState(() {
          _allTeams = teams;
          _filteredTeams = teams;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching teams: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to load teams. Please try again.');
      }
    }
  }

  // Join team and add to team_members sub-collection
  Future<void> _joinTeamInFirebase(Map<String, dynamic> team) async {
    setState(() => isLoading = true);
    
    try {
      // Add user to team_members sub-collection
      await _firestore
          .collection('teams')
          .doc(team['teamId'])
          .collection('team_members')
          .doc(widget.userId)
          .set({
        'userId': widget.userId,
        'userName': widget.userName,
        'role': 'member', // Regular member, not admin
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Update team's memberCount
      await _firestore
          .collection('teams')
          .doc(team['teamId'])
          .update({
        'memberCount': FieldValue.increment(1),
      });
      
      // Notify parent widget about successful team join
      if (widget.onTeamJoined != null) {
        widget.onTeamJoined!(team);
      }
      
      // Refresh teams list
      await _fetchTeamsFromFirebase();
      
    } catch (e) {
      print('Error joining team: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Failed to join team. Please try again.');
      }
    }
  }

  void _filterTeams(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeams = _allTeams;
      } else {
        _filteredTeams = _allTeams.where((team) {
          return team['name'].toLowerCase().contains(query.toLowerCase()) ||
                 (team['description'] ?? '').toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join Our Community',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Together, we can save more lives. Be part of a team that makes a real difference every day!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Create Team button
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateTeam(),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterTeams,
            decoration: InputDecoration(
              hintText: 'Search teams by name...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[500],
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        _searchController.clear();
                        _filterTeams('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Teams list
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFDE0D0D),
                  ),
                )
              : _filteredTeams.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFDE0D0D),
                      onRefresh: _fetchTeamsFromFirebase,
                      child: ListView.builder(
                        itemCount: _filteredTeams.length,
                        itemBuilder: (context, index) {
                          return _buildTeamCard(_filteredTeams[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              // Team icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.group,
                  color: Color(0xFFDE0D0D),
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Team info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team['description'] ?? 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // View Details button
              ElevatedButton(
                onPressed: () => _showTeamDetailsDialog(team),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Team stats
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Members',
                  '${team['memberCount'] ?? 0}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Created',
                  _formatDate(team['createdAt']),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDE0D0D),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchController.text.isEmpty ? Icons.groups : Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty 
                ? 'No teams available yet'
                : 'No teams found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Be the first to create a team!'
                : 'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _navigateToCreateTeam(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Create Team'),
            ),
          ],
        ],
      ),
    );
  }

  void _showTeamDetailsDialog(Map<String, dynamic> team) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE0D0D).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE0D0D).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Color(0xFFDE0D0D),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Created by ${team['createdBy'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildDetailStatItem(
                                'Members',
                                '${team['memberCount'] ?? 0}',
                                Icons.people,
                              ),
                            ),
                            Expanded(
                              child: _buildDetailStatItem(
                                'Created',
                                _formatDate(team['createdAt']),
                                Icons.calendar_today,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Description
                        const Text(
                          'About This Team',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          team['description'] ?? 'No description available.',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[300]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _joinTeam(team),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDE0D0D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Join Team',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFFDE0D0D),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDE0D0D),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _joinTeam(Map<String, dynamic> team) {
    Navigator.of(context).pop(); // Close the details dialog
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Join Team',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Are you sure you want to join ${team['name']}? You\'ll be able to participate in team activities and contribute to saving lives together.',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _joinTeamInFirebase(team);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Join',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
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
                
                // Notify parent that user joined a team (their own created team)
                if (widget.onTeamJoined != null) {
                  widget.onTeamJoined!(teamData);
                }
                
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
}