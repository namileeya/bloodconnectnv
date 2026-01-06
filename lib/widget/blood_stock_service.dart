// blood_stock_service.dart

class BloodStockService {
  // Sample data - replace with Firebase integration later
  static final Map<String, Map<String, dynamic>> _bloodStockData = {
    'National Blood Center': {
      'location_id': 'nbc_kl',
      'location_name': 'National Blood Center',
      'address': 'Kuala Lumpur',
      'last_updated': '2025-01-22T10:30:00Z',
      'blood_types': {
        'O-': {'status': 'Full', 'units': 150, 'percentage': 85},
        'O+': {'status': 'Medium', 'units': 89, 'percentage': 65},
        'A-': {'status': 'Low', 'units': 25, 'percentage': 25},
        'A+': {'status': 'Low', 'units': 32, 'percentage': 30},
        'B-': {'status': 'Medium', 'units': 67, 'percentage': 55},
        'B+': {'status': 'Low', 'units': 28, 'percentage': 28},
        'AB-': {'status': 'Low', 'units': 18, 'percentage': 20},
        'AB+': {'status': 'Medium', 'units': 45, 'percentage': 50},
      }
    },
    'Hospital Kuala Lumpur': {
      'location_id': 'hkl',
      'location_name': 'Hospital Kuala Lumpur',
      'address': 'Kuala Lumpur',
      'last_updated': '2025-01-22T09:45:00Z',
      'blood_types': {
        'O-': {'status': 'Medium', 'units': 78, 'percentage': 60},
        'O+': {'status': 'Full', 'units': 142, 'percentage': 90},
        'A-': {'status': 'Low', 'units': 19, 'percentage': 22},
        'A+': {'status': 'Medium', 'units': 65, 'percentage': 58},
        'B-': {'status': 'Low', 'units': 23, 'percentage': 25},
        'B+': {'status': 'Medium', 'units': 71, 'percentage': 62},
        'AB-': {'status': 'Low', 'units': 12, 'percentage': 15},
        'AB+': {'status': 'Full', 'units': 89, 'percentage': 85},
      }
    },
    'Hospital Serdang': {
      'location_id': 'hs_serdang',
      'location_name': 'Hospital Serdang',
      'address': 'Selangor',
      'last_updated': '2025-01-22T11:15:00Z',
      'blood_types': {
        'O-': {'status': 'Low', 'units': 31, 'percentage': 35},
        'O+': {'status': 'Medium', 'units': 94, 'percentage': 68},
        'A-': {'status': 'Medium', 'units': 56, 'percentage': 52},
        'A+': {'status': 'Full', 'units': 128, 'percentage': 88},
        'B-': {'status': 'Low', 'units': 22, 'percentage': 24},
        'B+': {'status': 'Full', 'units': 115, 'percentage': 92},
        'AB-': {'status': 'Medium', 'units': 41, 'percentage': 45},
        'AB+': {'status': 'Low', 'units': 29, 'percentage': 32},
      }
    },
    'Hospital Sultanah Aminah': {
      'location_id': 'hsa_jb',
      'location_name': 'Hospital Sultanah Aminah',
      'address': 'Johor Bahru',
      'last_updated': '2025-01-22T08:20:00Z',
      'blood_types': {
        'O-': {'status': 'Medium', 'units': 67, 'percentage': 58},
        'O+': {'status': 'Low', 'units': 38, 'percentage': 33},
        'A-': {'status': 'Full', 'units': 98, 'percentage': 82},
        'A+': {'status': 'Medium', 'units': 73, 'percentage': 64},
        'B-': {'status': 'Full', 'units': 87, 'percentage': 78},
        'B+': {'status': 'Medium', 'units': 52, 'percentage': 48},
        'AB-': {'status': 'Low', 'units': 16, 'percentage': 18},
        'AB+': {'status': 'Full', 'units': 104, 'percentage': 86},
      }
    },
  };

  // Get all available locations
  static List<String> getAvailableLocations() {
    return _bloodStockData.keys.toList();
  }

  // Get blood stock data for a specific location
  static Map<String, dynamic>? getBloodStockByLocation(String locationName) {
    return _bloodStockData[locationName];
  }

  // Get all blood stock data
  static Map<String, Map<String, dynamic>> getAllBloodStock() {
    return _bloodStockData;
  }

  // Helper method to get status color
  static String getStatusImage(String status) {
    switch (status.toLowerCase()) {
      case 'low':
        return 'assets/low.png';
      case 'medium':
        return 'assets/medium.png';
      case 'full':
      case 'high':
        return 'assets/high.png';
      default:
        return 'assets/medium.png';
    }
  }

  // Helper method to get status color for text
  static String getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'low':
        return 'red';
      case 'medium':
        return 'orange';
      case 'full':
      case 'high':
        return 'green';
      default:
        return 'orange';
    }
  }

  // Future method for Firebase integration (placeholder)
  // static Future<Map<String, dynamic>?> fetchBloodStockFromFirebase(String locationId) async {
  //   // TODO: Implement Firebase fetch logic
  //   // FirebaseFirestore firestore = FirebaseFirestore.instance;
  //   // DocumentSnapshot doc = await firestore.collection('blood_stock').doc(locationId).get();
  //   // return doc.data() as Map<String, dynamic>?;
  //   return null;
  // }

  // Future method for updating Firebase (placeholder)
  // static Future<void> updateBloodStockInFirebase(String locationId, Map<String, dynamic> data) async {
  //   // TODO: Implement Firebase update logic
  //   // FirebaseFirestore firestore = FirebaseFirestore.instance;
  //   // await firestore.collection('blood_stock').doc(locationId).update(data);
  // }
}