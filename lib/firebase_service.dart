import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dashboard related collections
  Future<List<Map<String, dynamic>>> getClientDetails() async {
    final snapshot = await _firestore.collection('ClientDetail').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Update client verification status
  Future<void> updateClientVerification(String clientId, bool isVerified) async {
    await _firestore.collection('ClientDetail').doc(clientId).update({
      'isVerified': isVerified,
      'verificationStatus': isVerified ? 'Verified' : 'Pending',
      'verifiedAt': isVerified ? FieldValue.serverTimestamp() : null,
      'verificationSubmittedAt': isVerified ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<List<Map<String, dynamic>>> getJobs() async {
    final snapshot = await _firestore.collection('Jobs').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Get jobs for a specific client
  Future<List<Map<String, dynamic>>> getJobsByClientId(String clientId) async {
    final snapshot = await _firestore
        .collection('Jobs')
        .where('clientId', isEqualTo: clientId)
        .get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // User request related collections
  Future<List<Map<String, dynamic>>> getMenRequests() async {
    final snapshot = await _firestore.collection('Men').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getWomenRequests() async {
    final snapshot = await _firestore.collection('Women').get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Update request status
  Future<void> updateRequestStatus(String collection, String docId, String status) async {
    await _firestore.collection(collection).doc(docId).update({
      'status': status,
      'lastUpdated': DateTime.now(),
    });
  }

  // Get requests filtered by status
  Future<List<Map<String, dynamic>>> getRequestsByStatus(String collection, String status) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('status', isEqualTo: status)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }
  
  // Get Register users
  Future<List<Map<String, dynamic>>> getRegisterUsers() async {
    try {
      print("Attempting to fetch Register collection data");
      
      // List all collections for debugging
      final collections = await _firestore.collection('Register').get();
      print("Register collection exists with ${collections.docs.length} documents");
      
      if (collections.docs.isEmpty) {
        print("No documents in Register collection");
        return [];
      }
      
      // Get all documents from Register collection
      return collections.docs.map((doc) {
        print("Document ID: ${doc.id}");
        final data = doc.data();
        print("Document data: ${data.keys.join(', ')}");
        
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print("Error fetching Register data: $e");
      return [];
    }
  }
  
  // Alternative approach - fetch Register users by getting all documents
  Future<List<Map<String, dynamic>>> fetchRegisterUsersAlternative() async {
    try {
      print("Using alternative approach to fetch Register collection");
      
      // Use a less restrictive query (get all documents)
      final snapshot = await _firestore.collection('Register').limit(100).get();
      print("Got ${snapshot.docs.length} documents from Register collection");
      
      if (snapshot.docs.isEmpty) {
        return [];
      }
      
      return snapshot.docs.map((doc) {
        print("Document ID: ${doc.id}, Data: ${doc.data().keys.join(', ')}");
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print("Error with alternative Register fetch: $e");
      return [];
    }
  }
  
  // List all available collections in Firestore
  Future<List<String>> listAllCollections() async {
    try {
      print("Cannot list all collections directly, using fallback method");
      
      // Fallback: try to access known collections to see which ones exist
      List<String> existingCollections = [];
      List<String> collectionsToCheck = [
        'Register', 'register', 'users', 'registration', 
        'ClientDetail', 'Jobs', 'Men', 'Women'
      ];
      
      for (var collection in collectionsToCheck) {
        try {
          final snapshot = await _firestore.collection(collection).limit(1).get();
          existingCollections.add(collection);
          print("Collection $collection exists with ${snapshot.docs.length} documents");
        } catch (e) {
          print("Collection $collection either doesn't exist or can't be accessed: $e");
        }
      }
      
      return existingCollections;
    } catch (e) {
      print("Error in listAllCollections: $e");
      return [];
    }
  }

  // Notification related methods
  Future<List<Map<String, dynamic>>> getNotifications(String adminEmail) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('adminEmail', isEqualTo: adminEmail)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print("Error fetching notifications: $e");
      return [];
    }
  }

  Future<void> addNotification(String notificationText, String adminEmail) async {
    await _firestore.collection('notifications').add({
      'text': notificationText,
      'adminEmail': adminEmail,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).delete();
  }

  // Admin access related methods
  Future<List<Map<String, dynamic>>> getAdmins() async {
    try {
      final snapshot = await _firestore.collection('admin-access').get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'email': doc.id,
          'password': data['password'] ?? '',
          'role': data['role'] ?? 'Admin',
          'createdAt': data['createdAt'],
        };
      }).toList();
    } catch (e) {
      print("Error fetching admins: $e");
      return [];
    }
  }

  Future<bool> addAdmin(String email, String password, String role) async {
    try {
      await _firestore.collection('admin-access').doc(email).set({
        'password': password,
        'role': role.isEmpty ? 'Admin' : role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print("Error adding admin: $e");
      return false;
    }
  }

  Future<bool> deleteAdmin(String email) async {
    try {
      await _firestore.collection('admin-access').doc(email).delete();
      return true;
    } catch (e) {
      print("Error deleting admin: $e");
      return false;
    }
  }

  Future<bool> verifyAdminCredentials(String email, String password) async {
    try {
      final doc = await _firestore.collection('admin-access').doc(email).get();
      
      if (!doc.exists) {
        return false;
      }
      
      final data = doc.data();
      return data?['password'] == password;
    } catch (e) {
      print("Error verifying admin credentials: $e");
      return false;
    }
  }
}
