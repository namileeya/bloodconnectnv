import 'package:flutter/material.dart';
import '../screen/donation_page.dart'; // Import the donation page

class ProcessWidget extends StatelessWidget {
  const ProcessWidget({super.key});

  // Blood Donation Process Data
  static final List<Map<String, dynamic>> _processSteps = [
    {
      'step': 'Step 1',
      'title': 'Come to the Donation Centre',
      'description': 'Book an appointment via BloodConnect or simply walk-in to any blood donation centre (Hospital Kuala Lumpur, Pusat Darah Negara, or Hospital Selayang). Bring a valid ID for verification.',
      'icon': Icons.location_on,
      'duration': 'Walk-in or Appointment',
    },
    {
      'step': 'Step 2',
      'title': 'Registration',
      'description': 'All donors are required to register and answer all of the pre-screening questions. If you wish to answer the questions via BloodConnect, please answer them on your donation day.',
      'icon': Icons.assignment,
      'duration': '5-10 minutes',
    },
    {
      'step': 'Step 3',
      'title': 'Medical Assessment',
      'description': 'The doctor will inquire about some medical history and personal questions. Please make sure that all the information disclosed are true and correct.',
      'icon': Icons.medical_information,
      'duration': '5-8 minutes',
    },
    {
      'step': 'Step 4',
      'title': 'Medical Checkup',
      'description': 'Your body temperature, blood pressure, heart pulse rate and hemoglobin level in your blood will be measured to ensure you\'re fit to donate.',
      'icon': Icons.health_and_safety,
      'duration': '8-10 minutes',
    },
    {
      'step': 'Step 5',
      'title': 'Donate',
      'description': 'Relax and make yourself comfortable on the designated chair. The doctor will cleanse an area on your arm and insert a brand new sterile needle for the blood draw.',
      'icon': Icons.bloodtype,
      'duration': '8-10 minutes',
    },
    {
      'step': 'Step 6',
      'title': 'Finished',
      'description': 'Rest for another 5-10 minutes and it\'s all done! Wait for another 56 days before your next donation. Enjoy refreshments to help your body recover.',
      'icon': Icons.check_circle,
      'duration': '10-15 minutes',
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
            'Blood Donation Process',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _processSteps.length + 1, // +1 for the button
            itemBuilder: (context, index) {
              // Show the button as the last item
              if (index == _processSteps.length) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DonationPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDE0D0D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Book Appointment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              // Show process steps
              final step = _processSteps[index];
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
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDE0D0D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Icon(
                          step['icon'],
                          color: const Color(0xFFDE0D0D),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  step['step'],
                                  style: const TextStyle(
                                    color: Color(0xFFDE0D0D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    step['duration'],
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step['description'],
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                height: 1.4,
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
          ),
        ),
      ],
    );
  }
}