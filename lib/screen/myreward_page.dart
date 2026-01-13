import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'notification_page.dart';
import '../widget/redeem_voucher.dart';
import '../widget/points_history.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../user_session.dart';

class MyRewardPage extends StatefulWidget {
  const MyRewardPage({super.key});

  @override
  State<MyRewardPage> createState() => _MyRewardPageState();
}

class _MyRewardPageState extends State<MyRewardPage> with TickerProviderStateMixin {
  int _selectedTabIndex = 0;
  late TabController _tabController;
  
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // User data
  Map<String, dynamic> _userData = {
    'name': 'Loading...',
    'bloodGroup': 'Loading...',
    'totalPoints': 0,
    'lifetimeDonations': 0,
    'lastDonationDate': 'Never',
  };

  // Loading states
  bool _isLoadingRewards = false;
  bool _isLoadingUserData = true;

  // Data lists
  List<Map<String, dynamic>> _redeemableRewards = [];
  List<Map<String, dynamic>> _redeemedVouchers = [];
  List<Map<String, dynamic>> _pointsHistory = [];
  List<Map<String, dynamic>> _availableVouchers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Changed to 3 tabs
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    if (_currentUserId == null) {
      print('❌ ERROR: No user logged in');
      return;
    }

    try {
      setState(() {
        _isLoadingUserData = true;
      });

      print('🔄 Loading data for user: $_currentUserId');

      // 0. Try to get cached session data first (FAST)
      Map<String, dynamic>? sessionUser = await UserSession.getUser();
      if (sessionUser != null && mounted) {
           String cachedName = sessionUser['full_name'] ?? sessionUser['fullName'] ?? 'User';
           setState(() {
             _userData['name'] = cachedName;
           });
      }

      // 1. Load donor profile
      final donorProfileDoc = await _firestore
          .collection('donor_profiles')
          .where('user_id', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      if (donorProfileDoc.docs.isNotEmpty) {
        final donorData = donorProfileDoc.docs.first.data() as Map<String, dynamic>;
        
        print('✅ Found donor profile');
        print('   full_name: ${donorData['full_name']}');
        print('   blood_group: ${donorData['blood_group']}');
        print('   rhesus: ${donorData['rhesus']}');
        
        // FIX Blood Group Formatting
        String bloodGroup = donorData['blood_group']?.toString().trim() ?? 'Unknown';
        String rhesus = donorData['rhesus']?.toString().trim() ?? '';
        
        // Check if blood_group already contains + or -
        String finalBloodGroup = bloodGroup;
        
        // Remove any existing ++ or --
        finalBloodGroup = finalBloodGroup.replaceAll('++', '+').replaceAll('--', '-');
        
        if (!finalBloodGroup.contains('+') && !finalBloodGroup.contains('-')) {
          // Add + or - based on rhesus
          if (rhesus.toLowerCase().contains('positive')) {
            finalBloodGroup = '$bloodGroup+';
          } else if (rhesus.toLowerCase().contains('negative')) {
            finalBloodGroup = '$bloodGroup-';
          }
        }
        
        print('   Final blood group: $finalBloodGroup');
        
        _userData['name'] = donorData['full_name'] ?? 'User';
        _userData['bloodGroup'] = finalBloodGroup;
      } else {
        print('❌ No donor profile found for user $_currentUserId');
        _userData['name'] = 'User';
        _userData['bloodGroup'] = 'Unknown';
      }

      // 2. Load donations to calculate points
      final donationsSnapshot = await _firestore
          .collection('donations')
          .where('donor_id', isEqualTo: _currentUserId)
          .orderBy('donation_date', descending: true)
          .get();

      final totalDonations = donationsSnapshot.docs.length;
      
      // 3. Load claimed rewards to calculate used points
      final claimedRewardsSnapshot = await _firestore
          .collection('rewards_claimed')
          .where('userId', isEqualTo: _currentUserId)
          .get();
      
      int totalUsedPoints = 0;
      for (var doc in claimedRewardsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        totalUsedPoints += (data['pointUsed'] as int? ?? 0);
      }
      
      // Calculate available points: (donations * 10) - points used
      final earnedPoints = totalDonations * 10;
      final availablePoints = earnedPoints - totalUsedPoints;
      
      final lastDonation = totalDonations > 0 
          ? (donationsSnapshot.docs.first.data()['donation_date'] as Timestamp).toDate()
          : null;

      _userData['totalPoints'] = availablePoints > 0 ? availablePoints : 0;
      _userData['lifetimeDonations'] = totalDonations;
      _userData['lastDonationDate'] = lastDonation != null
          ? DateFormat('yyyy-MM-dd').format(lastDonation)
          : 'Never';

      print('✅ Donations: $totalDonations, Earned Points: $earnedPoints');
      print('✅ Used Points: $totalUsedPoints, Available Points: ${_userData['totalPoints']}');

      // 4. DEBUG: Test rewards collection first
      await _debugCheckRewardsCollection();

      // 5. Load available rewards (for My Rewards tab)
      await _loadAvailableRewards();

      // 6. Load available vouchers (for Redeem Voucher tab) - NOW WITH POINTS FILTER
      await _loadAvailableVouchers();

      // 7. Load claimed rewards (kept for points history)
      await _loadClaimedRewards();

      // 8. Generate points history
      await _generatePointsHistory(donationsSnapshot.docs, claimedRewardsSnapshot.docs);

    } catch (e) {
      print('❌ Error loading user data: $e');
      _showErrorSnackBar('Failed to load data: $e');
    } finally {
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  // DEBUG: Check what's actually in rewards collection
  Future<void> _debugCheckRewardsCollection() async {
    try {
      print('🔍 DEBUG: Checking rewards collection structure...');
      
      // Get ALL documents from rewards collection
      final allRewards = await _firestore.collection('rewards').get();
      
      print('📊 Total documents in "rewards" collection: ${allRewards.docs.length}');
      
      if (allRewards.docs.isEmpty) {
        print('⚠️ WARNING: rewards collection is EMPTY!');
        return;
      }
      
      // Print all documents to see structure
      for (int i = 0; i < allRewards.docs.length; i++) {
        final doc = allRewards.docs[i];
        final data = doc.data() as Map<String, dynamic>;
        
        print('\n═══════════════════════════════════════════════════');
        print('📋 Document ${i + 1}: ${doc.id} - ${data['name']}');
        print('═══════════════════════════════════════════════════');
        
        // Print important fields
        print('   name: ${data['name']}');
        print('   isActive: ${data['isActive']}');
        print('   type: ${data['type']}');
        print('   pointsRequired: ${data['pointsRequired']}');
        print('   maxClaimsPerUser: ${data['maxClaimsPerUser']}');
        
        if (data.containsKey('expiryDate') && data['expiryDate'] != null) {
          try {
            final expiry = (data['expiryDate'] as Timestamp).toDate();
            final now = DateTime.now();
            print('   expiryDate: $expiry');
            print('   Is expired? ${expiry.isBefore(now)}');
          } catch (e) {
            print('   ❌ Error parsing expiryDate: $e');
          }
        }
        
        print('═══════════════════════════════════════════════════\n');
      }
      
    } catch (e) {
      print('❌ Error in debugCheckRewardsCollection: $e');
    }
  }

  // Load available rewards from Firebase
  Future<void> _loadAvailableRewards() async {
    try {
      print('🔄 Loading available rewards...');
      
      final now = DateTime.now();
      print('   Current time: $now');
      
      // Get all active, non-expired rewards
      final rewardsSnapshot = await _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .get();

      print('   Found ${rewardsSnapshot.docs.length} active rewards');
      
      _redeemableRewards = [];
      
      for (var doc in rewardsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if reward is expired
        bool isExpired = false;
        DateTime? expiryDate;
        
        if (data['expiryDate'] != null) {
          try {
            expiryDate = (data['expiryDate'] as Timestamp).toDate();
            isExpired = expiryDate.isBefore(now);
          } catch (e) {
            print('   ❌ Error parsing expiryDate for ${data['name']}: $e');
            expiryDate = DateTime.now().add(const Duration(days: 30));
          }
        } else {
          expiryDate = DateTime.now().add(const Duration(days: 30));
        }
        
        // Only show non-expired rewards
        if (!isExpired) {
          _redeemableRewards.add({
            'id': doc.id,
            'name': data['name'] ?? 'Unnamed Reward',
            'points': data['pointsRequired'] ?? 0,
            'type': data['type'] ?? 'voucher',
            'category': data['category'] ?? 'General',
            'description': data['description'] ?? '',
            'expiryDate': expiryDate!,
            'available': true,
            'stock': data['maxClaimsPerUser'] ?? 1,
            'discountValue': data['discountValue'] ?? 0,
            'icon': _getIconForReward(data),
          });
          print('   ✅ Added to available rewards: ${data['name']}');
        } else {
          print('   ❌ Skipping expired reward: ${data['name']}');
        }
      }

      print('✅ Available rewards: ${_redeemableRewards.length} items');

    } catch (e) {
      print('❌ Error loading rewards: $e');
      _redeemableRewards = [];
    }
  }

  // Load available vouchers specifically for Redeem tab - UPDATED WITH POINTS FILTER
  Future<void> _loadAvailableVouchers() async {
    if (_currentUserId == null) return;

    try {
      print('🔄 Loading available vouchers...');
      
      final now = DateTime.now();
      
      // Get all active rewards of type voucher
      final vouchersSnapshot = await _firestore
          .collection('rewards')
          .where('isActive', isEqualTo: true)
          .get();
      
      print('   Found ${vouchersSnapshot.docs.length} active rewards');
      
      _availableVouchers = [];
      
      for (var doc in vouchersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if it's a voucher type
        final type = data['type']?.toString().toLowerCase() ?? 'voucher';
        if (type != 'voucher') {
          print('   Skipping non-voucher: ${data['name']} (type: $type)');
          continue;
        }
        
        print('   Processing voucher: ${data['name']} (ID: ${doc.id})');
        
        // Check expiry date
        bool isExpired = false;
        DateTime expiryDate;
        
        if (data['expiryDate'] != null) {
          try {
            expiryDate = (data['expiryDate'] as Timestamp).toDate();
            isExpired = expiryDate.isBefore(now);
            if (isExpired) {
              print('      ❌ Voucher expired: $expiryDate');
              continue;
            }
          } catch (e) {
            print('      ❌ Error parsing expiryDate: $e');
            continue;
          }
        } else {
          print('      ⚠️ No expiry date, using default');
          expiryDate = DateTime.now().add(const Duration(days: 30));
        }
        
        // Get points cost
        final pointsCost = (data['pointsRequired'] as int? ?? 0);
        
        // CHECK IF USER HAS ENOUGH POINTS - NEW FILTER
        final userHasEnoughPoints = _userData['totalPoints'] >= pointsCost;
        if (!userHasEnoughPoints) {
          print('      ❌ User has ${_userData['totalPoints']} points, needs $pointsCost - skipping');
          continue;
        }
        
        // Check if user has already claimed this voucher
        final userClaims = await _firestore
            .collection('rewards_claimed')
            .where('userId', isEqualTo: _currentUserId)
            .where('rewardId', isEqualTo: doc.id)
            .get();

        final maxClaims = (data['maxClaimsPerUser'] as int? ?? 1);
        final userClaimCount = userClaims.docs.length;
        final canClaim = userClaimCount < maxClaims;

        print('      Max claims: $maxClaims, User claims: $userClaimCount, Can claim: $canClaim');
        
        if (canClaim) {
          _availableVouchers.add({
            'id': doc.id,
            'name': data['name'] ?? 'Voucher',
            'points': pointsCost,
            'type': 'voucher',
            'category': data['category'] ?? 'General',
            'description': data['description'] ?? '',
            'expiryDate': expiryDate,
            'discountValue': data['discountValue'] ?? 0,
            'maxClaims': maxClaims,
            'userClaims': userClaimCount,
            'isActive': data['isActive'] ?? true,
          });
          print('      ✅ Added to available vouchers');
        } else {
          print('      ❌ User has already claimed this voucher');
        }
      }

      print('✅ Available vouchers for user: ${_availableVouchers.length}');

    } catch (e) {
      print('❌ Error loading vouchers: $e');
      _availableVouchers = [];
    }
  }

  // Load claimed rewards from Firebase (kept for points history)
  Future<void> _loadClaimedRewards() async {
    if (_currentUserId == null) return;

    try {
      print('🔄 Loading claimed rewards...');
      
      final claimedSnapshot = await _firestore
          .collection('rewards_claimed')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('claimedAt', descending: true)
          .get();

      print('✅ Found ${claimedSnapshot.docs.length} claimed rewards');
      
      _redeemedVouchers = [];
      
      for (var doc in claimedSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final claimedAt = (data['claimedAt'] as Timestamp).toDate();
        final expiryDate = (data['expiryDate'] as Timestamp).toDate();
        final now = DateTime.now();
        
        // Determine status
        String status = data['status'] ?? 'active';
        if (status == 'active' && expiryDate.isBefore(now)) {
          status = 'expired';
        }

        // Get reward details
        final rewardId = data['rewardId'];
        Map<String, dynamic> rewardData = {};
        String rewardName = 'Reward';
        String rewardCategory = 'General';
        
        if (rewardId != null) {
          try {
            final rewardDoc = await _firestore.collection('rewards').doc(rewardId).get();
            if (rewardDoc.exists) {
              rewardData = rewardDoc.data() as Map<String, dynamic>;
              rewardName = rewardData['name'] ?? 'Reward';
              rewardCategory = rewardData['category'] ?? 'General';
              print('  Found reward details for $rewardId: $rewardName');
            }
          } catch (e) {
            print('  Error loading reward details for $rewardId: $e');
          }
        }

        final voucher = {
          'id': doc.id,
          'name': rewardName,
          'originalPoints': data['pointUsed'] ?? 0,
          'redeemedDate': DateFormat('yyyy-MM-dd').format(claimedAt),
          'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
          'status': status,
          'category': rewardCategory,
          'voucherCode': data['voucherCode'] ?? 'BC${doc.id.substring(0, 6).toUpperCase()}',
          'partnerStore': data['partnerStore'] ?? 'BloodConnect Partner',
          'usedDate': data['usedDate'],
          'minPurchase': data['minPurchase'] ?? 'N/A',
          'userId': _currentUserId,
          'rewardId': rewardId,
          'type': rewardData['type'] ?? 'voucher',
          'description': rewardData['description'] ?? '',
        };

        _redeemedVouchers.add(voucher);
      }

    } catch (e) {
      print('❌ Error loading claimed rewards: $e');
      _redeemedVouchers = [];
    }
  }

  // Generate points history from donations and claimed rewards
  Future<void> _generatePointsHistory(
    List<QueryDocumentSnapshot> donationDocs,
    List<QueryDocumentSnapshot> claimedDocs,
  ) async {
    final List<Map<String, dynamic>> history = [];

    // Add donation points
    for (var doc in donationDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final donationDate = (data['donation_date'] as Timestamp).toDate();
      
      history.add({
        'id': doc.id,
        'date': DateFormat('yyyy-MM-dd').format(donationDate),
        'description': 'Blood Donation',
        'points': '+10',
        'type': 'earned',
        'relatedId': doc.id,
        'category': 'Blood Donation',
        'userId': _currentUserId,
        'timestamp': donationDate,
      });
    }

    // Add redemption points from claimed rewards
    for (var doc in claimedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final redeemedDate = (data['claimedAt'] as Timestamp).toDate();
      final isUsed = data['status'] == 'used';
      
      // Get reward name
      String rewardName = 'Reward';
      final rewardId = data['rewardId'];
      if (rewardId != null) {
        try {
          final rewardDoc = await _firestore.collection('rewards').doc(rewardId).get();
          if (rewardDoc.exists) {
            final rewardData = rewardDoc.data() as Map<String, dynamic>;
            rewardName = rewardData['name'] ?? 'Reward';
          }
        } catch (e) {
          print('Error loading reward name for history: $e');
        }
      }
      
      // Redemption entry
      history.add({
        'id': 'redeem_${doc.id}',
        'date': DateFormat('yyyy-MM-dd').format(redeemedDate),
        'description': 'Redeemed $rewardName',
        'points': '-${data['pointUsed'] ?? 0}',
        'type': 'redeemed',
        'relatedId': doc.id,
        'category': 'Reward Redemption',
        'userId': _currentUserId,
        'timestamp': redeemedDate,
      });

      // Usage entry (if used)
      if (isUsed && data['usedDate'] != null) {
        history.add({
          'id': 'use_${doc.id}',
          'date': data['usedDate'],
          'description': 'Used $rewardName',
          'points': '0',
          'type': 'voucher_used',
          'relatedId': doc.id,
          'category': 'Reward Usage',
          'userId': _currentUserId,
          'timestamp': DateTime.parse(data['usedDate']),
        });
      }
    }

    history.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    
    setState(() {
      _pointsHistory = history;
    });
  }

  // Helper: Get icon for reward based on type and category
  IconData _getIconForReward(Map<String, dynamic> rewardData) {
    final type = rewardData['type'] ?? 'voucher';
    final category = rewardData['category']?.toString().toLowerCase() ?? 'general';
    
    if (type == 'product') {
      switch (category) {
        case 'clothing':
          return Icons.checkroom;
        case 'electronics':
          return Icons.devices;
        case 'home':
          return Icons.home;
        case 'accessories':
          return Icons.sports_bar;
        default:
          return Icons.shopping_bag;
      }
    } else { // voucher
      switch (category) {
        case 'food & beverages':
        case 'food':
          return Icons.restaurant;
        case 'shopping':
          return Icons.shopping_cart;
        case 'entertainment':
          return Icons.movie;
        case 'healthcare':
          return Icons.medical_services;
        case 'electronics':
          return Icons.devices;
        default:
          return Icons.confirmation_number;
      }
    }
  }

  // Refresh all data
  Future<void> _refreshData() async {
    setState(() {
      _isLoadingRewards = true;
    });

    try {
      await _loadUserData();
    } catch (e) {
      _showErrorSnackBar('Failed to refresh data: $e');
    } finally {
      setState(() {
        _isLoadingRewards = false;
      });
    }
  }

  // Handle tab switching
  void _switchTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    _tabController.animateTo(index);
  }

  // Handle voucher redemption from Redeem tab
  Future<void> _handleVoucherRedemption(String voucherId, int pointsCost, String voucherName, String voucherCode) async {
    if (_currentUserId == null) return;

    try {
      // Check if user has enough points
      if (_userData['totalPoints'] < pointsCost) {
        _showErrorSnackBar('Insufficient points!');
        return;
      }

      // Get voucher details
      final voucherDoc = await _firestore.collection('rewards').doc(voucherId).get();
      if (!voucherDoc.exists) {
        _showErrorSnackBar('Voucher not found!');
        return;
      }

      final voucherData = voucherDoc.data() as Map<String, dynamic>;
      final maxClaims = voucherData['maxClaimsPerUser'] ?? 1;

      // Check if user has already claimed this voucher
      final existingClaims = await _firestore
          .collection('rewards_claimed')
          .where('userId', isEqualTo: _currentUserId)
          .where('rewardId', isEqualTo: voucherId)
          .get();

      if (existingClaims.docs.length >= maxClaims) {
        _showErrorSnackBar('You have already claimed this voucher!');
        return;
      }

      // Create claimed voucher document
      final now = DateTime.now();
      final expiryDate = (voucherData['expiryDate'] as Timestamp).toDate();
      
      final claimedVoucher = {
        'userId': _currentUserId,
        'rewardId': voucherId,
        'pointUsed': pointsCost,
        'claimedAt': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'usedDate': null,
        'voucherCode': voucherCode,
        'partnerStore': voucherData['partnerStore'] ?? 'BloodConnect Partner',
        'minPurchase': voucherData['minPurchase'] ?? 'N/A',
      };

      await _firestore.collection('rewards_claimed').add(claimedVoucher);

      // Update voucher claim count
      await _firestore.collection('rewards').doc(voucherId).update({
        'claimCount': FieldValue.increment(1),
      });

      // Update local state
      final claimedVoucherData = {
        'id': 'new_claim_${now.millisecondsSinceEpoch}',
        'name': voucherName,
        'originalPoints': pointsCost,
        'redeemedDate': DateFormat('yyyy-MM-dd').format(now),
        'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
        'status': 'active',
        'category': voucherData['category'] ?? 'General',
        'voucherCode': voucherCode,
        'partnerStore': voucherData['partnerStore'] ?? 'BloodConnect Partner',
        'usedDate': null,
        'minPurchase': voucherData['minPurchase'] ?? 'N/A',
        'userId': _currentUserId,
        'rewardId': voucherId,
        'type': 'voucher',
      };

      setState(() {
        _redeemedVouchers.insert(0, claimedVoucherData);
        
        // Add to points history
        _pointsHistory.insert(0, {
          'id': 'history_${now.millisecondsSinceEpoch}',
          'date': claimedVoucherData['redeemedDate'],
          'description': 'Redeemed $voucherName',
          'points': '-$pointsCost',
          'type': 'redeemed',
          'relatedId': voucherId,
          'category': 'Voucher Redemption',
          'userId': _currentUserId,
          'timestamp': now,
        });
        
        // Update points by deducting from total
        _userData['totalPoints'] = _userData['totalPoints'] - pointsCost;
      });

      _showSuccessSnackBar('Voucher redeemed successfully!');

      // Refresh data
      await _loadAvailableVouchers();
      await _loadClaimedRewards();

    } catch (e) {
      print('Error redeeming voucher: $e');
      _showErrorSnackBar('Failed to redeem voucher: $e');
    }
  }

  // Handle reward redemption (for My Rewards tab)
  Future<void> _handleRewardRedemption(Map<String, dynamic> reward) async {
    if (_currentUserId == null) return;

    try {
      // Check if user has enough points
      if (_userData['totalPoints'] < reward['points']) {
        _showErrorSnackBar('Insufficient points!');
        return;
      }

      // Check if user has already claimed this reward
      final existingClaims = await _firestore
          .collection('rewards_claimed')
          .where('userId', isEqualTo: _currentUserId)
          .where('rewardId', isEqualTo: reward['id'])
          .get();

      final rewardDoc = await _firestore.collection('rewards').doc(reward['id']).get();
      if (!rewardDoc.exists) {
        _showErrorSnackBar('Reward not found!');
        return;
      }

      final rewardData = rewardDoc.data() as Map<String, dynamic>;
      final maxClaims = rewardData['maxClaimsPerUser'] ?? 1;

      if (existingClaims.docs.length >= maxClaims) {
        _showErrorSnackBar('You have already claimed this reward!');
        return;
      }

      // Create claimed reward document
      final now = DateTime.now();
      final expiryDate = reward['expiryDate'] ?? now.add(const Duration(days: 30));
      
      final claimedReward = {
        'userId': _currentUserId,
        'rewardId': reward['id'],
        'pointUsed': reward['points'],
        'claimedAt': Timestamp.fromDate(now),
        'expiryDate': Timestamp.fromDate(expiryDate),
        'status': 'active',
        'usedDate': null,
        'voucherCode': 'BC${now.millisecondsSinceEpoch.toString().substring(0, 6)}',
        'partnerStore': rewardData['partnerStore'] ?? 'BloodConnect Partner',
        'minPurchase': rewardData['minPurchase'] ?? 'N/A',
      };

      await _firestore.collection('rewards_claimed').add(claimedReward);

      // Update reward claim count
      await _firestore.collection('rewards').doc(reward['id']).update({
        'claimCount': FieldValue.increment(1),
      });

      // Update local state
      final claimedRewardData = {
        'id': 'new_claim_${now.millisecondsSinceEpoch}',
        'name': reward['name'],
        'originalPoints': reward['points'],
        'redeemedDate': DateFormat('yyyy-MM-dd').format(now),
        'expiryDate': DateFormat('yyyy-MM-dd').format(expiryDate),
        'status': 'active',
        'category': reward['category'] ?? 'General',
        'voucherCode': 'BC${now.millisecondsSinceEpoch.toString().substring(0, 6)}',
        'partnerStore': 'BloodConnect Partner',
        'usedDate': null,
        'minPurchase': 'N/A',
        'userId': _currentUserId,
        'rewardId': reward['id'],
        'type': reward['type'],
      };

      setState(() {
        _redeemedVouchers.insert(0, claimedRewardData);
        
        // Add to points history
        _pointsHistory.insert(0, {
          'id': 'history_${now.millisecondsSinceEpoch}',
          'date': claimedRewardData['redeemedDate'],
          'description': 'Redeemed ${reward['name']}',
          'points': '-${reward['points']}',
          'type': 'redeemed',
          'relatedId': reward['id'],
          'category': 'Reward Redemption',
          'userId': _currentUserId,
          'timestamp': now,
        });
        
        // Update points by deducting from total
        _userData['totalPoints'] = _userData['totalPoints'] - reward['points'];
      });

      _showSuccessSnackBar('${reward['type'] == 'voucher' ? 'Voucher' : 'Reward'} redeemed successfully!');

      // Refresh data
      await _loadAvailableRewards();
      await _loadAvailableVouchers();

    } catch (e) {
      print('Error redeeming reward: $e');
      _showErrorSnackBar('Failed to redeem reward: $e');
    }
  }

  // Show reward details
  void _showRewardDetails(Map<String, dynamic> reward) {
    final bool canRedeem = _userData['totalPoints'] >= reward['points'];
    final isExpired = reward['expiryDate'] != null && (reward['expiryDate'] as DateTime).isBefore(DateTime.now());
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: canRedeem && !isExpired ? const Color(0xFFDE0D0D) : Colors.grey[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(reward['icon'], color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Reward Details',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                        // Reward preview
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: canRedeem && !isExpired ? const Color(0xFFDE0D0D) : Colors.grey[400],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (canRedeem && !isExpired ? const Color(0xFFDE0D0D) : Colors.grey[400]!).withOpacity(0.3),
                                  spreadRadius: 0,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(reward['icon'], color: Colors.white, size: 48),
                                const SizedBox(height: 8),
                                Text(
                                  reward['name'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Reward information
                        _buildInfoCard(
                          'Reward Information',
                          [
                            'Name: ${reward['name']}',
                            'Type: ${reward['type']}',
                            'Category: ${reward['category']}',
                            'Points Required: ${reward['points']}',
                            'Available Stock: ${reward['stock']}',
                            if (reward['expiryDate'] != null)
                              'Expires: ${DateFormat('dd MMM yyyy').format(reward['expiryDate'])}',
                          ],
                          Colors.blue,
                        ),
                        
                        if ((reward['description'] as String).isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            'Description',
                            [reward['description']],
                            Colors.green,
                          ),
                        ],
                        
                        const SizedBox(height: 16),
                        // User points information
                        _buildInfoCard(
                          'Your Points',
                          [
                            'Current Points: ${_userData['totalPoints']}',
                            'Points Needed: ${reward['points']}',
                            if (_userData['totalPoints'] < reward['points'])
                              'Points Short: ${reward['points'] - _userData['totalPoints']}',
                          ],
                          Colors.orange,
                        ),
                        
                        // Warnings
                        if (isExpired) ...[
                          const SizedBox(height: 16),
                          _buildWarningCard(
                            'This reward has expired',
                            Colors.red,
                            Icons.error_outline,
                          ),
                        ],
                        
                        if (_userData['totalPoints'] < reward['points'] && !isExpired) ...[
                          const SizedBox(height: 16),
                          _buildWarningCard(
                            'You need ${reward['points'] - _userData['totalPoints']} more points to redeem this reward',
                            Colors.orange,
                            Icons.info_outline,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: canRedeem && !isExpired ? () {
                            Navigator.of(context).pop();
                            _confirmRewardRedemption(reward);
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canRedeem && !isExpired ? const Color(0xFFDE0D0D) : Colors.grey[400],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            canRedeem && !isExpired ? 'Redeem Now' : 'Cannot Redeem',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  // Confirm reward redemption
  void _confirmRewardRedemption(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Redemption', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDE0D0D))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to redeem "${reward['name']}" for ${reward['points']} points?', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(color: const Color(0xFFDE0D0D), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(reward['icon'], color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      reward['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Current Points:'),
                      Text('${_userData['totalPoints']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Points to Redeem:'),
                      Text('-${reward['points']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Remaining Points:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('${_userData['totalPoints'] - reward['points']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDE0D0D))),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _handleRewardRedemption(reward);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Redemption'),
            ),
          ],
        );
      },
    );
  }

  // Helper widgets
  Widget _buildInfoCard(String title, List<String> details, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(detail, style: TextStyle(fontSize: 14, color: color.withOpacity(0.9))),
          )),
        ],
      ),
    );
  }

  Widget _buildWarningCard(String message, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))),
        ],
      ),
    );
  }

  // Snackbars
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.info, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ]),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Get user initials
  String _getUserInitials() {
    final name = _userData['name'].toString();
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) return nameParts[0].substring(0, 1).toUpperCase();
    return '${nameParts.first.substring(0, 1).toUpperCase()}${nameParts.last.substring(0, 1).toUpperCase()}';
  }

  // Build methods
  Widget _buildUserCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDE0D0D), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDE0D0D).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _userData['name'],
            style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildUserInfoColumn('Blood Group', _userData['bloodGroup'], isBloodGroup: true),
              const SizedBox(width: 40),
              _buildUserInfoColumn('Total Points', '${_userData['totalPoints']}'),
              const Spacer(),
              _buildUserInfoColumn('Donations', '${_userData['lifetimeDonations']}'),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Spacer(),
              Text(
                'BloodConnect',
                style: TextStyle(color: Color(0xFFDE0D0D), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Icon(Icons.favorite, color: Color(0xFFDE0D0D), size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoColumn(String label, String value, {bool isBloodGroup = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isBloodGroup ? const Color(0xFFDE0D0D) : const Color(0xFFDE0D0D).withOpacity(0.1),
            borderRadius: BorderRadius.circular(isBloodGroup ? 20 : 8),
            border: isBloodGroup ? null : Border.all(color: const Color(0xFFDE0D0D).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBloodGroup) const Icon(Icons.water_drop, color: Colors.white, size: 14),
              if (isBloodGroup) const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  color: isBloodGroup ? Colors.white : const Color(0xFFDE0D0D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String title, int index) {
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDE0D0D),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getTabContent(),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildMyRewardsTab();
      case 1:
        return RedeemVoucherWidget(
          userPoints: _userData['totalPoints'],
          availableVouchers: _availableVouchers,
          onRedeem: _handleVoucherRedemption,
        );
      case 2:
        return PointsHistoryWidget(
          pointsHistory: _pointsHistory,
          formatDescription: (description) {
            if (description.toLowerCase().contains('blood donation')) {
              return 'Blood Donation';
            }
            return description;
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildMyRewardsTab() {
    if (_isLoadingUserData) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      key: const ValueKey('my_rewards'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Available Rewards',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFDE0D0D)),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_redeemableRewards.length} available',
                style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Rewards Grid
        Expanded(
          child: _isLoadingRewards
              ? const Center(child: CircularProgressIndicator())
              : _redeemableRewards.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_giftcard, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'No rewards available',
                            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check back later for new rewards!',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.0,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: _redeemableRewards.length,
                      itemBuilder: (context, index) {
                        final reward = _redeemableRewards[index];
                        return _buildRewardCard(reward);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final bool canRedeem = _userData['totalPoints'] >= reward['points'];
    final isExpired = reward['expiryDate'] != null && (reward['expiryDate'] as DateTime).isBefore(DateTime.now());
    
    return GestureDetector(
      onTap: () => _showRewardDetails(reward),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: canRedeem && !isExpired ? const Color(0xFFDE0D0D) : Colors.grey[400],
          borderRadius: BorderRadius.circular(16),
          boxShadow: canRedeem && !isExpired
              ? [
                  BoxShadow(
                    color: const Color(0xFFDE0D0D).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Status labels
            if (isExpired)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: const Text(
                  'Expired',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            
            // Main content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isExpired ? 12.0 : 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(reward['icon'], color: Colors.white, size: 40),
                    const SizedBox(height: 8),
                    Text(
                      reward['name'],
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${reward['points']} pts',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomHeader(
        appName: 'BloodConnect',
        userInitials: _getUserInitials(),
        fullName: _userData['name'].toString(), // Pass the full name dynamic value
        currentPage: 'rewards',
        onRewardsPressed: () {
          // Already on rewards page
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
          // Page Title
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'My Rewards',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          
          // Tab selector - NOW 3 TABS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTabButton('My Rewards', 0),
                  _buildTabButton('Redeem\nVoucher', 1),
                  _buildTabButton('Points\nHistory', 2), // Changed from Used Voucher to Points History
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // User card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildUserCard(),
          ),
          
          const SizedBox(height: 24),
          
          // Content based on selected tab
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTabContent(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return CustomBottomNavigationBar(
      currentIndex: 0, // Default to Home for now, or use a specific index if defined
      onTap: (index) => NavigationHelper.handleNavigation(context, index, (i) {}),
    );
  }
}