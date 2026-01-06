import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donate_now_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/blood_request_share.dart';
import '../user_session.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedTabIndex = 0;
  String fullName = "";
  String? userBloodType;
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Add these variables for caching and sorting
  List<DocumentSnapshot> _allNotifications = [];
  bool _isLoading = true;
  String _sortOrder = 'desc'; // 'desc' for newest first, 'asc' for oldest first
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAllNotifications();
  }
  
  void _loadUserData() async {
    try {
      // 1. Try to get cached session data first (FAST)
      Map<String, dynamic>? sessionUser = await UserSession.getUser();
      
      if (sessionUser != null) {
        if (mounted) {
          setState(() {
            // Support both keys just in case
            fullName = sessionUser['full_name'] ?? sessionUser['fullName'] ?? "User";
            userBloodType = sessionUser['blood_group'] ?? sessionUser['bloodType'];
          });
        }
      }

      // 2. Fetch fresh data from Firebase (BACKGROUND UPDATE)
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot donorDoc = await _firestore.collection('donor_profiles').doc(user.uid).get();
        if (donorDoc.exists) {
          if (mounted) {
            setState(() {
              fullName = donorDoc.get('full_name') ?? "";
              userBloodType = donorDoc.get('blood_group'); // Fixed key to match header
            });
            
            // Optional: Update session with fresh data
            Map<String, dynamic> freshData = {
               ...sessionUser ?? {},
               'full_name': fullName,
               'blood_group': userBloodType,
            };
            await UserSession.saveUser(freshData);
          }
        } else {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            if (mounted) {
              setState(() {
                fullName = userDoc.get('full_name') ?? userDoc.get('username') ?? "User";
                userBloodType = userDoc.get('blood_type');
              });
            }
          }
        }
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }
  
  Future<void> _loadAllNotifications() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;
      
      QuerySnapshot snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      if (mounted) {
        setState(() {
          _allNotifications = snapshot.docs;
          _sortNotifications(); // Sort after loading
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading notifications: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _sortNotifications() {
    _allNotifications.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      
      final Timestamp? timeA = dataA['created_at'] as Timestamp?;
      final Timestamp? timeB = dataB['created_at'] as Timestamp?;
      
      // Handle null timestamps
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1; // Put nulls at the end
      if (timeB == null) return -1; // Put nulls at the end
      
      if (_sortOrder == 'desc') {
        return timeB.compareTo(timeA); // Newest first
      } else {
        return timeA.compareTo(timeB); // Oldest first
      }
    });
  }
  
  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc';
      _sortNotifications();
    });
  }
  
  String _getUserInitials() {
    if (fullName.isEmpty) return 'U';
    List<String> nameParts = fullName.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    return '$firstInitial$lastInitial';
  }

  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Future<void> _markAllAsRead() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;
      
      QuerySnapshot unreadSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      final notificationsToMark = unreadSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final isRead = data['read'] ?? true;
        final type = data['type'] ?? '';
        return !isRead && type != 'blood_request';
      }).toList();
      
      WriteBatch batch = _firestore.batch();
      for (DocumentSnapshot doc in notificationsToMark) {
        batch.update(doc.reference, {'read': true});
      }
      
      await batch.commit();
      
      // Reload notifications to reflect changes
      await _loadAllNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      print("Error marking all as read: $e");
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
      
      // Update local cache
      final index = _allNotifications.indexWhere((doc) => doc.id == notificationId);
      if (index != -1) {
        final data = _allNotifications[index].data() as Map<String, dynamic>;
        data['read'] = true;
        setState(() {}); // Trigger UI update
      }
    } catch (e) {
      print("Error marking notification as read: $e");
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      // Remove from local cache
      setState(() {
        _allNotifications.removeWhere((doc) => doc.id == notificationId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error deleting notification: $e");
    }
  }

  String _formatDateTime(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${date.day} ${_getMonthName(date.month)} ${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  String _getStatusForNotification(Map<String, dynamic>? data) {
    if (data == null) return '';
    
    // Check for direct status (for donation notifications)
    final directStatus = data['status'] ?? '';
    if (directStatus.isNotEmpty) return directStatus;
    
    // Check for nested status in donationData
    final donationData = data['donationData'] as Map<String, dynamic>?;
    if (donationData != null) {
      return donationData['status'] ?? '';
    }
    
    // Check for event registration status
    final registrationData = data['registrationData'] as Map<String, dynamic>?;
    if (registrationData != null) {
      return registrationData['status'] ?? '';
    }
    
    // Check for community status updates
    final newStatus = data['newStatus'] ?? '';
    final oldStatus = data['oldStatus'] ?? '';
    if (newStatus.isNotEmpty || oldStatus.isNotEmpty) {
      return newStatus; // Return the new status for community updates
    }
    
    return '';
  }

  Widget _getNotificationIcon(String type, Map<String, dynamic>? data) {
    final status = _getStatusForNotification(data);
    
    // Handle donation status notifications
    if (type == 'donation_status_update' && status.isNotEmpty) {
      switch (status) {
        case 'registered':
          return _buildIconContainer(const Color(0xFFFF9800), Icons.calendar_today);
        case 'approved':
          return _buildIconContainer(const Color(0xFF4CAF50), Icons.check_circle);
        case 'confirmed':
          return _buildIconContainer(const Color(0xFF4CAF50), Icons.check_circle);
        case 'checked_in':
          return _buildIconContainer(const Color(0xFF2196F3), Icons.pin_drop);
        case 'completed':
          return _buildIconContainer(const Color(0xFF4CAF50), Icons.verified);
        case 'used':
          return _buildIconContainer(const Color(0xFF4CAF50), Icons.favorite);
        case 'rejected':
          return _buildIconContainer(const Color(0xFFF44336), Icons.cancel);
        case 'cancelled':
          return _buildIconContainer(const Color(0xFF757575), Icons.block);
        case 'no-show':
          return _buildIconContainer(const Color(0xFFFFC107), Icons.person_off);
        default:
          return _buildIconContainer(Colors.grey, Icons.notifications);
      }
    }
    
    if (type == 'eligibility_update' && data != null) {
      final status = data['status'] ?? '';
      if (status.contains('Eligible')) {
        return _buildIconContainer(const Color(0xFF4CAF50), Icons.verified);
      } else if (status.contains('Deferred')) {
        return _buildIconContainer(const Color(0xFFFF9800), Icons.schedule);
      } else if (status.contains('Ineligible')) {
        return _buildIconContainer(const Color(0xFFF44336), Icons.block);
      }
    }
    
    // Handle community status update notifications from web
    if (type == 'GROUP_STATUS_UPDATE' || 
        type == 'CONTENT_STATUS_UPDATE' || 
        type == 'BANNER_STATUS_UPDATE') {
      return _buildIconContainer(const Color(0xFF2196F3), Icons.group);
    }
    
    // Also handle if type starts with community_ (backward compatibility)
    if (type.startsWith('community_')) {
      return _buildIconContainer(const Color(0xFF2196F3), Icons.group);
    }
    
    switch (type) {
      case 'donation_status_update':
        return _buildIconContainer(const Color(0xFF2196F3), Icons.bloodtype);
      case 'eligibility_update':
        return _buildIconContainer(const Color(0xFF2196F3), Icons.medical_services);
      case 'donation':
        return _buildIconContainer(const Color(0xFFDE0D0D), Icons.bloodtype);
      case 'appointment':
        return _buildIconContainer(const Color(0xFF9C27B0), Icons.calendar_today);
      case 'blood_request':
        return _buildIconContainer(const Color(0xFFDE0D0D), Icons.bloodtype);
      default:
        return _buildIconContainer(Colors.grey, Icons.notifications);
    }
  }

  Widget _buildIconContainer(Color color, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Color _getNotificationColor(String type, Map<String, dynamic>? data) {
    final status = _getStatusForNotification(data);
    
    // Handle donation status notifications
    if (type == 'donation_status_update' && status.isNotEmpty) {
      switch (status) {
        case 'registered':
          return const Color(0xFFFF9800);
        case 'approved':
          return const Color(0xFF4CAF50);
        case 'confirmed':
          return const Color(0xFF4CAF50);
        case 'checked_in':
          return const Color(0xFF2196F3);
        case 'completed':
          return const Color(0xFF4CAF50);
        case 'used':
          return const Color(0xFF4CAF50);
        case 'rejected':
          return const Color(0xFFF44336);
        case 'cancelled':
          return const Color(0xFF757575);
        case 'no-show':
          return const Color(0xFFFFC107);
        default:
          return Colors.grey;
      }
    }
    
    if (type == 'eligibility_update' && data != null) {
      final status = data['status'] ?? '';
      if (status.contains('Eligible')) return const Color(0xFF4CAF50);
      if (status.contains('Deferred')) return const Color(0xFFFF9800);
      if (status.contains('Ineligible')) return const Color(0xFFF44336);
    }
    
    // Handle community status update notifications from web
    if (type == 'GROUP_STATUS_UPDATE' || 
        type == 'CONTENT_STATUS_UPDATE' || 
        type == 'BANNER_STATUS_UPDATE') {
      return const Color(0xFF2196F3);
    }
    
    // Also handle if type starts with community_ (backward compatibility)
    if (type.startsWith('community_')) {
      return const Color(0xFF2196F3);
    }
    
    switch (type) {
      case 'donation_status_update': return const Color(0xFF2196F3);
      case 'eligibility_update': return const Color(0xFF2196F3);
      case 'donation': return const Color(0xFFDE0D0D);
      case 'appointment': return const Color(0xFF9C27B0);
      case 'blood_request': return const Color(0xFFDE0D0D);
      default: return Colors.grey;
    }
  }

  String _getStatusBadgeText(String type, Map<String, dynamic>? data) {
    final status = _getStatusForNotification(data);
    
    if (type == 'donation_status_update' && status.isNotEmpty) {
      switch (status) {
        case 'registered':
          return 'REGISTERED';
        case 'approved':
          return 'APPROVED';
        case 'confirmed':
          return 'CONFIRMED';
        case 'checked_in':
          return 'CHECKED-IN';
        case 'completed':
          return 'COMPLETED';
        case 'used':
          return 'USED';
        case 'rejected':
          return 'REJECTED';
        case 'cancelled':
          return 'CANCELLED';
        case 'no-show':
          return 'NO-SHOW';
        default:
          return status.toUpperCase();
      }
    }
    
    if (type == 'eligibility_update' && data != null) {
      final status = data['status'] ?? '';
      if (status.contains('Eligible')) return 'ELIGIBLE';
      if (status.contains('Deferred')) return 'DEFERRED';
      if (status.contains('Ineligible')) return 'INELIGIBLE';
    }
    
    // Handle community status update notifications from web
    if ((type == 'GROUP_STATUS_UPDATE' || 
         type == 'CONTENT_STATUS_UPDATE' || 
         type == 'BANNER_STATUS_UPDATE') && data != null) {
      final newStatus = data['newStatus'] ?? '';
      if (newStatus.isNotEmpty) {
        // Map Firebase status to readable format
        switch (newStatus.toLowerCase()) {
          case 'active':
          case 'approved':
          case 'published':
            return 'PUBLISHED';
          case 'inactive':
          case 'pending':
          case 'in review':
            return 'IN REVIEW';
          case 'disbanded':
          case 'rejected':
            return 'REJECTED';
          default:
            return newStatus.toUpperCase();
        }
      }
    }
    
    // Also handle if type starts with community_ (backward compatibility)
    if (type.startsWith('community_') && data != null) {
      final newStatus = data['newStatus'] ?? '';
      if (newStatus.isNotEmpty) return newStatus.toUpperCase();
    }
    
    return '';
  }

  // Helper methods to filter notifications
  List<DocumentSnapshot> _getUnreadNotifications() {
    return _allNotifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isRead = data['read'] ?? true;
      final type = data['type'] ?? '';
      return !isRead && type != 'blood_request';
    }).toList();
  }

  List<DocumentSnapshot> _getReadNotifications() {
    return _allNotifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final isRead = data['read'] ?? false;
      final type = data['type'] ?? '';
      return isRead && type != 'blood_request';
    }).toList();
  }

  List<DocumentSnapshot> _getBloodRequestNotifications() {
    return _allNotifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] ?? '';
      final title = data['title'] ?? '';
      
      return type == 'blood_request' || 
             title.toLowerCase().contains('blood') ||
             title.toLowerCase().contains('request') ||
             title.toLowerCase().contains('urgent');
    }).toList();
  }

  Widget _buildUnreadNotifications() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
    }
    
    final unreadNotifications = _getUnreadNotifications();
    
    if (unreadNotifications.isEmpty) {
      return _buildEmptyState('No Unread Notifications', 'You have no unread notifications');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: unreadNotifications.length,
      itemBuilder: (context, index) {
        final doc = unreadNotifications[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildNotificationCard(context, doc.id, data, false);
      },
    );
  }

  Widget _buildReadNotifications() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
    }
    
    final readNotifications = _getReadNotifications();
    
    if (readNotifications.isEmpty) {
      return _buildEmptyState('No Read Notifications', 'You have no read notifications');
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: readNotifications.length,
      itemBuilder: (context, index) {
        final doc = readNotifications[index];
        final data = doc.data() as Map<String, dynamic>;
        return _buildNotificationCard(context, doc.id, data, true);
      },
    );
  }

  Widget _buildBloodRequestTab() {
    User? user = _auth.currentUser;
    if (user == null) return const Center(child: Text('Please login'));

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)));
    }
    
    final bloodRequestNotifications = _getBloodRequestNotifications();
    
    if (bloodRequestNotifications.isEmpty) {
      return _buildEmptyState(
        'No Blood Requests',
        'There are no blood request notifications at this time.',
      );
    }
    
    // Separate unread and read
    final unreadRequests = bloodRequestNotifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['read'] ?? true) == false;
    }).toList();
    
    final readRequests = bloodRequestNotifications.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['read'] ?? false) == true;
    }).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (unreadRequests.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'New Blood Requests (${unreadRequests.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDE0D0D),
              ),
            ),
          ),
          ...unreadRequests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final notificationData = data['data'] as Map<String, dynamic>?;
            return _buildBloodRequestCard(
              context,
              doc.id,
              data,
              notificationData,
              false,
            );
          }).toList(),
        ],
        
        if (readRequests.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              top: unreadRequests.isNotEmpty ? 16 : 0,
              bottom: 8,
            ),
            child: Text(
              'Previous Blood Requests (${readRequests.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ...readRequests.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final notificationData = data['data'] as Map<String, dynamic>?;
            return _buildBloodRequestCard(
              context,
              doc.id,
              data,
              notificationData,
              true,
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(BuildContext context, String id, Map<String, dynamic> data, bool isRead) {
    final Timestamp? timestamp = data['created_at'] as Timestamp?;
    final String date = timestamp != null ? _formatDateTime(timestamp) : 'Unknown date';
    final String title = data['title'] ?? 'Notification';
    final String message = data['message'] ?? '';
    final String type = data['type'] ?? 'general';
    final Map<String, dynamic>? notificationData = data['data'] as Map<String, dynamic>?;
    final Color color = _getNotificationColor(type, notificationData);
    final String statusBadgeText = _getStatusBadgeText(type, notificationData);
    
    // If this is a blood request, show it in blood request style
    if (type == 'blood_request') {
      return _buildBloodRequestCard(
        context,
        id,
        data,
        notificationData,
        isRead,
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : color.withOpacity(0.3),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _getNotificationIcon(type, notificationData),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (statusBadgeText.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusBadgeText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              if (!isRead) ...[
                                if (statusBadgeText.isNotEmpty) const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDE0D0D).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDE0D0D),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'mark_read' && !isRead) {
                      _markAsRead(id);
                    } else if (value == 'delete') {
                      _deleteNotification(id);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      if (!isRead)
                        const PopupMenuItem<String>(
                          value: 'mark_read',
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text('Mark as read'),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            
            // Show donation details if available
            if (type == 'donation_status_update' && notificationData != null) ...[
              const SizedBox(height: 12),
              _buildDonationDetails(notificationData, color),
            ],
            
            // Show eligibility details if available
            if (type == 'eligibility_update' && notificationData != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton(
                  onPressed: () {
                    _showEligibilityDetails(context, notificationData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Eligibility Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            
            // Show community status change details if available
            if ((type == 'GROUP_STATUS_UPDATE' || 
                 type == 'CONTENT_STATUS_UPDATE' || 
                 type == 'BANNER_STATUS_UPDATE') && 
                notificationData != null) ...[
              const SizedBox(height: 12),
              _buildCommunityStatusDetails(notificationData, color, type),
            ],
          ],
        ),
      )
    );
  }

  Widget _buildCommunityStatusDetails(Map<String, dynamic> data, Color color, String type) {
    final oldStatus = data['oldStatus'] ?? '';
    final newStatus = data['newStatus'] ?? '';
    final itemName = data['itemName'] ?? '';
    final itemType = data['itemType'] ?? '';
    final timestamp = data['timestamp'] ?? '';
    
    // Map status to readable format
    String mapStatus(String status) {
      switch (status.toLowerCase()) {
        case 'active':
        case 'approved':
        case 'published':
          return 'Published';
        case 'inactive':
        case 'pending':
        case 'in review':
          return 'In Review';
        case 'disbanded':
        case 'rejected':
          return 'Rejected';
        default:
          return status;
      }
    }
    
    String getItemTypeText(String type) {
      switch (type) {
        case 'GROUP_STATUS_UPDATE':
          return 'Group';
        case 'CONTENT_STATUS_UPDATE':
          return 'Story';
        case 'BANNER_STATUS_UPDATE':
          return 'Banner';
        default:
          return itemType;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${getItemTypeText(type)}: $itemName',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  'Status Change:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          mapStatus(oldStatus),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          mapStatus(newStatus),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    if (timestamp.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Updated: $timestamp',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDonationDetails(Map<String, dynamic> data, Color color) {
    final recordId = data['recordId'] ?? '';
    final eventTitle = data['eventTitle'] ?? '';
    final eventLocation = data['eventLocation'] ?? '';
    final timeSlot = data['timeSlot'] ?? '';
    final serialNumber = data['serialNumber'] ?? '';
    final amountDonated = data['amountDonated'] ?? '';
    final bloodType = data['bloodType'] ?? '';
    final reason = data['reason'] ?? '';
    final hospitalName = data['hospitalName'] ?? '';
    final usedDate = data['usedDate'] ?? '';
    final registrationId = data['registrationId'] ?? '';
    
    // Get donation data if nested
    final donationData = data['donationData'] as Map<String, dynamic>?;
    final registrationData = data['registrationData'] as Map<String, dynamic>?;
    
    final effectiveRecordId = recordId.isNotEmpty ? recordId : (donationData?['id'] ?? '');
    final effectiveEventTitle = eventTitle.isNotEmpty ? eventTitle : (registrationData?['eventTitle'] ?? '');
    final effectiveEventLocation = eventLocation.isNotEmpty ? eventLocation : (registrationData?['location'] ?? '');
    final effectiveTimeSlot = timeSlot.isNotEmpty ? timeSlot : (registrationData?['timeSlot'] ?? '');
    final effectiveSerialNumber = serialNumber.isNotEmpty ? serialNumber : (donationData?['serialNumber'] ?? '');
    final effectiveAmountDonated = amountDonated.isNotEmpty ? amountDonated : (donationData?['amountDonated'] ?? '');
    final effectiveBloodType = bloodType.isNotEmpty ? bloodType : (donationData?['bloodType'] ?? '');
    final effectiveReason = reason.isNotEmpty ? reason : (data['reason'] ?? '');
    final effectiveHospitalName = hospitalName.isNotEmpty ? hospitalName : (donationData?['hospitalName'] ?? '');
    final effectiveUsedDate = usedDate.isNotEmpty ? usedDate : (donationData?['usedDate'] ?? '');
    final effectiveRegistrationId = registrationId.isNotEmpty ? registrationId : (registrationData?['id'] ?? '');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (effectiveRecordId.isNotEmpty) ...[
            _buildDonationDetailRow('Record ID:', effectiveRecordId, color),
            const SizedBox(height: 8),
          ],
          if (effectiveRegistrationId.isNotEmpty) ...[
            _buildDonationDetailRow('Registration ID:', effectiveRegistrationId, color),
            const SizedBox(height: 8),
          ],
          if (effectiveEventTitle.isNotEmpty) ...[
            _buildDonationDetailRow('Event:', effectiveEventTitle, color),
            const SizedBox(height: 8),
          ],
          if (effectiveHospitalName.isNotEmpty) ...[
            _buildDonationDetailRow('Hospital:', effectiveHospitalName, color),
            const SizedBox(height: 8),
          ],
          if (effectiveEventLocation.isNotEmpty) ...[
            _buildDonationDetailRow('Location:', effectiveEventLocation, color),
            const SizedBox(height: 8),
          ],
          if (effectiveTimeSlot.isNotEmpty) ...[
            _buildDonationDetailRow('Time Slot:', effectiveTimeSlot, color),
            const SizedBox(height: 8),
          ],
          if (effectiveSerialNumber.isNotEmpty) ...[
            _buildDonationDetailRow('Serial No:', effectiveSerialNumber, color),
            const SizedBox(height: 8),
          ],
          if (effectiveAmountDonated.isNotEmpty) ...[
            _buildDonationDetailRow('Amount:', '$effectiveAmountDonated ml', color),
            const SizedBox(height: 8),
          ],
          if (effectiveBloodType.isNotEmpty && effectiveBloodType != 'Unknown') ...[
            _buildDonationDetailRow('Blood Type:', effectiveBloodType, color),
            const SizedBox(height: 8),
          ],
          if (effectiveUsedDate.isNotEmpty) ...[
            _buildDonationDetailRow('Used Date:', effectiveUsedDate, color),
            const SizedBox(height: 8),
          ],
          if (effectiveReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: $effectiveReason',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDonationDetailRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBloodRequestCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    Map<String, dynamic>? notificationData,
    bool isRead,
  ) {
    final Timestamp? timestamp = data['created_at'] as Timestamp?;
    final String date = timestamp != null ? _formatDateTime(timestamp) : 'Unknown date';
    final String title = data['title'] ?? 'Blood Request';
    final String message = data['message'] ?? '';
    
    final bloodType = notificationData?['bloodType'] ?? 'Unknown';
    final location = notificationData?['location'] ?? 'Unknown location';
    final patientName = notificationData?['patientName'] ?? 'A patient';
    final urgency = notificationData?['urgency'] ?? 'Normal';
    final hospital = notificationData?['hospital'] ?? 'Local hospital';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDE0D0D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bloodtype,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Color(0xFFDE0D0D),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Date
            Text(
              date,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Message
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Blood Request Details
            if (notificationData != null) ...[
              _buildRequestInfoRow('Blood Type:', bloodType, Color(0xFFDE0D0D)),
              const SizedBox(height: 8),
              _buildRequestInfoRow('Hospital:', hospital, Color(0xFFDE0D0D)),
              const SizedBox(height: 8),
              _buildRequestInfoRow('Patient Name:', patientName, Color(0xFFDE0D0D)),
              const SizedBox(height: 8),
              _buildRequestInfoRow('Location:', location, Color(0xFFDE0D0D)),
              const SizedBox(height: 8),
              _buildRequestInfoRow('Urgency:', urgency, Color(0xFFDE0D0D)),
              const SizedBox(height: 16),
            ],
            
            // Buttons: Donate Now and Share
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DonateNowPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFDE0D0D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Donate Now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Prepare blood request data for sharing
                      Map<String, dynamic> shareData = {
                        'bloodType': bloodType,
                        'hospital': hospital,
                        'patientName': patientName,
                        'location': location,
                        'urgency': urgency,
                        'message': message,
                        'date': date,
                      };
                      
                      // Show share sheet
                      BloodRequestShareHelper.showBloodRequestShareSheet(context, shareData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFDE0D0D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Share',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Action buttons for read/delete (optional)
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton(
                    onPressed: () => _markAsRead(id),
                    child: const Text(
                      'Mark as Read',
                      style: TextStyle(color: Color(0xFFDE0D0D)),
                    ),
                  ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _deleteNotification(id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestInfoRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 2 ? Icons.bloodtype_outlined : Icons.notifications_off,
              size: 70,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifications = _getUnreadNotifications();
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomHeader(
        appName: 'BloodConnect',
        userInitials: _getUserInitials(),
        fullName: fullName,
        currentPage: 'notifications',
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sort button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _toggleSortOrder,
                  icon: Icon(
                    _sortOrder == 'desc' ? Icons.arrow_downward : Icons.arrow_upward,
                    color: const Color(0xFFDE0D0D),
                  ),
                  tooltip: _sortOrder == 'desc' ? 'Newest First' : 'Oldest First',
                ),
              ],
            ),
          ),
          
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton('Unread\nNotifications', 0),
                  _buildTabButton('Read\nNotifications', 1),
                  _buildTabButton('Blood\nRequest', 2),
                ],
              ),
            ),
          ),
          
          // Mark all as read button (only for unread tab)
          if (_selectedTabIndex == 0 && unreadNotifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _markAllAsRead,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(double.infinity, 45),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Mark all as read',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFDE0D0D)))
                : _selectedTabIndex == 0
                    ? _buildUnreadNotifications()
                    : _selectedTabIndex == 1
                        ? _buildReadNotifications()
                        : _buildBloodRequestTab(),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 6),
                Container(
                  width: 30,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE0D0D),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomNavigationBar(
      currentIndex: 0, // Default to Home
      onTap: (index) => NavigationHelper.handleNavigation(context, index, (i) {}),
    );
  }

  Color _getStatusColor(String status) {
    if (status.contains('Eligible')) {
      return const Color(0xFF4CAF50);
    } else if (status.contains('Deferred')) {
      return const Color(0xFFFF9800);
    } else if (status.contains('Ineligible')) {
      return const Color(0xFFF44336);
    }
    return const Color(0xFF2196F3);
  }

  IconData _getStatusIcon(String status) {
    if (status.contains('Eligible')) {
      return Icons.check_circle;
    } else if (status.contains('Deferred')) {
      return Icons.schedule;
    } else if (status.contains('Ineligible')) {
      return Icons.block;
    }
    return Icons.medical_services;
  }

  void _showEligibilityDetails(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Unknown';
    final notes = data['notes'] ?? '';
    final eligibilityId = data['eligibilityId'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Eligibility Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(status),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${eligibilityId.substring(0, 8)}...',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Admin Notes:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  notes,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}