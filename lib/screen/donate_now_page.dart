import 'package:bloodconnect/user_session.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';

class DonateNowPage extends StatefulWidget {
  const DonateNowPage({super.key});

  @override
  State<DonateNowPage> createState() => _DonateNowPageState();
}

class _DonateNowPageState extends State<DonateNowPage> {
  bool _agreementChecked = false;
  bool _showSuccessDialog = false;
  bool _showVenueSelection = true;
  int _selectedVenueIndex = -1;
  bool _showQuestionnaire = false;
  bool _isSubmitting = false;
  
  // User data from session
  String _fullName = "";
  String _gender = "";
  String _userId = "";
  
  // Firestore data
  List<Map<String, dynamic>> venues = [];
  bool _isLoading = true;
  bool _hasError = false;

  // Pre-screening answers storage
  final Map<String, bool?> _answers = {};

  // Firestore reference
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHospitals();
  }

  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await UserSession.getUser();
      
      if (userData == null) {
        throw Exception('No user data found in session');
      }
      
      setState(() {
        _userId = userData['user_id']?.toString() ?? '';
        _fullName = userData['full_name']?.toString() ?? '';
        _gender = userData['gender']?.toString() ?? '';
      });
      
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadHospitals() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      QuerySnapshot querySnapshot = await _firestore.collection('hospitals').get();
      
      List<Map<String, dynamic>> hospitalList = [];
      
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        String hospitalName = data['name']?.toString() ?? '';
        
        if (hospitalName.isEmpty) continue;
        
        String initials = _generateHospitalInitials(hospitalName);
        
        hospitalList.add({
          'id': doc.id,
          'name': hospitalName,
          'location': data['address']?.toString() ?? '',
          'city': data['city']?.toString() ?? '',
          'state': data['state']?.toString() ?? '',
          'initials': initials,
        });
      }
      
      setState(() {
        venues = hospitalList;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading hospitals: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  String _generateHospitalInitials(String hospitalName) {
    List<String> words = hospitalName.trim().split(' ');
    words = words.where((word) => word.isNotEmpty).toList();
    
    if (words.isEmpty) return 'H';
    if (words.length == 1) return words[0].substring(0, 1).toUpperCase();
    
    return '${words[0].substring(0, 1).toUpperCase()}${words[1].substring(0, 1).toUpperCase()}';
  }

  // Calculate eligibility status based on answers
  String _calculateEligibilityStatus() {
    // Check for immediate disqualifications
    if (_answers['Do you have any flu, cough, fever, or infection right now?'] == true) {
      return 'ineligible_temporary';
    }
    
    if (_answers['Are you feeling well today?'] == false) {
      return 'ineligible_temporary';
    }
    
    if (_answers['Have you ever been diagnosed with hepatitis B, hepatitis C, HIV/AIDS, or syphilis?'] == true) {
      return 'ineligible_permanent';
    }
    
    if (_answers['Have you ever tested positive for HIV, hepatitis, or other sexually transmitted diseases?'] == true) {
      return 'ineligible_permanent';
    }
    
    if (_answers['Have you been permanently deferred from donating blood before?'] == true) {
      return 'ineligible_permanent';
    }
    
    // Check for temporary deferrals
    if (_answers['Have you donated blood in the past 3 months (men) / 4 months (women)?'] == true) {
      return 'ineligible_temporary';
    }
    
    if (_answers['Have you had tattoos, ear/body piercing, or acupuncture in the past 6 months?'] == true) {
      return 'ineligible_temporary';
    }
    
    if (_answers['Have you received any vaccination in the past 1 month?'] == true) {
      return 'ineligible_temporary';
    }
    
    if (_answers['Have you had any surgery, blood transfusion, or organ transplant in the past 6 months?'] == true) {
      return 'ineligible_temporary';
    }
    
    // Check for conditions needing admin review
    if (_answers['Do you have any chronic diseases (e.g., asthma, diabetes, heart disease, epilepsy)?'] == true) {
      return 'needs_review';
    }
    
    if (_answers['Are you taking long-term medication (e.g., for high blood pressure, epilepsy, thyroid)?'] == true) {
      return 'needs_review';
    }
    
    if (_answers['Have you ever been diagnosed with cancer?'] == true) {
      return 'needs_review';
    }
    
    // Women-specific checks
    if (_gender.toLowerCase() == 'female') {
      if (_answers['Are you currently pregnant?'] == true) {
        return 'ineligible_temporary';
      }
      
      if (_answers['Are you breastfeeding?'] == true) {
        return 'ineligible_temporary';
      }
      
      if (_answers['Are you having your period today?'] == true) {
        return 'ineligible_temporary';
      }
    }
    
    // If all checks pass
    return 'eligible';
  }

  Future<void> _submitQuestionnaire() async {
    if (_selectedVenueIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a hospital')),
      );
      return;
    }

    Map<String, List<String>> relevantQuestions = _getRelevantQuestions();
    bool allAnswered = relevantQuestions.values
        .expand((questions) => questions)
        .every((question) => _answers[question] != null);
    
    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please answer all questions')),
      );
      return;
    }

    if (_userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please login again')),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // Calculate the status
      String status = _calculateEligibilityStatus();
      
      await _firestore.collection('eligibility_requests').add({
        'userId': _userId,
        'userName': _fullName,
        'gender': _gender,
        'hospitalName': venues[_selectedVenueIndex]['name'], // Added hospital name
        'answers': _answers,
        'autoStatus': status, // Admin can override this
        'adminStatus': status, // Start with auto status, admin can change
        'submittedDate': FieldValue.serverTimestamp(),
        'status': 'pending_review', // General status
      });

      setState(() {
        _showSuccessDialog = true;
        _isSubmitting = false;
      });

    } catch (e) {
      print('Error submitting: $e');
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed')),
      );
    }
  }

  // Pre-screening questions (unchanged)
  final Map<String, List<String>> _questions = {
    'General Health': [
      'Are you feeling well today?',
      'Do you have any flu, cough, fever, or infection right now?',
      'Have you had fever, flu, or infection in the past 3 weeks?',
      'Do you have any chronic diseases (e.g., asthma, diabetes, heart disease, epilepsy)?',
      'Have you ever been diagnosed with cancer?',
    ],
    'Medication & Treatment': [
      'Are you currently taking antibiotics?',
      'Have you taken aspirin, painkillers, or anti-inflammatory drugs in the past 48 hours?',
      'Are you taking long-term medication (e.g., for high blood pressure, epilepsy, thyroid)?',
      'Have you received any vaccination in the past 1 month?',
      'Have you had any surgery, blood transfusion, or organ transplant in the past 6 months?',
    ],
    'Infectious Diseases': [
      'Have you ever been diagnosed with hepatitis B, hepatitis C, HIV/AIDS, or syphilis?',
      'Have you ever tested positive for HIV, hepatitis, or other sexually transmitted diseases?',
      'Have you had jaundice (yellow eyes/skin) after age 10?',
      'Have you ever had tuberculosis (TB)?',
      'Have you ever been told not to donate blood for medical reasons?',
    ],
    'Lifestyle & Risk Behaviors': [
      'Have you ever injected recreational drugs or shared needles?',
      'Have you had tattoos, ear/body piercing, or acupuncture in the past 6 months?',
      'Have you had close contact with a person with hepatitis or HIV?',
      'Have you had multiple sexual partners or engaged in high-risk sexual activity in the past 12 months?',
      'For men: Have you had sexual relations with another man?',
    ],
    'Travel History': [
      'Have you traveled overseas in the past 6 months?',
      'Have you been to malaria-risk areas in the past 12 months?',
      'Have you lived in the UK/Europe between 1980–1996 (mad cow disease period)?',
    ],
    'Donation History': [
      'Have you donated blood in the past 3 months (men) / 4 months (women)?',
      'Have you ever fainted or had complications during/after a blood donation?',
      'Have you been permanently deferred from donating blood before?',
    ],
    'Others': [
      'Have you received experimental treatment, injections, or participated in clinical trials?',
      'Have you had close contact with someone with COVID-19 in the past 14 days?',
      'Have you tested positive for COVID-19 in the past 28 days?',
    ],
  };

  final Map<String, List<String>> _womenOnlyQuestions = {
    'Women Donors Only': [
      'Are you currently pregnant?',
      'Are you breastfeeding?',
      'Are you having your period today?',
    ],
  };

  Map<String, List<String>> _getRelevantQuestions() {
    Map<String, List<String>> relevantQuestions = Map.from(_questions);
    
    if (_gender.toLowerCase() == 'female') {
      relevantQuestions.addAll(_womenOnlyQuestions);
    }
    
    return relevantQuestions;
  }

  String _getUserInitials() {
    if (_fullName.isEmpty) return 'U';
    
    List<String> nameParts = _fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    if (nameParts.length == 1) return nameParts[0].substring(0, 1).toUpperCase();
    
    return '${nameParts.first.substring(0, 1).toUpperCase()}${nameParts.last.substring(0, 1).toUpperCase()}';
  }

  void _updateNavIndex(int index) {}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
          body: _showVenueSelection 
              ? _buildVenueSelection() 
              : _showQuestionnaire 
                  ? _buildQuestionnaire()
                  : _buildPreScreening(),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: -1,
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        if (_showSuccessDialog) _buildSuccessPopup(),
      ],
    );
  }

  Widget _buildVenueSelection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFDE0D0D)),
            SizedBox(height: 20),
            Text(
              'Loading hospitals...',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_hasError || venues.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 20),
              Text(
                'Unable to load hospitals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Please check your internet connection',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadHospitals,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                ),
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
                  'Donate Now',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'Choose Your Venue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFDE0D0D),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ...venues.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> venue = entry.value;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: _selectedVenueIndex == index 
                          ? const Color(0xFFDE0D0D) 
                          : Colors.grey[300]!,
                      width: _selectedVenueIndex == index ? 2 : 1,
                    ),
                  ),
                  elevation: 2,
                  color: Colors.white,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedVenueIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFDE0D0D).withOpacity(0.1),
                              border: Border.all(
                                color: const Color(0xFFDE0D0D),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                venue['initials'],
                                style: const TextStyle(
                                  color: Color(0xFFDE0D0D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venue['name'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  venue['location'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (venue['city'] != null && venue['city'].isNotEmpty)
                                  Text(
                                    '${venue['city']}, ${venue['state']}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          if (_selectedVenueIndex == index)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFDE0D0D),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDE0D0D),
                      side: const BorderSide(color: Color(0xFFDE0D0D)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedVenueIndex != -1
                        ? () {
                            setState(() {
                              _showVenueSelection = false;
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDE0D0D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreScreening() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showVenueSelection = true;
                    });
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
                const SizedBox(width: 16),
                const Text(
                  'Pre-Screening Request',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'IMPORTANT INFORMATION FOR BLOOD DONORS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Blood donation is a noble act that can save lives. By donating blood, you help provide life-saving assistance to others.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'As a donor, it is crucial to ensure that your blood is healthy and suitable for donation. Even if you feel fine, there may be times when your blood isn\'t ideal for donation due to the presence of viruses or other infectious agents. It\'s important to note that your blood could potentially harm those receiving it.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Before donating, you\'ll be required to answer a set of personal questions concerning your health, travel, and sexual history. This is necessary to confirm that you are fit to donate and that your blood does not carry any infectious diseases that might jeopardize the recipient\'s health. The blood bank counts on your honesty to ensure that the information provided during your donation interview is accurate.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Please remember to bring your blood donor card with you and present it when you arrive. Additionally, you will need to complete a pre-donation form before the donation process can proceed.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Your cooperation is essential for the safety of both you and the recipient. Thank you for your generosity and support.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Checkbox(
                  value: _agreementChecked,
                  onChanged: (value) {
                    setState(() {
                      _agreementChecked = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFDE0D0D),
                ),
                const Expanded(
                  child: Text(
                    'I have read and understand the information provided above.',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreementChecked
                    ? () {
                        setState(() {
                          _showQuestionnaire = true;
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaire() {
    Map<String, List<String>> relevantQuestions = _getRelevantQuestions();
    
    bool allAnswered = relevantQuestions.values
        .expand((questions) => questions)
        .every((question) => _answers[question] != null);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showQuestionnaire = false;
                    });
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
                const SizedBox(width: 16),
                const Text(
                  'Pre-Screening Questions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            ...relevantQuestions.entries.map((entry) {
              String category = entry.key;
              List<String> questions = entry.value;
              
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDE0D0D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...questions.asMap().entries.map((questionEntry) {
                        int questionIndex = questionEntry.key;
                        String question = questionEntry.value;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${questionIndex + 1}. $question',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildAnswerButton(question, true, 'Yes'),
                                  const SizedBox(width: 12),
                                  _buildAnswerButton(question, false, 'No'),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: allAnswered && !_isSubmitting
                    ? _submitQuestionnaire
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE0D0D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String question, bool value, String label) {
    bool isSelected = _answers[question] == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _answers[question] = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? const Color(0xFFDE0D0D).withOpacity(0.1) : Colors.white,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFDE0D0D) : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessPopup() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.5),
        ),
        
        Center(
          child: Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 280,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                  
                  const Text(
                    'Request Submitted',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  const Text(
                    'One step closer to saving lives. Thank you!',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  FutureBuilder(
                    future: Future.delayed(const Duration(seconds: 2)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Navigator.of(context).pop();
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