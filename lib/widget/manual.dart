import 'package:flutter/material.dart';
import 'book_appointment_tutorial.dart'; // Import the tutorial
import 'find_donors_tutorial.dart'; // Import the find donors tutorial
import 'donate_now_tutorial.dart'; // Import the donate now tutorial

class ManualWidget extends StatelessWidget {
  const ManualWidget({super.key});

  // BloodConnect Manual Data
  static final List<Map<String, dynamic>> _appGuide = [
    {
      'title': 'How to Book an Appointment',
      'description': 'Learn how to schedule your blood donation appointment through the app. Find available slots and confirm your preferred time.',
      'icon': Icons.book_online,
      'features': ['Select Date & Time', 'Choose Location', 'Confirm Booking'],
    },
    {
      'title': 'How to Donate Now',
      'description': 'Understand the complete donation process from registration to post-donation care. Get prepared for a smooth experience.',
      'icon': Icons.bloodtype,
      'features': ['Walk-in Process', 'Required Documents', 'Health Screening'],
    },
    {
      'title': 'How to Find Donors',
      'description': 'Connect with potential blood donors in your area. Search by blood type and location for emergency requests.',
      'icon': Icons.search,
      'features': ['Search by Blood Type', 'Location Filter', 'Contact Donors'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'BloodConnect Manual',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _appGuide.length,
            itemBuilder: (context, index) {
              final guide = _appGuide[index];
              return GestureDetector(
                onTap: () {
                  if (guide['title'] == 'How to Book an Appointment') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookAppointmentTutorial(),
                      ),
                    );
                  } else if (guide['title'] == 'How to Find Donors') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FindDonorsTutorial(),
                      ),
                    );
                  } else if (guide['title'] == 'How to Donate Now') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DonateNowTutorial(),
                      ),
                    );
                  }
                  // Add navigation for other tutorials here if needed
                },
                child: Container(
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDE0D0D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              guide['icon'],
                              color: const Color(0xFFDE0D0D),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              guide['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        guide['description'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (guide['features'] as List<String>).map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDE0D0D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              feature,
                              style: const TextStyle(
                                color: Color(0xFFDE0D0D),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),);
            },
          ),
        ),
      ],
    );
  }
}