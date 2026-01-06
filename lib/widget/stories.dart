// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StoriesWidget extends StatefulWidget {
  final String userId;
  const StoriesWidget({super.key, required this.userId});

  @override
  State<StoriesWidget> createState() => _StoriesWidgetState();
}

class _StoriesWidgetState extends State<StoriesWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _stories = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchStories();
  }

  Future<void> _fetchStories() async {
    try {
      // First, try to fetch with status filter
      QuerySnapshot snapshot = await _firestore
          .collection('stories')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      // If no results, try without status filter (in case status field doesn't exist or has different values)
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('stories')
            .orderBy('createdAt', descending: true)
            .get();
      }

      List<Map<String, dynamic>> stories = [];
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> storyData = doc.data() as Map<String, dynamic>;
        storyData['id'] = doc.id; // Add document ID
        
        // Ensure all required fields exist
        storyData['author'] = storyData['author'] ?? 'Anonymous';
        storyData['category'] = storyData['category'] ?? 'Story';
        storyData['title'] = storyData['title'] ?? 'Untitled Story';
        storyData['description'] = storyData['description'] ?? '';
        storyData['fullStory'] = storyData['fullStory'] ?? storyData['description'] ?? '';
        storyData['likes'] = storyData['likes'] ?? 0;
        storyData['comments'] = storyData['comments'] ?? 0;
        storyData['isAnonymous'] = storyData['isAnonymous'] ?? false;
        
        stories.add(storyData);
      }

      if (mounted) {
        setState(() {
          _stories = stories;
          _isLoading = false;
          _errorMessage = '';
        });
      }
      
    } catch (e) {
      print('Error fetching stories: $e');
      
      // Try one more time with simpler query (no ordering)
      try {
        QuerySnapshot snapshot = await _firestore
            .collection('stories')
            .get();
            
        List<Map<String, dynamic>> stories = [];
        
        for (var doc in snapshot.docs) {
          Map<String, dynamic> storyData = doc.data() as Map<String, dynamic>;
          storyData['id'] = doc.id;
          
          // Ensure all required fields exist
          storyData['author'] = storyData['author'] ?? 'Anonymous';
          storyData['category'] = storyData['category'] ?? 'Story';
          storyData['title'] = storyData['title'] ?? 'Untitled Story';
          storyData['description'] = storyData['description'] ?? '';
          storyData['fullStory'] = storyData['fullStory'] ?? storyData['description'] ?? '';
          storyData['likes'] = storyData['likes'] ?? 0;
          storyData['comments'] = storyData['comments'] ?? 0;
          storyData['isAnonymous'] = storyData['isAnonymous'] ?? false;
          
          stories.add(storyData);
        }
        
        // Sort by createdAt if available, otherwise by document ID
        stories.sort((a, b) {
          if (a['createdAt'] != null && b['createdAt'] != null) {
            try {
              Timestamp aTime = a['createdAt'] as Timestamp;
              Timestamp bTime = b['createdAt'] as Timestamp;
              return bTime.compareTo(aTime); // Descending
            } catch (e) {
              return 0;
            }
          }
          return 0;
        });

        if (mounted) {
          setState(() {
            _stories = stories;
            _isLoading = false;
            _errorMessage = '';
          });
        }
        
      } catch (e2) {
        print('Second attempt failed: $e2');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load stories. Please check your connection.';
          });
        }
      }
    }
  }

  void _showStoryDetail(Map<String, dynamic> story) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryDetailPage(story: story),
      ),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    return '$firstInitial$lastInitial';
  }

  // Format Firestore timestamp to readable date
  String _formatDate(Timestamp timestamp) {
    try {
      DateTime date = timestamp.toDate();
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  // Format timestamp for display in story card
  String _formatDateForCard(Timestamp? timestamp) {
    if (timestamp == null) return 'Recent';
    
    try {
      DateTime date = timestamp.toDate();
      DateTime now = DateTime.now();
      Duration difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d, yyyy').format(date);
      }
    } catch (e) {
      return 'Recent';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFDE0D0D),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchStories,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No stories yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Be the first to share your blood donation story!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFDE0D0D),
      onRefresh: _fetchStories,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _stories.length,
        itemBuilder: (context, index) {
          final story = _stories[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 0,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story image with category badge
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Stack(
                      children: [
                        // Image placeholder
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: const Color(0xFFDE0D0D).withOpacity(0.1),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bloodtype,
                                size: 60,
                                color: const Color(0xFFDE0D0D).withOpacity(0.3),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                story['category'] ?? 'Story',
                                style: TextStyle(
                                  color: const Color(0xFFDE0D0D).withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Category badge
                        if (story['category'] != null)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDE0D0D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                story['category'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        
                        // Story indicator overlay
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Read story button
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _showStoryDetail(story),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_stories,
                                    size: 16,
                                    color: Color(0xFFDE0D0D),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Read Story',
                                    style: TextStyle(
                                      color: Color(0xFFDE0D0D),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Anonymous badge
                        if (story['isAnonymous'] == true)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.visibility_off,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Anonymous',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
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
                ),
                
                // Story content
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] ?? 'Untitled Story',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['description'] ?? 'No description available',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      
                      // Author and date info
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFDE0D0D).withOpacity(0.1),
                            child: Text(
                              story['isAnonymous'] == true
                                  ? 'A'
                                  : _getUserInitials(story['author'] ?? 'Anonymous'),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDE0D0D),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  story['isAnonymous'] == true
                                      ? 'Anonymous Donor'
                                      : story['author'] ?? 'Anonymous',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  story['createdAt'] != null
                                      ? _formatDateForCard(story['createdAt'] as Timestamp?)
                                      : 'Recent',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Engagement stats
                          Row(
                            children: [
                              Icon(
                                Icons.favorite_border,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${story['likes'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.comment_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${story['comments'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Read More button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showStoryDetail(story),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFDE0D0D)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Read Full Story',
                            style: TextStyle(
                              color: Color(0xFFDE0D0D),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Story Detail Page (keep this part mostly the same, but add error handling)
class StoryDetailPage extends StatefulWidget {
  final Map<String, dynamic> story;

  const StoryDetailPage({super.key, required this.story});

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLiked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.story['likes'] ?? 0;
  }

  void _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    
    try {
      // Update like count in Firestore
      await _firestore
          .collection('stories')
          .doc(widget.story['id'])
          .update({
        'likes': _likeCount,
      });
    } catch (e) {
      print('Error updating like: $e');
      // Revert on error
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update like. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addComment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment functionality coming soon!')),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    return '$firstInitial$lastInitial';
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    try {
      DateTime date = timestamp.toDate();
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Story Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Story image
              Container(
                height: 250,
                width: double.infinity,
                color: const Color(0xFFDE0D0D).withOpacity(0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bloodtype,
                      size: 80,
                      color: const Color(0xFFDE0D0D).withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.story['category'] ?? 'Blood Donation',
                      style: TextStyle(
                        color: const Color(0xFFDE0D0D).withOpacity(0.5),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Story content
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFDE0D0D).withOpacity(0.1),
                          child: Text(
                            widget.story['isAnonymous'] == true
                                ? 'A'
                                : _getUserInitials(widget.story['author'] ?? 'Anonymous'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDE0D0D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.story['isAnonymous'] == true
                                    ? 'Anonymous Donor'
                                    : widget.story['author'] ?? 'Anonymous Donor',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                _formatDate(widget.story['createdAt'] as Timestamp?),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Story title
                    Text(
                      widget.story['title'] ?? 'Untitled Story',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category badge
                    if (widget.story['category'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE0D0D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.story['category'],
                          style: const TextStyle(
                            color: Color(0xFFDE0D0D),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Story content
                    Text(
                      widget.story['fullStory'] ?? widget.story['description'] ?? 'No story content available.',
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Anonymous note
                    if (widget.story['isAnonymous'] == true)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.visibility_off,
                              color: Colors.grey,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This story was shared anonymously to protect the donor\'s privacy.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    // Engagement section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: _toggleLike,
                                child: Row(
                                  children: [
                                    Icon(
                                      _isLiked ? Icons.favorite : Icons.favorite_border,
                                      color: _isLiked ? Colors.red : Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$_likeCount likes',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Row(
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: Colors.grey[600],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.story['comments'] ?? 0} comments',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _addComment,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDE0D0D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text(
                                'Add Comment',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}