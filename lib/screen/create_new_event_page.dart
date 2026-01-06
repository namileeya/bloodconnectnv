import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/header.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import 'package:bloodconnect/user_session.dart';

class CreateNewEventPage extends StatefulWidget {
  const CreateNewEventPage({super.key});

  @override
  State<CreateNewEventPage> createState() => _CreateNewEventPageState();
}

class _CreateNewEventPageState extends State<CreateNewEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _organizerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _showSuccessDialog = false;
  bool _isLoading = true;
  
  // User data from session
  String? _fullName;
  String? _phoneNumber;
  String? _userId;
  
  // Hospital data
  List<Map<String, dynamic>> _hospitals = [];
  String? _selectedHospitalId;
  String? _selectedHospitalName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadHospitals();
  }

  // Load user data from session
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data from UserSession
      final userData = await UserSession.getUser();
      
      if (userData == null) {
        throw Exception('No user data found');
      }
      
      setState(() {
        _fullName = userData['full_name'];
        _phoneNumber = userData['phone_number'];
        _userId = userData['user_id'];
        
        // Pre-fill organizer fields with user data
        if (_fullName != null) {
          _organizerNameController.text = _fullName!;
        }
        if (_phoneNumber != null) {
          _contactNumberController.text = _phoneNumber!;
        }
      });
    } catch (e) {
      print('Error loading user data: $e');
      
      // Show error dialog
      if (mounted) {
        _showErrorDialog('Failed to load user data. Please try again.');
      }
    }
  }

  // Load hospitals from Firestore
  Future<void> _loadHospitals() async {
    try {
      final querySnapshot = await _firestore
          .collection('hospitals')
          .orderBy('name')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('No hospitals found in database');
        if (mounted) {
          setState(() {
            _hospitals = [];
            _isLoading = false;
          });
        }
        return;
      }

      final hospitalsList = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'address': data['address'] ?? '',
          'city': data['city'] ?? '',
          'state': data['state'] ?? '',
          'initials': data['initials'] ?? '',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _hospitals = hospitalsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading hospitals: $e');
      if (mounted) {
        setState(() {
          _hospitals = [];
          _isLoading = false;
        });
        _showErrorDialog('Failed to load hospitals. Please try again.');
      }
    }
  }

  // Get user initials from full name
  String _getUserInitials() {
    if (_fullName == null || _fullName!.isEmpty) return 'U';
    
    List<String> nameParts = _fullName!.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  void _updateNavIndex(int index) {
    // Required by NavigationHelper
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _descriptionController.dispose();
    _organizerNameController.dispose();
    _contactNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFDE0D0D),
            colorScheme: ColorScheme.light(
              primary: Color(0xFFDE0D0D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        controller.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Color(0xFFDE0D0D),
            colorScheme: ColorScheme.light(
              primary: Color(0xFFDE0D0D),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogTheme: DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
        final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
        controller.text = '${hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
      });
    }
  }

  // Validate form fields
  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an event title');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an event location');
      return false;
    }
    if (_selectedHospitalId == null || _selectedHospitalName == null || _selectedHospitalName!.isEmpty) {
      _showErrorDialog('Please select a destination hospital');
      return false;
    }
    if (_startDateController.text.trim().isEmpty) {
      _showErrorDialog('Please select a start date');
      return false;
    }
    if (_endDateController.text.trim().isEmpty) {
      _showErrorDialog('Please select an end date');
      return false;
    }
    if (_startTimeController.text.trim().isEmpty) {
      _showErrorDialog('Please select a start time');
      return false;
    }
    if (_endTimeController.text.trim().isEmpty) {
      _showErrorDialog('Please select an end time');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a description');
      return false;
    }
    if (_organizerNameController.text.trim().isEmpty) {
      _showErrorDialog('Please enter organizer name');
      return false;
    }
    if (_contactNumberController.text.trim().isEmpty) {
      _showErrorDialog('Please enter contact number');
      return false;
    }
    if (_capacityController.text.trim().isEmpty) {
      _showErrorDialog('Please enter expected capacity');
      return false;
    }
    
    // Validate capacity is a number
    if (int.tryParse(_capacityController.text.trim()) == null) {
      _showErrorDialog('Capacity must be a valid number');
      return false;
    }
    
    return true;
  }

  // Create event and save to Firestore
  Future<void> _createEvent() async {
    if (!_validateForm()) {
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDE0D0D)),
          ),
        );
      },
    );

    try {
      // Prepare event data for Firestore
      final eventData = {
        'title': _titleController.text.trim(),
        'location': _locationController.text.trim(),
        'assignedHospitalName': _selectedHospitalName,
        'startDate': _startDateController.text.trim(),
        'endDate': _endDateController.text.trim(),
        'startTime': _startTimeController.text.trim(),
        'endTime': _endTimeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'organizerName': _organizerNameController.text.trim(),
        'contactNumber': _contactNumberController.text.trim(),
        'expectedCapacity': int.parse(_capacityController.text.trim()),
        'currentParticipants': 0, // Initialize with 0 participants
        'createdBy': _userId,
        'createdAt': FieldValue.serverTimestamp(), // Use server timestamp
        'status': 'submitted', // Status: submitted (waiting for admin approval), approved, rejected, completed, cancelled
        'locationHospitalId': _selectedHospitalId,
        'locationHospitalName': _selectedHospitalName,
        'locationType': 'other',
      };

      // Save to Firestore collection 'blood_drive_events'
      await _firestore.collection('blood_drive_events').add(eventData);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success dialog
      setState(() {
        _showSuccessDialog = true;
      });
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      print('Error creating event: $e');
      _showErrorDialog('Failed to create event. Please try again.\n\nError: ${e.toString()}');
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFFDE0D0D)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Success Popup
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
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              width: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green,
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check,
                        color: Colors.green,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Event Created Successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
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

  @override
  Widget build(BuildContext context) {
    // Show loading screen while fetching user data and hospitals
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDE0D0D)),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.grey[50],
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
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Create a New Blood Drive Event',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Fill out the details below to create a new blood donation event.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Event Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Text(
                            'Event Title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              hintText: 'Enter Title',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _locationController,
                            decoration: InputDecoration(
                              hintText: 'Enter Event Location',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Destination Hospital Dropdown
                          Text(
                            'Destination Hospital',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _selectedHospitalId,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  hintText: 'Select a hospital',
                                ),
                                items: _hospitals.map((hospital) {
                                  return DropdownMenuItem<String>(
                                    value: hospital['id'],
                                    child: Text(
                                      hospital['name'],
                                      style: TextStyle(fontSize: 14.5),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedHospitalId = value;
                                    if (value != null) {
                                      final selectedHospital = _hospitals.firstWhere(
                                        (hospital) => hospital['id'] == value,
                                        orElse: () => {},
                                      );
                                      _selectedHospitalName = selectedHospital['name'];
                                    } else {
                                      _selectedHospitalName = null;
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a hospital';
                                  }
                                  return null;
                                },
                                isExpanded: true,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hospital where collected blood will be sent',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _startDateController,
                                      decoration: InputDecoration(
                                        hintText: 'DD/MM/YYYY',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.calendar_today, color: Colors.grey),
                                          onPressed: () => _selectDate(context, _startDateController),
                                        ),
                                        hintStyle: TextStyle(fontSize: 14.5),
                                      ),
                                      style: TextStyle(fontSize: 14.5),
                                      readOnly: true,
                                      onTap: () => _selectDate(context, _startDateController),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _endDateController,
                                      decoration: InputDecoration(
                                        hintText: 'DD/MM/YYYY',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.calendar_today, color: Colors.grey),
                                          onPressed: () => _selectDate(context, _endDateController),
                                        ),
                                        hintStyle: TextStyle(fontSize: 14.5),
                                      ),
                                      style: TextStyle(fontSize: 14.5),
                                      readOnly: true,
                                      onTap: () => _selectDate(context, _endDateController),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _startTimeController,
                                      decoration: InputDecoration(
                                        hintText: 'HH:MM AM/PM',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.access_time, color: Colors.grey),
                                          onPressed: () => _selectTime(context, _startTimeController),
                                        ),
                                        hintStyle: TextStyle(fontSize: 14.5),
                                      ),
                                      style: TextStyle(fontSize: 14.5),
                                      readOnly: true,
                                      onTap: () => _selectTime(context, _startTimeController),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    TextField(
                                      controller: _endTimeController,
                                      decoration: InputDecoration(
                                        hintText: 'HH:MM AM/PM',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        suffixIcon: IconButton(
                                          icon: Icon(Icons.access_time, color: Colors.grey),
                                          onPressed: () => _selectTime(context, _endTimeController),
                                        ),
                                        hintStyle: TextStyle(fontSize: 14.5),
                                      ),
                                      style: TextStyle(fontSize: 14.5),
                                      readOnly: true,
                                      onTap: () => _selectTime(context, _endTimeController),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Provide details about the event',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          Divider(),
                          SizedBox(height: 20),
                          
                          Text(
                            'Organizer Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          Text(
                            'Organizer Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _organizerNameController,
                            decoration: InputDecoration(
                              hintText: 'Enter Organizer Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Text(
                            'Contact Number',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _contactNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter Contact Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          Text(
                            'Expected Capacity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _capacityController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter Expected Capacity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Approximate number of donors you expect to accommodate.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createEvent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDE0D0D),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Create Event',
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
            ),
          ),
          bottomNavigationBar: CustomBottomNavigationBar(
            currentIndex: -1,
            onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
          ),
        ),
        if (_showSuccessDialog)
          _buildSuccessPopup(),
      ],
    );
  }
}