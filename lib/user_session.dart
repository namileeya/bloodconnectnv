import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserSession {
  // Save user data
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(userData));
  }
  
  // Get user data
  static Future<Map<String, dynamic>?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('user_data');
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    Map<String, dynamic>? user = await getUser();
    return user != null;
  }
  
  // Logout (clear session)
  static Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

// In your user_session.dart file, add this method:
static Future<void> clearUser() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_data'); // or whatever key you use to store user data
}

}