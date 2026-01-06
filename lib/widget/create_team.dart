import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateTeamWidget extends StatefulWidget {
  final String userId;
  final String userName;
  final Function(Map<String, dynamic>)? onTeamCreated; // Callback when team is created
  final VoidCallback? onCancel; // Callback when user cancels
  
  const CreateTeamWidget({
    super.key,
    required this.userId,
    required this.userName,
    this.onTeamCreated,
    this.onCancel,
  });

  @override
  State<CreateTeamWidget> createState() => _CreateTeamWidgetState();
}

class _CreateTeamWidgetState extends State<CreateTeamWidget> {
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isAgreed = false;
  bool _isLoading = false;
  
  // Predefined team images/avatars (URLs from Unsplash or placeholders)
  final List<String> _teamImages = [
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1579684385127-1ef15d508118?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1582750433449-648ed127bb54?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
    'https://images.unsplash.com/photo-1559757175-0eb30cd8c063?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
  ];
  
  String _selectedImage = '';
  
  @override
  void initState() {
    super.initState();
    // Select first image by default
    _selectedImage = _teamImages[0];
  }

  // Create team in Firebase
  Future<void> _createTeamInFirebase() async {
    if (!_isFormValid()) return;

    setState(() => _isLoading = true);
    
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorMessage('User not logged in');
        return;
      }

      // Generate a unique team ID
      final newTeamRef = _firestore.collection('teams').doc();
      final teamId = newTeamRef.id;
      
      // Prepare team data
      final teamData = {
        'teamId': teamId,
        'name': _teamNameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim()
            : 'A dedicated team working together to save lives through blood donation.',
        'createdBy': widget.userName,
        'createdById': widget.userId,
        'createdAt': FieldValue.serverTimestamp(),
        'memberCount': 1, // Start with 1 (the creator)
        'imageUrl': _selectedImage,
        'status': 'active',
      };
      
      // Create the team document
      await newTeamRef.set(teamData);
      
      // Add creator as admin to team_members sub-collection
      await newTeamRef.collection('team_members').doc(widget.userId).set({
        'userId': widget.userId,
        'userName': widget.userName,
        'role': 'admin', // Creator becomes admin
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Show success popup
      _showSuccessPopup(teamData);
      
      // Wait for popup to be shown, then call callback
      await Future.delayed(const Duration(seconds: 3));
      
      if (widget.onTeamCreated != null) {
        widget.onTeamCreated!(teamData);
      }
      
    } catch (e) {
      print('Error creating team: $e');
      _showErrorMessage('Failed to create team. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isFormValid() {
    return _teamNameController.text.trim().isNotEmpty && _isAgreed;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessPopup(Map<String, dynamic> teamData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildSuccessPopup(teamData);
      },
    );
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 0),
                
                // Form container
                Container(
                  padding: const EdgeInsets.all(20),
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
                      // Upload Team Picture section
                      const Text(
                        'Choose Team Picture:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Image selection grid
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _teamImages.length,
                          itemBuilder: (context, index) {
                            final imageUrl = _teamImages[index];
                            final isSelected = _selectedImage == imageUrl;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImage = imageUrl;
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey[300]!,
                                    width: isSelected ? 3 : 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, color: Colors.grey),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Team Name section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Team Name:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Team name input
                      TextField(
                        controller: _teamNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter team name',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDE0D0D)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Team Description (optional)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Team Description (Optional):',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Description input
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe your team\'s purpose or mission...',
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFDE0D0D)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Terms and conditions checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isAgreed,
                            onChanged: (value) {
                              setState(() {
                                _isAgreed = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFFDE0D0D),
                            side: BorderSide(
                              color: Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'By proceeding to create a team, you hereby acknowledge and accept the role of Team Owner, with full responsibility for overseeing the team\'s participation and conduct within this application. You further agree to adhere strictly to all provisions outlined in Connecticut\'s Privacy Policy and Terms & Conditions.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kindly be advised that all team creation submissions are subject to a review and approval process, which may require between 2 to 3 business days.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (widget.onCancel != null) {
                                  widget.onCancel!();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey[400]!),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isFormValid() && !_isLoading
                                  ? _createTeamInFirebase
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDE0D0D),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Create'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Success popup similar to booking confirmation
  Widget _buildSuccessPopup(Map<String, dynamic> teamData) {
    return Stack(
      children: [
        // Semi-transparent background
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        
        // Popup content
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 320,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon (green checkmark in circle with border)
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Success message
                  const Text(
                    'Team Created Successfully',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15),
                  
                  // Additional message about admin approval
                  Text(
                    'Your team "${teamData['name']}" has been created! You are now the team admin. Start inviting members!',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Auto close after 3 seconds
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 3)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        // Close dialog and navigate back
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop(); // Close the dialog
                        });
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}