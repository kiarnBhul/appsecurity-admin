import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'user_detail_screen.dart'; // Screen to show user details
import 'firebase_service.dart'; // Import the firebase service

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];
  String _errorMsg = '';
  List<String> _availableCollections = [];
  
  @override
  void initState() {
    super.initState();
    _checkAvailableCollections();
  }
  
  Future<void> _checkAvailableCollections() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMsg = '';
      });
      
      // First check which collections are available
      _availableCollections = await _firebaseService.listAllCollections();
      print('Available collections: ${_availableCollections.join(', ')}');
      
      _fetchUsers();
    } catch (e) {
      print('Error checking collections: $e');
      setState(() {
        _errorMsg = 'Error checking collections: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      if (_errorMsg.isEmpty) {
        _errorMsg = '';
      }
    });
    
    try {
      List<Map<String, dynamic>> allUsers = [];
      
      // Try the alternative approach first
      print('Using alternative approach to fetch Register users');
      final alternativeUsers = await _firebaseService.fetchRegisterUsersAlternative();
      
      if (alternativeUsers.isNotEmpty) {
        print('Alternative approach found ${alternativeUsers.length} users');
        final usersWithSource = alternativeUsers.map((user) => {
          ...user,
          'source': 'Register',
        }).toList();
        
        allUsers.addAll(usersWithSource);
      } else {
        print('Alternative approach found no users');
        
        // Try the regular approach if available
        if (_availableCollections.contains('Register')) {
          print('Fetching from Register collection (found in available collections)');
          final registerUsers = await _firebaseService.getRegisterUsers();
          
          if (registerUsers.isNotEmpty) {
            final usersWithSource = registerUsers.map((user) => {
              ...user,
              'source': 'Register',
            }).toList();
            
            allUsers.addAll(usersWithSource);
          }
        }
        
        // Try fetch from lowercase 'register' if it exists
        if (_availableCollections.contains('register')) {
          print('Fetching from lowercase register collection');
          try {
            final snapshot = await _firestore.collection('register').get();
            
            if (snapshot.docs.isNotEmpty) {
              final registerUsers = snapshot.docs.map((doc) => {
                'id': doc.id,
                'source': 'register',
                ...doc.data(),
              }).toList();
              
              allUsers.addAll(registerUsers);
            }
          } catch (e) {
            print('Error fetching from lowercase register: $e');
          }
        }
      }
      
      // Still fetch from users collection if it exists
      if (_availableCollections.contains('users')) {
        print('Fetching from users collection');
        try {
          final snapshot = await _firestore.collection('users').get();
          
          if (snapshot.docs.isNotEmpty) {
            final usersCollectionUsers = snapshot.docs.map((doc) => {
              'id': doc.id,
              'source': 'users',
              ...doc.data(),
            }).toList();
            
            allUsers.addAll(usersCollectionUsers);
          }
        } catch (e) {
          print('Error fetching from users collection: $e');
        }
      }
      
      // Also try the registration collection if it exists
      if (_availableCollections.contains('registration')) {
        print('Fetching from registration collection');
        try {
          final snapshot = await _firestore.collection('registration').get();
          
          if (snapshot.docs.isNotEmpty) {
            final registrationUsers = snapshot.docs.map((doc) => {
              'id': doc.id,
              'source': 'registration',
              ...doc.data(),
            }).toList();
            
            allUsers.addAll(registrationUsers);
          }
        } catch (e) {
          print('Error fetching from registration collection: $e');
        }
      }
      
      // If all approaches failed but Register collection exists, try manual approach
      if (allUsers.isEmpty && _availableCollections.contains('Register')) {
        print('Trying manual approach for Register collection');
        
        try {
          // Query specifically for documents in Register collection
          final QuerySnapshot snapshot = await _firestore
              .collection('Register')
              .where(FieldPath.documentId, isNotEqualTo: '')
              .get();
          
          print('Manual approach found ${snapshot.docs.length} documents');
          
          final manualUsers = snapshot.docs.map((doc) => {
            'id': doc.id,
            'source': 'Register',
            ...(doc.data() as Map<String, dynamic>),
          }).toList();
          
          allUsers.addAll(manualUsers);
        } catch (e) {
          print('Error with manual approach: $e');
          setState(() {
            _errorMsg = 'Error with manual approach: $e';
          });
        }
      }
      
      print('Total users found across all collections: ${allUsers.length}');
      
      setState(() {
        _users = allUsers;
        _isLoading = false;
        
        if (allUsers.isEmpty) {
          _errorMsg = 'No users found in any collection. Available collections: ${_availableCollections.join(', ')}';
        }
      });
    } catch (e) {
      print('Error fetching users: $e');
      setState(() {
        _isLoading = false;
        _errorMsg = 'Error fetching users: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Users List"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkAvailableCollections,
          ),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : _users.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No users found'),
                  if (_errorMsg.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: $_errorMsg',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (_availableCollections.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Available collections: ${_availableCollections.join(', ')}',
                        style: TextStyle(fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: _checkAvailableCollections,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        user['firstName'] != null ? user['firstName'][0] : 
                        user['name'] != null ? user['name'][0] : 'U',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      user['firstName'] != null ? '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}' :
                      user['name'] ?? 'Unknown User',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phone: ${user['phone'] ?? user['phoneNumber'] ?? 'No Phone'}'),
                        Text('Email: ${user['email'] ?? 'No Email'}'),
                        Text('Source: ${user['source'] ?? 'Unknown'}'),
                        Text('ID: ${user['id']}'),
                      ],
                    ),
                    trailing: Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailScreen(
                            userId: user['id'],
                            collection: user['source'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
