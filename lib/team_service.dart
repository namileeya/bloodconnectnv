import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // ADD THIS IMPORT FOR IconData

class TeamService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'teams';

  static Future<List<Map<String, dynamic>>> getActiveTeams() async {
  try {
    final snapshot = await _firestore
        .collection(collectionName)
        .orderBy('memberCount', descending: true)
        .limit(8)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      data['icon'] = _getTeamIcon(data['name']);
      return data;
    }).toList();
  } catch (e) {
    print('Error fetching teams: $e');
    return [];
  }
}

  static IconData _getTeamIcon(String teamName) {
    if (teamName.toLowerCase().contains('warrior')) return Icons.favorite;
    if (teamName.toLowerCase().contains('positive')) return Icons.add_circle;
    if (teamName.toLowerCase().contains('hero')) return Icons.star;
    if (teamName.toLowerCase().contains('champion')) return Icons.emoji_events;
    if (teamName.toLowerCase().contains('donor')) return Icons.people;
    if (teamName.toLowerCase().contains('blood')) return Icons.water_drop;
    return Icons.group; // Default icon
  }
}