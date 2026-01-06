import 'package:cloud_firestore/cloud_firestore.dart';

class BloodStockService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Main collection is now 'hospitals' instead of 'blood_stock'
  static const String HOSPITALS_COLLECTION = 'hospitals';
  static const String BLOOD_STOCK_SUBCOLLECTION = 'bloodStock';
  
  /// Fetch all available hospitals from Firebase
  /// Returns the display names (e.g., "Pusat Darah Negara")
  static Future<List<String>> getAvailableLocations() async {
    try {
      print('🔍 Fetching hospitals from $HOSPITALS_COLLECTION collection...');
      
      final querySnapshot = await _firestore.collection(HOSPITALS_COLLECTION).get();
      print('📄 Hospitals found: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isEmpty) {
        print('⚠️ No hospitals in $HOSPITALS_COLLECTION collection');
        return [];
      }
      
      // Extract hospital names from the 'name' field
      final List<String> locations = [];
      for (var doc in querySnapshot.docs) {
        print('   📄 Hospital ID: ${doc.id}');
        final data = doc.data();
        print('   📊 Hospital data keys: ${data.keys.toList()}');
        
        if (data.containsKey('name')) {
          final hospitalName = data['name'] as String;
          locations.add(hospitalName);
          print('   ✓ Found hospital: $hospitalName (ID: ${doc.id})');
        } else {
          print('   ⚠️ Hospital ${doc.id} missing "name" field');
          // Fallback: use document ID if name field doesn't exist
          locations.add(doc.id);
        }
      }
      
      print('✅ Successfully found ${locations.length} hospitals: $locations');
      return locations;
      
    } catch (e, stackTrace) {
      print('❌ Error fetching hospitals: $e');
      print('Stack trace: $stackTrace');
      
      if (e.toString().contains('permission-denied')) {
        print('⚠️ PERMISSION DENIED: Check Firebase Security Rules!');
      }
      
      return [];
    }
  }
  
  /// Get hospital document ID by name
  static Future<String?> getHospitalIdByName(String hospitalName) async {
    try {
      final querySnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .where('name', isEqualTo: hospitalName)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print('❌ Error getting hospital ID: $e');
      return null;
    }
  }
  
  /// Get hospital data by name
  static Future<Map<String, dynamic>?> getHospitalData(String hospitalName) async {
    try {
      final querySnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .where('name', isEqualTo: hospitalName)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      print('❌ Error getting hospital data: $e');
      return null;
    }
  }
  
  /// Fetch blood stock data for a specific hospital
  /// @param hospitalName - The hospital name (e.g., "Pusat Darah Negara")
  static Future<Map<String, dynamic>?> getBloodStockByLocation(String hospitalName) async {
    try {
      print('🩸 Fetching blood stock for hospital: "$hospitalName"');
      
      // First, get the hospital ID
      final hospitalId = await getHospitalIdByName(hospitalName);
      if (hospitalId == null) {
        print('⚠️ Hospital not found: "$hospitalName"');
        return null;
      }
      
      print('   Found hospital ID: $hospitalId');
      
      // Get hospital details
      final hospitalData = await getHospitalData(hospitalName);
      if (hospitalData == null) {
        print('⚠️ Could not fetch hospital details');
        return null;
      }
      
      // Get all blood stock documents from the subcollection
      final bloodStockSnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .doc(hospitalId)
          .collection(BLOOD_STOCK_SUBCOLLECTION)
          .get();
      
      if (bloodStockSnapshot.docs.isEmpty) {
        print('⚠️ No blood stock data found for hospital: "$hospitalName"');
        return null;
      }
      
      print('📊 Found ${bloodStockSnapshot.docs.length} blood types');
      
      // Format the data
      return _formatBloodStockData(
        hospitalName: hospitalName,
        hospitalData: hospitalData,
        bloodStockDocs: bloodStockSnapshot.docs,
      );
      
    } catch (e, stackTrace) {
      print('❌ Error fetching blood stock: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }
  
  /// Helper method to format blood stock data
  static Map<String, dynamic> _formatBloodStockData({
    required String hospitalName,
    required Map<String, dynamic> hospitalData,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bloodStockDocs,
  }) {
    final Map<String, dynamic> bloodTypesFormatted = {};
    Timestamp? latestUpdate;
    
    print('📊 Starting _formatBloodStockData with ${bloodStockDocs.length} documents');
    
    // Process each blood type document
    for (var doc in bloodStockDocs) {
      final bloodTypeData = doc.data();
      final bloodType = bloodTypeData['bloodType']?.toString() ?? 'Unknown';
      
      print('   Processing $bloodType...');
      print('   Raw document data: $bloodTypeData');
      
      // Get last updated timestamp
      final lastUpdated = bloodTypeData['lastUpdated'] as Timestamp?;
      if (lastUpdated != null) {
        if (latestUpdate == null || lastUpdated.millisecondsSinceEpoch > latestUpdate.millisecondsSinceEpoch) {
          latestUpdate = lastUpdated;
        }
      }
      
      // Get quantity - ensure it's converted to int
      final quantity = (bloodTypeData['quantity'] as num?)?.toInt() ?? 0;
      
      // Get thresholds
      final thresholds = bloodTypeData['thresholds'] as Map<String, dynamic>? ?? {};
      final highThreshold = (thresholds['high'] as num?)?.toInt() ?? 50;
      final mediumThreshold = (thresholds['medium'] as num?)?.toInt() ?? 30;
      final lowThreshold = (thresholds['low'] as num?)?.toInt() ?? 10;
      
      // DEBUG: Print thresholds and quantity
      print('     DEBUG: Quantity = $quantity');
      print('     DEBUG: Thresholds: low=$lowThreshold, medium=$mediumThreshold, high=$highThreshold');
      
      // Get the stored status from database for comparison
      final storedStatus = bloodTypeData['status'] as String? ?? 'unknown';
      print('     DEBUG: Stored status in DB: $storedStatus');
      
      // Calculate status based on quantity and thresholds
      String calculatedStatus;
      if (quantity == 0) {
        calculatedStatus = 'empty';
      } else if (quantity >= highThreshold) {
        calculatedStatus = 'high';
      } else if (quantity >= mediumThreshold) {
        calculatedStatus = 'medium';
      } else if (quantity >= lowThreshold) {
        calculatedStatus = 'low';
      } else {
        calculatedStatus = 'very_low'; // quantity > 0 but < lowThreshold
      }
      
      // Log for debugging
      print('     Calculated status: $calculatedStatus');
      print('     Stored vs Calculated: "$storedStatus" vs "$calculatedStatus"');
      
      bloodTypesFormatted[bloodType] = {
        'status': calculatedStatus, // Use calculated status, not stored one
        'units': quantity,
        'thresholds': {
          'high': highThreshold,
          'medium': mediumThreshold,
          'low': lowThreshold,
        },
      };
      
      print('     ✓ $bloodType: $calculatedStatus ($quantity units)');
    }
    
    // Format last updated string
    String lastUpdatedStr;
    if (latestUpdate != null) {
      lastUpdatedStr = latestUpdate.toDate().toIso8601String();
    } else {
      lastUpdatedStr = DateTime.now().toIso8601String();
    }
    
    // Create the complete response structure
    Map<String, dynamic> formattedData = {
      'location': hospitalName,
      'name': hospitalName,
      'address': hospitalData['address'] ?? '',
      'city': hospitalData['city'] ?? '',
      'state': hospitalData['state'] ?? '',
      'officeDays': hospitalData['officeDays'] ?? '',
      'officeStartTime': hospitalData['officeStartTime'] ?? '',
      'officeEndTime': hospitalData['officeEndTime'] ?? '',
      'last_updated': lastUpdatedStr,
      'blood_types': bloodTypesFormatted,
    };
    
    print('✅ Successfully formatted blood stock data');
    print('   Total blood types: ${bloodTypesFormatted.length}');
    print('   Final formatted data keys: ${formattedData.keys.toList()}');
    print('   Final blood_types: ${formattedData['blood_types']}');
    
    return formattedData;
  }
  
  /// Get blood stock data for ALL hospitals
  static Future<List<Map<String, dynamic>>> getAllHospitalsBloodStock() async {
    try {
      print('🏥 Fetching all hospitals with blood stock...');
      
      final hospitalsSnapshot = await _firestore.collection(HOSPITALS_COLLECTION).get();
      final List<Map<String, dynamic>> allHospitalsData = [];
      
      for (var hospitalDoc in hospitalsSnapshot.docs) {
        final hospitalData = hospitalDoc.data();
        final hospitalName = hospitalData['name']?.toString() ?? hospitalDoc.id;
        
        print('   Processing hospital: $hospitalName');
        
        // Get blood stock for this hospital
        final bloodStockSnapshot = await _firestore
            .collection(HOSPITALS_COLLECTION)
            .doc(hospitalDoc.id)
            .collection(BLOOD_STOCK_SUBCOLLECTION)
            .get();
        
        if (bloodStockSnapshot.docs.isNotEmpty) {
          final formattedData = _formatBloodStockData(
            hospitalName: hospitalName,
            hospitalData: hospitalData,
            bloodStockDocs: bloodStockSnapshot.docs,
          );
          allHospitalsData.add(formattedData);
          print('   ✓ Added blood stock for $hospitalName');
        } else {
          print('   ⚠️ No blood stock data for $hospitalName');
        }
      }
      
      print('✅ Successfully fetched data for ${allHospitalsData.length} hospitals');
      return allHospitalsData;
      
    } catch (e, stackTrace) {
      print('❌ Error fetching all hospitals blood stock: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
  
  /// Update status for a specific blood type based on quantity
  static Future<bool> updateBloodStockStatus({
    required String hospitalId,
    required String bloodTypeDocId,
    required int quantity,
  }) async {
    try {
      // Get the blood type document to access thresholds
      final docSnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .doc(hospitalId)
          .collection(BLOOD_STOCK_SUBCOLLECTION)
          .doc(bloodTypeDocId)
          .get();
      
      if (!docSnapshot.exists) {
        return false;
      }
      
      final data = docSnapshot.data();
      final thresholds = data?['thresholds'] as Map<String, dynamic>? ?? {};
      final highThreshold = (thresholds['high'] as num?)?.toInt() ?? 50;
      final mediumThreshold = (thresholds['medium'] as num?)?.toInt() ?? 30;
      final lowThreshold = (thresholds['low'] as num?)?.toInt() ?? 10;
      
      // Calculate new status
      String newStatus;
      if (quantity == 0) {
        newStatus = 'empty';
      } else if (quantity >= highThreshold) {
        newStatus = 'high';
      } else if (quantity >= mediumThreshold) {
        newStatus = 'medium';
      } else if (quantity >= lowThreshold) {
        newStatus = 'low';
      } else {
        newStatus = 'very_low';
      }
      
      // Update the status in the database
      await docSnapshot.reference.update({
        'status': newStatus,
        'quantity': quantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Status updated to $newStatus for quantity $quantity');
      return true;
      
    } catch (e) {
      print('❌ Error updating status: $e');
      return false;
    }
  }
  
  /// Update blood stock quantity for a specific hospital and blood type
  static Future<bool> updateBloodStock({
    required String hospitalName,
    required String bloodType,
    required int newQuantity,
  }) async {
    try {
      final hospitalId = await getHospitalIdByName(hospitalName);
      if (hospitalId == null) {
        print('❌ Hospital not found: $hospitalName');
        return false;
      }
      
      // Find the blood type document
      final querySnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .doc(hospitalId)
          .collection(BLOOD_STOCK_SUBCOLLECTION)
          .where('bloodType', isEqualTo: bloodType)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        print('❌ Blood type $bloodType not found for hospital $hospitalName');
        return false;
      }
      
      final docId = querySnapshot.docs.first.id;
      
      // Use the helper method to update status based on quantity
      return await updateBloodStockStatus(
        hospitalId: hospitalId,
        bloodTypeDocId: docId,
        quantity: newQuantity,
      );
      
    } catch (e, stackTrace) {
      print('❌ Error updating blood stock: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  /// Get detailed blood type information including thresholds
  static Future<Map<String, dynamic>?> getBloodTypeDetails({
    required String hospitalName,
    required String bloodType,
  }) async {
    try {
      final hospitalId = await getHospitalIdByName(hospitalName);
      if (hospitalId == null) {
        return null;
      }
      
      final querySnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .doc(hospitalId)
          .collection(BLOOD_STOCK_SUBCOLLECTION)
          .where('bloodType', isEqualTo: bloodType)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        return null;
      }
      
      final data = querySnapshot.docs.first.data();
      final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
      final thresholds = data['thresholds'] as Map<String, dynamic>? ?? {};
      
      return {
        'quantity': quantity,
        'thresholds': thresholds,
        'bloodType': bloodType,
        'hospitalId': hospitalId,
        'docId': querySnapshot.docs.first.id,
      };
      
    } catch (e) {
      print('❌ Error getting blood type details: $e');
      return null;
    }
  }
  
  /// Add units to existing blood stock
  static Future<bool> addBloodStockUnits({
    required String hospitalName,
    required String bloodType,
    required int unitsToAdd,
  }) async {
    try {
      final details = await getBloodTypeDetails(
        hospitalName: hospitalName,
        bloodType: bloodType,
      );
      
      if (details == null) {
        return false;
      }
      
      final int currentQuantity = details['quantity'] as int;
      final int newQuantity = currentQuantity + unitsToAdd;
      
      return await updateBloodStock(
        hospitalName: hospitalName,
        bloodType: bloodType,
        newQuantity: newQuantity,
      );
      
    } catch (e) {
      print('❌ Error adding blood stock units: $e');
      return false;
    }
  }
  
  /// Remove units from existing blood stock
  static Future<bool> removeBloodStockUnits({
    required String hospitalName,
    required String bloodType,
    required int unitsToRemove,
  }) async {
    try {
      final details = await getBloodTypeDetails(
        hospitalName: hospitalName,
        bloodType: bloodType,
      );
      
      if (details == null) {
        return false;
      }
      
      final int currentQuantity = details['quantity'] as int;
      final int newQuantity = currentQuantity - unitsToRemove;
      
      // Ensure we don't go below 0
      final int safeQuantity = newQuantity < 0 ? 0 : newQuantity;
      
      return await updateBloodStock(
        hospitalName: hospitalName,
        bloodType: bloodType,
        newQuantity: safeQuantity,
      );
      
    } catch (e) {
      print('❌ Error removing blood stock units: $e');
      return false;
    }
  }
  
  /// Recalculate and update all blood stock statuses for a hospital
  static Future<bool> recalculateAllStatuses(String hospitalName) async {
    try {
      final hospitalId = await getHospitalIdByName(hospitalName);
      if (hospitalId == null) {
        print('❌ Hospital not found: $hospitalName');
        return false;
      }
      
      // Get all blood stock documents
      final bloodStockSnapshot = await _firestore
          .collection(HOSPITALS_COLLECTION)
          .doc(hospitalId)
          .collection(BLOOD_STOCK_SUBCOLLECTION)
          .get();
      
      print('🔧 Recalculating statuses for ${bloodStockSnapshot.docs.length} blood types');
      
      bool allSuccess = true;
      
      for (var doc in bloodStockSnapshot.docs) {
        final data = doc.data();
        final bloodType = data['bloodType'] as String? ?? 'Unknown';
        final quantity = (data['quantity'] as num?)?.toInt() ?? 0;
        
        // Use updateBloodStockStatus to recalculate and update
        final success = await updateBloodStockStatus(
          hospitalId: hospitalId,
          bloodTypeDocId: doc.id,
          quantity: quantity,
        );
        
        if (!success) {
          allSuccess = false;
          print('⚠️ Failed to update status for $bloodType');
        } else {
          print('✅ Updated status for $bloodType');
        }
      }
      
      return allSuccess;
      
    } catch (e) {
      print('❌ Error recalculating statuses: $e');
      return false;
    }
  }
  
  static String getStatusImage(String status) {
    final statusLower = status.toLowerCase();
    
    // Print for debugging
    print('🖼️ Getting image for status: "$status" (lowercase: "$statusLower")');
    
    switch (statusLower) {
      case 'low':
      case 'very_low':
      case 'empty':
        return 'assets/low.png';
      case 'full':
      case 'high':
        return 'assets/high.png';
      case 'medium':
        return 'assets/medium.png';
      default:
        print('⚠️ Unknown status in getStatusImage: $status');
        return 'assets/medium.png'; // Default fallback
    }
  }
  
  /// Get status color for UI
  static String getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'high':
      case 'full':
        return '#4CAF50'; // Green
      case 'medium':
        return '#FFC107'; // Amber/Yellow
      case 'low':
        return '#FF9800'; // Orange
      case 'very_low':
      case 'empty':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }
  
  /// Get status description for UI
  static String getStatusDescription(String status, int quantity) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'high':
      case 'full':
        return 'Good stock level';
      case 'medium':
        return 'Moderate stock level';
      case 'low':
        return 'Low stock level';
      case 'very_low':
        return 'Very low stock - urgent need';
      case 'empty':
        return 'Out of stock';
      default:
        return 'Unknown status';
    }
  }
}