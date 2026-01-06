import 'package:flutter/material.dart';

class HeaderTwo extends StatefulWidget {
  // Properties that can be passed from Firebase later
  final String fullName;
  final String bloodType;
  final String donorStatus;
  final int donationCount;
  final String? userInitials;

  const HeaderTwo({
    super.key,
    required this.fullName,
    required this.bloodType,
    this.donorStatus = "Regular Donor",
    this.donationCount = 1,
    this.userInitials,
  });

  @override
  State<HeaderTwo> createState() => _HeaderTwoState();
}

class _HeaderTwoState extends State<HeaderTwo> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Color(0xFFDE0D0D), // Red background color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Profile Avatar - Initials only
            _buildProfileAvatar(),
            const SizedBox(width: 16),
            
            // User Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  Text(
                    widget.fullName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Blood Type
                  Text(
                    "${widget.bloodType} Blood Type",
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Status Pills Row
                  Row(
                    children: [
                      _buildStatusPill(widget.donorStatus),
                      const SizedBox(width: 8),
                      _buildStatusPill("${widget.donationCount} Donation${widget.donationCount > 1 ? 's' : ''}"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Profile Avatar Widget - Only shows initials
  Widget _buildProfileAvatar() {
    String initials = widget.userInitials ?? _getInitials(widget.fullName);
    
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFFDE0D0D),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  // Status Pill Widget
  Widget _buildStatusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white30,
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper method to extract initials from full name
  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    // Take first letter of first name and first letter of last name
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }
}

// Example usage widget for testing
class HeaderTwoExample extends StatefulWidget {
  const HeaderTwoExample({super.key});

  @override
  State<HeaderTwoExample> createState() => _HeaderTwoExampleState();
}

class _HeaderTwoExampleState extends State<HeaderTwoExample> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Example header with sample data
          const HeaderTwo(
            fullName: "AMMAL ALIYA BINTI MISRON",
            bloodType: "O-",
            donorStatus: "Regular Donor",
            donationCount: 1,
          ),
          
          // Rest of the page content would go here
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: const Center(
                child: Text(
                  "Profile displays user initials only",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Firebase integration helper class (for future use)
class HeaderTwoFirebaseModel {
  final String uid;
  final String fullName;
  final String bloodType;
  final String donorStatus;
  final int donationCount;
  final DateTime? lastDonation;
  
  const HeaderTwoFirebaseModel({
    required this.uid,
    required this.fullName,
    required this.bloodType,
    this.donorStatus = "Regular Donor",
    this.donationCount = 0,
    this.lastDonation,
  });

  // Factory constructor for Firebase document data
  factory HeaderTwoFirebaseModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return HeaderTwoFirebaseModel(
      uid: uid,
      fullName: data['fullName'] ?? 'Unknown User',
      bloodType: data['bloodType'] ?? 'Unknown',
      donorStatus: data['donorStatus'] ?? 'Regular Donor',
      donationCount: data['donationCount'] ?? 0,
      lastDonation: data['lastDonation']?.toDate(),
    );
  }

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'bloodType': bloodType,
      'donorStatus': donorStatus,
      'donationCount': donationCount,
      'lastDonation': lastDonation,
    };
  }
}