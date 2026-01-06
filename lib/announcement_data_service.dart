import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'announcements';

  static Future<List<Map<String, dynamic>>> getActiveAnnouncements() async {
    try {
      print('🔍 Fetching announcements from collection: $collectionName');
      
      // Try with NO status filter first
      final snapshot = await _firestore
          .collection(collectionName)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      print('📊 Found ${snapshot.docs.length} announcements');
      
      // Print each announcement for debugging
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📋 Announcement ID: ${doc.id}');
        print('   Title: ${data['title']}');
        print('   Status: ${data['status']}');
        print('   Content: ${data['content']}');
        print('   Date: ${data['date']}');
        print('   ---');
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('❌ Error fetching announcements: $e');
      print('❌ Error details: ${e.toString()}');
      return [];
    }
  }
}