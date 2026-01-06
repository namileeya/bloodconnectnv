import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'donation_confirmation_page.dart';
import 'notification_page.dart';
import 'myreward_page.dart';
import '../widget/bottom_navigation_bar.dart';
import '../navigation_helper.dart';
import '../widget/header.dart';
import 'package:bloodconnect/user_session.dart';

class DonationDatePage extends StatefulWidget {
  final String hospitalId;
  final String selectedCenter;
  final String selectedAddress;
  final String officeStartTime;
  final String officeEndTime;

  const DonationDatePage({
    super.key,
    required this.hospitalId,
    required this.selectedCenter,
    required this.selectedAddress,
    required this.officeStartTime,
    required this.officeEndTime,
  });

  @override
  State<DonationDatePage> createState() => _DonationDatePageState();
}

class _DonationDatePageState extends State<DonationDatePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final int _currentStep = 2;
  String fullName = "User";
  
  // Selected date and time
  DateTime? _selectedDate;
  String? _selectedTime;
  
  // Current month and year for calendar
  late DateTime _currentMonth;
  
  // Track selected index for bottom nav bar
  int _selectedNavIndex = 2;
  
  // Generated time slots
  List<String> _timeSlots = [];
  
  // Existing appointment check
  bool _hasAppointmentOnSelectedDate = false;
  bool _isCheckingAppointment = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _generateTimeSlots();
    _loadUserProfile();
  }

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Load user profile
  Future<void> _loadUserProfile() async {
    try {
      // Try to get from session first
      final userData = await UserSession.getUser();
      if (userData != null && userData['fullName'] != null) {
        setState(() {
          fullName = userData['fullName'];
        });
        return;
      }

      // If not in session, fetch from Firestore
      if (_currentUserId != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .get();
        
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            fullName = data['fullName'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        fullName = 'User';
      });
    }
  }

  // Generate time slots based on office hours
  void _generateTimeSlots() {
    List<String> slots = [];
    
    try {
      final startParts = widget.officeStartTime.split(':');
      final endParts = widget.officeEndTime.split(':');
      
      int startHour = int.parse(startParts[0]);
      int startMinute = int.parse(startParts[1]);
      int endHour = int.parse(endParts[0]);
      int endMinute = int.parse(endParts[1]);
      
      // Convert to minutes for easier calculation
      int currentMinutes = startHour * 60 + startMinute;
      int endMinutes = endHour * 60 + endMinute;
      
      // Generate slots every 30 minutes
      while (currentMinutes < endMinutes) {
        int hour = currentMinutes ~/ 60;
        int minute = currentMinutes % 60;
        
        String timeSlot = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        slots.add(timeSlot);
        
        currentMinutes += 30; // 30-minute intervals
      }
      
      setState(() {
        _timeSlots = slots;
      });
    } catch (e) {
      print('Error generating time slots: $e');
      // Fallback to default slots if parsing fails
      setState(() {
        _timeSlots = [
          '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
          '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
          '16:00', '16:30'
        ];
      });
    }
  }

  // Check if user already has an appointment on selected date
  Future<void> _checkExistingAppointment(DateTime date) async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isCheckingAppointment = true;
    });
    
    try {
      // Create start and end of the selected day
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // Query appointments for this user, hospital, and date
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('userId', isEqualTo: _currentUserId)
          .where('hospitalId', isEqualTo: widget.hospitalId)
          .where('appointmentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('appointmentDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();
      
      setState(() {
        _hasAppointmentOnSelectedDate = querySnapshot.docs.isNotEmpty;
        _isCheckingAppointment = false;
        
        // Clear selected time if appointment exists
        if (_hasAppointmentOnSelectedDate) {
          _selectedTime = null;
        }
      });
    } catch (e) {
      print('Error checking existing appointment: $e');
      setState(() {
        _isCheckingAppointment = false;
      });
    }
  }

  // Get user initials from full name
  String _getUserInitials() {
    List<String> nameParts = fullName.trim().split(' ');
    
    if (nameParts.isEmpty) return 'U';
    
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    
    String firstInitial = nameParts.first.substring(0, 1).toUpperCase();
    String lastInitial = nameParts.last.substring(0, 1).toUpperCase();
    
    return '$firstInitial$lastInitial';
  }

  // Check if date is a weekend (Saturday or Sunday)
  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  // Check if date is in the past
  bool _isPastDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  // Check if time slot is in the past (for today's date)
  bool _isPastTimeSlot(String timeSlot) {
    if (_selectedDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
    
    // Only check if selected date is today
    if (selectedDay.isAtSameMomentAs(today)) {
      final timeParts = timeSlot.split(':');
      final slotHour = int.parse(timeParts[0]);
      final slotMinute = int.parse(timeParts[1]);
      
      final slotTime = DateTime(now.year, now.month, now.day, slotHour, slotMinute);
      return slotTime.isBefore(now);
    }
    
    return false;
  }

  // Simplified navigation handler
  void _updateNavIndex(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book Appointment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              
              _buildDateTimeSelection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => NavigationHelper.handleNavigation(context, index, _updateNavIndex),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStepIndicator(1, 'Location', isPast: true),
        Expanded(
          child: Container(
            height: 2,
            color: const Color(0xFFDE0D0D),
          ),
        ),
        _buildStepIndicator(2, 'Date'),
        Expanded(
          child: Container(
            height: 2,
            color: Colors.grey[300],
          ),
        ),
        _buildStepIndicator(3, 'Confirmation', isActive: false),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label, {bool isPast = false, bool isActive = true}) {
    final bool isCurrent = step == _currentStep;
    
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isPast 
                ? Colors.red 
                : (isCurrent ? const Color(0xFFDE0D0D) : Colors.grey[300]),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isPast || isCurrent ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date and Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Selected donation center info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.selectedCenter,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.selectedAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        const Text(
          'Select Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildCalendar(),
        const SizedBox(height: 20),
        
        const Text(
          'Select Time',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show message if checking appointment or if appointment exists
        if (_isCheckingAppointment)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDE0D0D),
              ),
            ),
          )
        else if (_hasAppointmentOnSelectedDate)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You already have an appointment at this hospital on this date.',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        _buildTimeSlots(),
        const SizedBox(height: 40),
        
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildCalendar() {
    final DateTime firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final int firstDayIndex = firstDayOfMonth.weekday % 7;
    final int daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final int daysInPreviousMonth = DateTime(_currentMonth.year, _currentMonth.month, 0).day;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month - 1,
                    );
                  });
                },
              ),
              Text(
                '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _currentMonth = DateTime(
                      _currentMonth.year,
                      _currentMonth.month + 1,
                    );
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Days of week
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text('Sun', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Mon', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Tue', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Wed', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Thu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Fri', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Text('Sat', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.2,
              crossAxisSpacing: 0,
              mainAxisSpacing: 0,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              int day = index - firstDayIndex;
              
              // Previous month days
              if (day < 0) {
                int prevMonthDay = daysInPreviousMonth + day + 1;
                return Center(
                  child: Text(
                    prevMonthDay.toString(),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                );
              }
              
              // Current month days
              else if (day < daysInMonth) {
                day = day + 1;
                final DateTime currentDate = DateTime(_currentMonth.year, _currentMonth.month, day);
                final bool isSelected = _selectedDate?.day == day && 
                                       _selectedDate?.month == _currentMonth.month &&
                                       _selectedDate?.year == _currentMonth.year;
                
                final DateTime now = DateTime.now();
                final bool isToday = day == now.day && 
                                     now.month == _currentMonth.month &&
                                     now.year == _currentMonth.year;
                
                final bool isWeekend = _isWeekend(currentDate);
                final bool isPast = _isPastDate(currentDate);
                final bool isDisabled = isWeekend || isPast;
                
                return GestureDetector(
                  onTap: isDisabled ? null : () {
                    setState(() {
                      _selectedDate = currentDate;
                      _selectedTime = null; // Clear selected time when date changes
                    });
                    _checkExistingAppointment(currentDate);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFFDE0D0D) 
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        day.toString(),
                        style: TextStyle(
                          color: isSelected 
                              ? Colors.white 
                              : (isDisabled ? Colors.grey[400] : Colors.black),
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                          decoration: isDisabled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              // Next month days
              else {
                int nextMonthDay = day - daysInMonth + 1;
                return Center(
                  child: Text(
                    nextMonthDay.toString(),
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 14,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildTimeSlots() {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: _timeSlots.map((time) => _buildTimeSlot(time)).toList(),
    );
  }

  Widget _buildTimeSlot(String time) {
    final bool isSelected = _selectedTime == time;
    final bool isPast = _isPastTimeSlot(time);
    final bool isDisabled = _selectedDate == null || 
                           _hasAppointmentOnSelectedDate || 
                           isPast;
    
    return GestureDetector(
      onTap: isDisabled ? null : () {
        setState(() {
          _selectedTime = time;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width - 64) / 4,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFDE0D0D) 
              : (isDisabled ? Colors.grey[200] : Colors.white),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFDE0D0D) 
                : (isDisabled ? Colors.grey[300]! : Colors.grey.shade300),
          ),
        ),
        child: Center(
          child: Text(
            time,
            style: TextStyle(
              color: isSelected 
                  ? Colors.white 
                  : (isDisabled ? Colors.grey[400] : Colors.black),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Back',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedDate != null && _selectedTime != null 
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DonationConfirmationPage(
                        hospitalId: widget.hospitalId,
                        selectedCenter: widget.selectedCenter,
                        selectedAddress: widget.selectedAddress,
                        selectedDate: _selectedDate!,
                        selectedTime: _selectedTime!,
                      ),
                    ),
                  );
                }
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDE0D0D),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _selectedDate != null && _selectedTime != null 
                      ? Colors.white 
                      : Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}