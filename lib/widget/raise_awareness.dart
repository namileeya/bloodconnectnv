import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// ignore: unused_import
import 'dart:io' show Platform;
// ignore: unused_import
import 'package:url_launcher/url_launcher.dart'; // Add to pubspec.yaml: url_launcher: ^6.2.1

class RaiseAwarenessHelper {
  // Share content templates
  static final List<Map<String, dynamic>> _shareTemplates = [
    {
      'title': 'General Awareness',
      'message': '🩸 Every 3 seconds, someone needs blood. Join me in making a difference with BloodConnect - the app that saves lives! \n\n💪 Connect with donors, find blood drives, and be part of a community that cares. Together, we can ensure no one waits for the blood they need.\n\n📱 Download BloodConnect today and become a hero in someone\'s story!\n\n#BloodConnect #SaveLives #BloodDonation #BeAHero',
      'icon': Icons.favorite,
      'color': Color(0xFFE91E63),
    },
    {
      'title': 'Emergency Appeal',
      'message': '🚨 URGENT: Blood shortages can happen anytime, anywhere. \n\n🩸 BloodConnect helps connect those in need with willing donors instantly. Don\'t wait for an emergency to act!\n\n✅ Register as a donor\n✅ Find nearby blood drives\n✅ Get notified when your blood type is needed\n\n📱 Join thousands who are already saving lives. Download BloodConnect now!\n\n#BloodEmergency #BloodConnect #DonateBlood #SaveLives',
      'icon': Icons.warning_amber,
      'color': Color(0xFFFF9800),
    },
    {
      'title': 'Community Impact',
      'message': '🌟 Amazing fact: 1 blood donation can save up to 3 lives! \n\n🤝 I\'m part of the BloodConnect community - a network of heroes making real impact. We\'re not just an app, we\'re a movement!\n\n💝 Features I love:\n• Real-time blood stock updates\n• Easy donor matching\n• Rewarding donation tracking\n• Supportive community\n\n🎯 Ready to make a difference? Join BloodConnect today!\n\n#CommunityHeroes #BloodConnect #MakeADifference #BloodDonors',
      'icon': Icons.people,
      'color': Color(0xFF4CAF50),
    },
    {
      'title': 'Personal Story',
      'message': '💭 Blood donation isn\'t just about giving - it\'s about hope, life, and community.\n\n🩸 BloodConnect has made it so easy for me to contribute meaningfully. From finding donation centers to connecting with other donors, this app is truly changing lives.\n\n🏆 Every donation matters. Every donor counts. Every life saved is priceless.\n\n📲 If you\'ve been thinking about donating, start with BloodConnect. It\'s your gateway to becoming someone\'s hero.\n\n#PersonalImpact #BloodConnect #GiveLife #BeTheChange',
      'icon': Icons.auto_stories,
      'color': Color(0xFF9C27B0),
    },
    {
      'title': 'Statistics & Facts',
      'message': '📊 Did you know?\n\n🩸 Only 3% of eligible people donate blood yearly\n⏰ Every 2 seconds someone needs a transfusion\n❤️ 1 donation = 3 lives saved\n🏥 Hospitals need 44,000 donations daily\n\n💡 BloodConnect is changing these numbers by making donation accessible, rewarding, and community-driven.\n\n🎯 Be part of the solution. Join our mission to ensure no one waits for life-saving blood.\n\n📱 Download BloodConnect - Where heroes connect!\n\n#BloodFacts #BloodConnect #DataDriven #SaveLives',
      'icon': Icons.analytics,
      'color': Color(0xFF2196F3),
    },
  ];

  // Show native share picker with awareness content options
  static void showRaiseAwarenessShareSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.campaign, color: Color(0xFFDE0D0D), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Raise Awareness',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Share options
            SizedBox(
              height: 280,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _shareTemplates.length,
                itemBuilder: (context, index) {
                  final template = _shareTemplates[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (template['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          template['icon'] as IconData,
                          color: template['color'] as Color,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        template['title']!,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        _getPreviewText(template['message']!),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Icon(Icons.share, size: 20, color: Color(0xFFDE0D0D)),
                      onTap: () {
                        Navigator.pop(context);
                        _shareContent(context, template['message']!);
                      },
                    ),
                  );
                },
              ),
            ),
            // Cancel button
            Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Share content using native share sheet with platform support
  static void _shareContent(BuildContext context, String message) async {
    try {
      const String appLink = 'https://bloodconnect.app'; // Replace with actual link
      final String completeMessage = '$message\n\n📥 Download: $appLink';
      
      // Use share_plus for native sharing - this will show all available apps
      final result = await Share.shareWithResult(
        completeMessage,
        subject: 'Join BloodConnect - Save Lives Together!',
      );

      // Check if sharing was successful
      if (result.status == ShareResultStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared successfully!'),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // TODO: Add Firebase Analytics tracking
      // FirebaseAnalytics.instance.logEvent(
      //   name: 'share_awareness_content',
      //   parameters: {
      //     'content_type': 'raise_awareness',
      //     'method': 'native_share',
      //   },
      // );
      
    } catch (e) {
      // Fallback to clipboard if sharing fails
      await Clipboard.setData(ClipboardData(text: '$message\n\n📥 Download: https://bloodconnect.app'));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied to clipboard! Share it anywhere you like.'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  static String _getPreviewText(String message) {
    // Remove emojis and get first line for preview
    final lines = message.split('\n');
    String firstLine = lines[0].replaceAll(RegExp(r'[^\w\s]+'), '');
    if (firstLine.isEmpty && lines.length > 1) {
      firstLine = lines[1].replaceAll(RegExp(r'[^\w\s]+'), '');
    }
    return firstLine.trim();
  }
}

/*
===========================================
SETUP INSTRUCTIONS:
===========================================

1. Add dependency to pubspec.yaml:
   dependencies:
     share_plus: ^7.2.2

2. The native share sheet will automatically show all installed apps 
   that support sharing (WhatsApp, Facebook, Twitter, Instagram, Telegram, 
   Messages, Email, etc.)

3. No additional configuration needed! The share_plus package handles
   everything automatically.

4. Usage in your HomePage:
   InkWell(
     onTap: () {
       RaiseAwarenessHelper.showRaiseAwarenessShareSheet(context);
     },
     child: Column(
       mainAxisAlignment: MainAxisAlignment.center,
       mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           width: 54,
           height: 54,
           decoration: BoxDecoration(
             color: const Color(0xFFDE0D0D).withOpacity(0.1),
             borderRadius: BorderRadius.circular(12),
           ),
           child: const Center(
             child: Icon(
               Icons.campaign,
               color: Color(0xFFDE0D0D),
               size: 26,
             ),
           ),
         ),
         const SizedBox(height: 6),
         const Text(
           'Raise\nAwareness',
           style: TextStyle(
             fontSize: 10,
             fontWeight: FontWeight.bold,
           ),
           textAlign: TextAlign.center,
         ),
       ],
     ),
   ),

NOTE: The share_plus package will automatically display the native 
system share sheet with all available apps (WhatsApp, Facebook, Twitter,
Instagram, Telegram, Messages, Email, etc.). Users can choose which 
app to share to from their device's native share menu.
*/