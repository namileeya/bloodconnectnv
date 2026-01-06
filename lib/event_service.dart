import 'package:cloud_firestore/cloud_firestore.dart';

class EventService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'blood_drive_events';

  static Future<List<Map<String, dynamic>>> getUpcomingEvents() async {
    try {
      // Fetch all events ordered by startDate
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('startDate')
          .get();

      // Filter events that are today or in the future
      final now = DateTime.now();
      final upcomingEvents = snapshot.docs.where((doc) {
        final data = doc.data();
        final startDateStr = data['startDate'] as String?;
        
        if (startDateStr == null || startDateStr.isEmpty) return false;
        
        try {
          // Parse DD/MM/YYYY format
          final parts = startDateStr.split('/');
          if (parts.length != 3) return false;
          
          final day = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final year = int.parse(parts[2]);
          
          final eventDate = DateTime(year, month, day);
          final today = DateTime(now.year, now.month, now.day);
          
          // Return true if event is today or in the future
          return eventDate.isAfter(today.subtract(const Duration(days: 1)));
        } catch (e) {
          print('Error parsing date $startDateStr: $e');
          return false;
        }
      }).toList();

      // Limit to 5 events for display
      final limitedEvents = upcomingEvents.take(5).toList();

      // Convert to List<Map<String, dynamic>> and add display fields
      return limitedEvents.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['displayDate'] = data['startDate'];
        data['displayTime'] = '${data['startTime']} - ${data['endTime']}';
        data['organizers'] = data['organizerName'] ?? 'Unknown Organizer';
        return data;
      }).toList();
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }
}