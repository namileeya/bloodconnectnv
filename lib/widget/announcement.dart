import 'package:flutter/material.dart';
import 'dart:async';

// Model class for Announcement
class Announcement {
  final String id;
  final String title;
  final String message;
  final String footer;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final int priority;
  final IconData? icon; // Added icon support
  
  Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.footer,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.priority = 0,
    this.icon,
  });
  
  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      footer: json['footer'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isActive: json['is_active'] ?? true,
      priority: json['priority'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'footer': footer,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'priority': priority,
    };
  }
}

// Service class for handling announcement data
class AnnouncementService {
  static final List<Announcement> _sampleAnnouncements = [
    Announcement(
      id: '1',
      title: 'Walk-in Donations Only',
      message: 'At our blood donation centers and clinics, only walk-in donations are allowed. Appointment requests are not available at this time. Please visit any of our locations during operating hours.',
      footer: 'We apologize for the inconvenience.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      priority: 1,
      icon: Icons.location_on_outlined,
    ),
    Announcement(
      id: '2',
      title: 'Donor Rewards Program',
      message: 'Earn points every time you donate blood! Redeem them for exclusive merchandise and gift cards. New rewards have been added including electronics, vouchers, and health checkup packages.',
      footer: 'Check your profile for current point balance.',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      priority: 2,
      icon: Icons.card_giftcard_outlined,
    ),
    Announcement(
      id: '3',
      title: 'New Blood Type Testing',
      message: 'Free comprehensive blood type analysis now available with every donation. This includes detailed blood group analysis, Rh factor determination, and antibody screening for better compatibility matching.',
      footer: 'Results delivered within 7 days.',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      priority: 3,
      icon: Icons.biotech_outlined,
    ),
    Announcement(
      id: '4',
      title: 'Mobile App Update',
      message: 'Latest version 2.5 brings improved donation tracking, health metrics dashboard, appointment scheduling, and enhanced user interface. Update now to access new features and improved performance.',
      footer: 'Update now to access all features.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      priority: 4,
      icon: Icons.system_update_outlined,
    ),
  ];
  
  static Future<List<Announcement>> getActiveAnnouncements() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _sampleAnnouncements
        .where((announcement) => announcement.isActive)
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
  
  static Stream<List<Announcement>> getAnnouncementsStream() {
    return Stream.periodic(const Duration(seconds: 30), (_) => _sampleAnnouncements)
        .asyncMap((_) => getActiveAnnouncements());
  }
}

// Main Announcement Widget
class AnnouncementWidget extends StatefulWidget {
  final double height;
  final Duration autoSlideInterval;
  final bool enableAutoSlide;
  final Function(Announcement)? onAnnouncementTap;
  
  const AnnouncementWidget({
    super.key,
    this.height = 220.0,
    this.autoSlideInterval = const Duration(seconds: 5),
    this.enableAutoSlide = true,
    this.onAnnouncementTap,
  });

  @override
  State<AnnouncementWidget> createState() => _AnnouncementWidgetState();
}

class _AnnouncementWidgetState extends State<AnnouncementWidget> {
  final PageController _pageController = PageController();
  Timer? _autoSlideTimer;
  int _currentIndex = 0;
  List<Announcement> _announcements = [];
  bool _isLoading = true;
  StreamSubscription<List<Announcement>>? _announcementSubscription;

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _setupPageControllerListener();
  }

  void _loadAnnouncements() async {
    try {
      final announcements = await AnnouncementService.getActiveAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = announcements;
          _isLoading = false;
        });
        
        if (widget.enableAutoSlide && _announcements.isNotEmpty) {
          _startAutoSlideTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      debugPrint('Error loading announcements: $e');
    }
  }

  void _setupPageControllerListener() {
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentIndex) {
        setState(() {
          _currentIndex = _pageController.page!.round();
        });
      }
    });
  }

  void _startAutoSlideTimer() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(widget.autoSlideInterval, (timer) {
      if (!mounted || _announcements.isEmpty) return;
      
      final nextIndex = (_currentIndex + 1) % _announcements.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoSlideTimer() {
    _autoSlideTimer?.cancel();
  }

  void _onIndicatorTap(int index) {
    _stopAutoSlideTimer();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    if (widget.enableAutoSlide) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _startAutoSlideTimer();
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _announcementSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with better styling
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  color: Color(0xFFDE0D0D),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Announcements',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_announcements.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDE0D0D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${_announcements.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDE0D0D),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _buildAnnouncementContent(),
          if (_announcements.length > 1) ...[
            const SizedBox(height: 12),
            _buildImprovedIndicators(),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildAnnouncementContent() {
    if (_isLoading) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFDE0D0D),
            strokeWidth: 3,
          ),
        ),
      );
    }

    if (_announcements.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 32,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No announcements available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Check back later for updates',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Removed arrows - full width for content
    return SizedBox(
      height: widget.height,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _announcements.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildImprovedAnnouncementCard(_announcements[index]);
        },
      ),
    );
  }

    Widget _buildImprovedAnnouncementCard(Announcement announcement) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // BloodConnect Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Image.asset(
                  'assets/bloodconnect logo 5.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 2),
                const Text(
                  'BloodConnect',
                  style: TextStyle(
                    color: Color(0xFFDE0D0D),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (announcement.icon != null) ...[
                  Icon(
                    announcement.icon,
                    color: const Color(0xFFDE0D0D),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    announcement.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Message + Read More Button
            LayoutBuilder(
              builder: (context, constraints) {
                final span = TextSpan(
                  text: announcement.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                );
                final tp = TextPainter(
                  text: span,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  maxLines: 4,
                );
                tp.layout(maxWidth: constraints.maxWidth);
                final isTextOverflowing = tp.didExceedMaxLines;

                return Column(
                  children: [
                    Text(
                      announcement.message,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (isTextOverflowing)
                      GestureDetector(
                        onTap: () => _showAnnouncementDetails(announcement),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE0D0D).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFDE0D0D).withOpacity(0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Read More',
                                style: TextStyle(
                                  color: Color(0xFFDE0D0D),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFFDE0D0D),
                                size: 12,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      announcement.footer,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.amber[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Method to show full announcement details in a dialog
  void _showAnnouncementDetails(Announcement announcement) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white, // Set white background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Colors.white, // Ensure white background
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDE0D0D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/bloodconnect logo 6.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      'BloodConnect',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              
              // Content - White background container
              Flexible(
                child: Container(
                  color: Colors.white, // Explicit white background for content area
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with icon
                        Row(
                          children: [
                            if (announcement.icon != null) ...[
                              Icon(
                                announcement.icon,
                                color: const Color(0xFFDE0D0D),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                announcement.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Full message
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            announcement.message,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Footer information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber[700],
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  announcement.footer,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.amber[800],
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Date information
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.blue[600],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Posted: ${_formatDate(announcement.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action button - White background container
              Container(
                color: Colors.white, // Explicit white background for button area
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE0D0D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  // Helper method to format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  Widget _buildImprovedIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < _announcements.length; i++)
            GestureDetector(
              onTap: () => _onIndicatorTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _currentIndex == i ? 24 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: _currentIndex == i
                      ? const Color(0xFFDE0D0D)
                      : Colors.grey.shade300,
                ),
              ),
            ),
        ],
      ),
    );
  }
}