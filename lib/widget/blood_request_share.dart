import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart'; // Add to pubspec.yaml: share_plus: ^7.2.2

class BloodRequestShareHelper {
  // Generate share templates based on blood request data
  static List<Map<String, dynamic>> _generateShareTemplates(Map<String, dynamic> request) {
    final String bloodType = request['bloodType'] ?? 'Unknown';
    final String hospital = request['hospital'] ?? 'Hospital';
    final String patientName = request['patientName'] ?? 'Patient';
    final String shareLink = "bit.ly/help-${bloodType.toLowerCase()}";

    return [
      {
        'title': 'Urgent Appeal',
        'message': '🚨 URGENT: $bloodType blood donor needed!\n\n🏥 Hospital: $hospital\n👤 Patient: $patientName\n\n🩸 Your donation can save a life! Every share helps us find the right donor faster.\n\n📱 Help spread the word: $shareLink\n\n#SaveALife #BloodDonation #${bloodType}BloodNeeded #BloodConnect',
        'icon': Icons.warning_amber,
        'color': Color(0xFFFF5722),
      },
      {
        'title': 'Personal Appeal',
        'message': 'Hi friends! 💕\n\nA $bloodType blood donor is urgently needed at $hospital. Patient $patientName is counting on our community to help.\n\n🩸 If you\'re eligible to donate or know someone who is, please share this message. Every share could be the one that saves a life!\n\n📋 More info: $shareLink\n\n#CommunitySupport #BloodDonation #SaveLives',
        'icon': Icons.favorite,
        'color': Color(0xFFE91E63),
      },
      {
        'title': 'Community Call',
        'message': '🤝 Our community needs us!\n\n🩸 Blood Type Needed: $bloodType\n🏥 Location: $hospital\n⏰ Needed: ASAP\n\n💪 Together we can make a difference. If you can\'t donate, please share to help us reach someone who can.\n\n🔗 $shareLink\n\n#BloodConnect #CommunityHeroes #${bloodType}Donor #HelpSaveALife',
        'icon': Icons.people,
        'color': Color(0xFF4CAF50),
      },
      {
        'title': 'Simple Message',
        'message': '$bloodType blood donor needed at $hospital for $patientName.\n\nPlease share if you can help or know someone who might be able to donate.\n\n$shareLink\n\n#BloodDonation #$bloodType #SaveALife',
        'icon': Icons.bloodtype,
        'color': Color(0xFFDE0D0D),
      },
    ];
  }

  // Show native share picker for blood request
  static void showBloodRequestShareSheet(BuildContext context, Map<String, dynamic> request) {
    final templates = _generateShareTemplates(request);
    
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFFDE0D0D).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bloodtype,
                      color: Color(0xFFDE0D0D),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Blood Request',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${request['bloodType']} needed urgently',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
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
                        _shareBloodRequest(context, template['message']!);
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

  // Share blood request using native share sheet
  static void _shareBloodRequest(BuildContext context, String message) async {
    try {
      // Use share_plus for native sharing
      await Share.share(
        message,
        subject: 'Urgent: Blood Donor Needed - Please Help!',
      );

      // Optional: Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blood request shared successfully!'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
      
      // TODO: Add Firebase Analytics tracking
      // FirebaseAnalytics.instance.logEvent(
      //   name: 'share_blood_request',
      //   parameters: {
      //     'content_type': 'blood_request',
      //     'method': 'native_share',
      //   },
      // );
      
    } catch (e) {
      // Fallback to clipboard if sharing fails
      await Clipboard.setData(ClipboardData(text: message));
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