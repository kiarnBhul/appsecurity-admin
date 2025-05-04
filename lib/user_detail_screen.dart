import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final String collection;

  const UserDetailScreen({
    super.key, 
    required this.userId,
    this.collection = '',
  });

  @override
  _UserDetailScreenState createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  Map<String, dynamic>? userDetails;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    try {
      print('Attempting to fetch user details for ID: ${widget.userId}, collection: ${widget.collection}');
      
      // Check if we know which collection to use
      if (widget.collection.isNotEmpty) {
        print('Using provided collection: ${widget.collection}');
        DocumentSnapshot userDoc = await _firestore.collection(widget.collection).doc(widget.userId).get();
        
        if (userDoc.exists) {
          print('Document exists in ${widget.collection}');
          final data = userDoc.data() as Map<String, dynamic>;
          print('Document data keys: ${data.keys.join(', ')}');
          
          setState(() {
            userDetails = data;
            userDetails!['id'] = widget.userId;
            userDetails!['source'] = widget.collection;
            isLoading = false;
          });
          return;
        } else {
          print('Document does not exist in ${widget.collection}');
        }
      }
      
      // If we don't know the collection or user wasn't found, try all collections
      // Try Register collection first
      print('Trying Register collection');
      DocumentSnapshot registerDoc = await _firestore.collection('Register').doc(widget.userId).get();
      
      if (registerDoc.exists) {
        print('Document exists in Register collection');
        final data = registerDoc.data() as Map<String, dynamic>;
        print('Document data keys: ${data.keys.join(', ')}');
        
        setState(() {
          userDetails = data;
          userDetails!['id'] = widget.userId;
          userDetails!['source'] = 'Register';
          isLoading = false;
        });
        return;
      } else {
        print('Document not found in Register collection');
        
        // Try querying Register collection to see if document exists with different ID structure
        try {
          final registerUsers = await _firebaseService.getRegisterUsers();
          print('FirebaseService returned ${registerUsers.length} Register users');
          
          // Try to find a user in Register collection with matching email
          for (var user in registerUsers) {
            print('Checking user: ${user['email']}');
            if (user['email'] == widget.userId) {
              print('Found matching user by email in Register collection');
              setState(() {
                userDetails = user;
                userDetails!['source'] = 'Register';
                isLoading = false;
              });
              return;
            }
          }
        } catch (e) {
          print('Error with FirebaseService.getRegisterUsers: $e');
        }
      }
      
      // Try users collection
      print('Trying users collection');
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(widget.userId).get();
      
      if (userDoc.exists) {
        print('Document exists in users collection');
        setState(() {
          userDetails = userDoc.data() as Map<String, dynamic>;
          userDetails!['id'] = widget.userId;
          userDetails!['source'] = 'users';
          isLoading = false;
        });
        return;
      } else {
        print('Document not found in users collection');
      }
      
      // Try registration collection
      print('Trying registration collection');
      DocumentSnapshot registrationDoc = await _firestore.collection('registration').doc(widget.userId).get();
      
      if (registrationDoc.exists) {
        print('Document exists in registration collection');
        setState(() {
          userDetails = registrationDoc.data() as Map<String, dynamic>;
          userDetails!['id'] = widget.userId;
          userDetails!['source'] = 'registration';
          isLoading = false;
        });
        return;
      } else {
        print('Document not found in registration collection');
      }
      
      // User not found in any collection
      print('User not found in any collection');
      setState(() {
        isLoading = false;
        errorMessage = 'User not found in any collection.';
      });
    } catch (e) {
      print('Error fetching user details: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userDetails == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('User not found'),
                      if (errorMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _fetchUserDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            child: Text(
                              userDetails!['firstName'] != null
                                  ? userDetails!['firstName'][0]
                                  : userDetails!['name'] != null
                                    ? userDetails!['name'][0]
                                    : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            userDetails!['firstName'] != null 
                              ? '${userDetails!['firstName'] ?? ''} ${userDetails!['lastName'] ?? ''}'
                              : userDetails!['name'] ?? 'Unknown User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('User ID: ${widget.userId}'),
                              Text('Collection: ${userDetails!['source'] ?? 'Unknown'}'),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: const Text('Email'),
                          subtitle: Text(userDetails!['email'] ?? 'N/A'),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: const Text('Phone Number'),
                          subtitle: Text(userDetails!['phone'] ?? userDetails!['phoneNumber'] ?? 'N/A'),
                        ),
                      ),
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: const Text('Address'),
                          subtitle: Text(userDetails!['address'] ?? 'N/A'),
                        ),
                      ),
                      // Display all other available fields
                      ...userDetails!.entries
                        .where((entry) => !['firstName', 'lastName', 'name', 'email', 'phone', 'phoneNumber', 'address', 'id', 'source'].contains(entry.key))
                        .map((entry) => Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(toTitleCase(entry.key)),
                            subtitle: Text(entry.value?.toString() ?? 'N/A'),
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }
  
  String toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}