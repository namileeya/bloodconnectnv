import 'package:bloodconnect/user_session.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:path/path.dart' as path;
import 'home_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';


class SnapAndSharePage extends StatefulWidget {
  const SnapAndSharePage({super.key});

  @override
  State<SnapAndSharePage> createState() => _SnapAndSharePageState();
}

class _SnapAndSharePageState extends State<SnapAndSharePage> with TickerProviderStateMixin {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  
  // Form state
  String _selectedCategory = 'First Time';
  bool _isLoading = false;
  bool _isAnonymous = false;
  
  // User data from session
  String? _userId;
  String? _currentUserName;
  
  // Available categories for stories
  final List<String> _categories = [
    'First Time',
    'Recipient Story',
    'Milestone',
    'Community Impact',
    'Medical Professional',
    'Family Story',
    'Recovery Journey',
    'Inspiration',
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await UserSession.getUser();
      
      if (userData == null) {
        throw Exception('No user data found');
      }
      
      setState(() {
        _userId = userData['user_id'];
        _currentUserName = userData['full_name'];
      });
      
      print('User data loaded: userId=$_userId, name=$_currentUserName'); // Debug log
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load user data. Please try logging in again.');
      }
    }
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _storyController.dispose();
    super.dispose();
  }
  
  String _getUserInitials() {
    if (_currentUserName == null || _currentUserName!.isEmpty) return 'U';
    
    List<String> nameParts = _currentUserName!.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    // Take first letter of first name and first letter of last name
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  void _updateNavIndex(int index) {
    // This method can be empty since we're not updating any state for this page
    // It's just required by the NavigationHelper
  }
  
  // Handle image selection from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _scaleController.reset();
        _scaleController.forward();
        _showImageSelectedSnackBar();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image from gallery');
    }
  }
  
  // Handle taking a new picture
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        _scaleController.reset();
        _scaleController.forward();
        _showImageSelectedSnackBar();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to take picture');
    }
  }
  
  // Show success message when image is selected
  void _showImageSelectedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Image selected successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFFDE0D0D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  // Validate form data
  bool _validateForm() {
    if (_selectedImage == null) {
      _showErrorSnackBar('Please select an image first');
      return false;
    }
    
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a title for your story');
      return false;
    }
    
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a description for your story');
      return false;
    }
    
    if (_storyController.text.trim().isEmpty) {
      _showErrorSnackBar('Please share your full story');
      return false;
    }
    
    return true;
  }

  // Clear form after successful submission
  void _clearForm() {
    setState(() {
      _selectedImage = null;
      _titleController.clear();
      _descriptionController.clear();
      _storyController.clear();
      _selectedCategory = 'First Time';
      _isAnonymous = false;
    });
  }

  // Show success popup dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 300,
            width: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
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
                
                // Success title
                const Text(
                  'Story Shared Successfully!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 15),
                
                // Success message
                Text(
                  'Your story has been shared and will appear in the community after review.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Auto close after 3 seconds and navigate to home
                FutureBuilder(
                  future: Future.delayed(const Duration(seconds: 3)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // Navigate to home page after delay
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                          (route) => false,
                        );
                      });
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Save image to local storage
  Future<String> _saveImageLocally(File imageFile) async {
    try {
      // Get the app's document directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      
      // Create a 'stories' subdirectory if it doesn't exist
      final Directory storiesDir = Directory('${appDir.path}/stories');
      if (!await storiesDir.exists()) {
        await storiesDir.create(recursive: true);
      }
      
      // Generate unique filename
      final String fileName = '${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${storiesDir.path}/$fileName';
      
      // Copy the image to the new location
      final File savedImage = await imageFile.copy(filePath);
      
      print('Image saved locally at: $filePath'); // Debug log
      return savedImage.path;
    } catch (e) {
      print('Error saving image locally: $e');
      throw Exception('Failed to save image');
    }
  }

  // Handle story submission
  Future<void> _submitStory() async {
    if (!_validateForm()) return;
    
    // Check if user data is loaded
    if (_userId == null || _currentUserName == null) {
      _showErrorSnackBar('User session not found. Please login again.');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 1. Save image locally
      print('Saving image locally...'); // Debug log
      final String localImagePath = await _saveImageLocally(_selectedImage!);
      print('Local image path: $localImagePath'); // Debug log
      
      // 2. Create story document in Firestore
      print('Creating Firestore document...'); // Debug log
      final Map<String, dynamic> storyData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fullStory': _storyController.text.trim(),
        'imagePath': localImagePath, // Store local path instead of URL
        'author': _isAnonymous ? 'Anonymous' : _currentUserName,
        'userId': _userId,
        'isAnonymous': _isAnonymous,
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'likes': 0,
        'comments': 0,
      };
      
      await FirebaseFirestore.instance
          .collection('stories')
          .add(storyData);
      
      print('Story saved successfully!'); // Debug log
      
      if (mounted) {
        // Clear the form
        _clearForm();
        
        // Show success dialog
        _showSuccessDialog();
      }
    } on FirebaseException catch (e) {
      print('Firebase Error Code: ${e.code}'); // Debug log
      print('Firebase Error Message: ${e.message}'); // Debug log
      
      if (mounted) {
        String errorMessage = 'Failed to share your story. Please try again.';
        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      print('General Error: $e'); // Debug log
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
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
                  const SizedBox(width: 12),
                  const Text(
                    'Snap And Share',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Snap and Share your experience in donating blood',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              
              // Image selection section
              if (_selectedImage == null) ...[
                Row(
                  children: [
                    // Upload from Gallery
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickImageFromGallery,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.photo_library,
                                  color: Color(0xFFDE0D0D),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Upload from Gallery',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Choose from your photos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Take Picture
                    Expanded(
                      child: GestureDetector(
                        onTap: _takePicture,
                        child: Container(
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDE0D0D).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xFFDE0D0D),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Take Picture',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Capture a new moment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Selected image preview with form
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Form fields
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title field
                              const Text(
                                'Story Title *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: 'Give your story a compelling title...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDE0D0D)),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLength: 100,
                              ),
                              const SizedBox(height: 20),
                              
                              // Category selection
                              const Text(
                                'Category *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _categories.map((String category) {
                                    return DropdownMenuItem<String>(
                                      value: category,
                                      child: Text(category),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Description field
                              const Text(
                                'Short Description *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _descriptionController,
                                decoration: InputDecoration(
                                  hintText: 'Write a brief summary of your story...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDE0D0D)),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 3,
                                maxLength: 200,
                              ),
                              const SizedBox(height: 20),
                              
                              // Full story field
                              const Text(
                                'Your Full Story *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _storyController,
                                decoration: InputDecoration(
                                  hintText: 'Share your complete blood donation experience, feelings, and message to others...',
                                  hintStyle: TextStyle(color: Colors.grey[500]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFDE0D0D)),
                                  ),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                maxLines: 8,
                                maxLength: 1000,
                              ),
                              const SizedBox(height: 20),
                              
                              // Anonymous option
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _isAnonymous,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isAnonymous = value ?? false;
                                        });
                                      },
                                      activeColor: const Color(0xFFDE0D0D),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Share anonymously',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Your story will be shared without your name',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              
                              // Submit button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _submitStory,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDE0D0D),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: _isLoading
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Sharing Your Story...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.share, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Share My Story',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Help text (only show when no image selected)
              if (_selectedImage == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE0D0D).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDE0D0D).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFFDE0D0D),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tips for a Great Story',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDE0D0D),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Share your genuine experience and emotions\n• Include what motivated you to donate\n• Mention any challenges you overcame\n• Add a message of encouragement for others\n• Keep it authentic and heartfelt',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Add padding at the bottom to avoid overlap with bottom navigation bar
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // Add bottom navigation bar
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: -1, // Set to -1 to keep all icons grey/unselected
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }
}