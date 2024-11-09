import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/common/nav/nav.dart';
import 'package:poochpaw/screen/function_1/vet/vet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileCompleteScreen extends StatefulWidget {
  const ProfileCompleteScreen({super.key});

  @override
  State<ProfileCompleteScreen> createState() => _ProfileCompleteScreenState();
}

class _ProfileCompleteScreenState extends State<ProfileCompleteScreen> {
  String? selectedRole;
  TextEditingController _doctorIdController = TextEditingController();

  Future<void> _updateUserRoleInFirestore(String role,
      [String? doctorId]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({
        'role': role,
        if (role == 'Vet' && doctorId != null) 'doctorId': doctorId,
      });
    }
  }

  @override
  void dispose() {
    _doctorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: const Color(nav),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Select your role",
                style: TextStyle(
                  color: Color(nav),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            DropdownButton<String>(
              value: selectedRole,
              hint: const Text("Select Role"),
              onChanged: (String? newValue) {
                setState(() {
                  selectedRole = newValue;
                  if (selectedRole != 'Vet') {
                    _doctorIdController.clear(); // Clear doctor ID if not Vet
                  }
                });
              },
              items: <String>['Client', 'Vet']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedRole == 'Vet') ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _doctorIdController,
                  decoration: InputDecoration(
                    labelText: 'Enter Doctor ID',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  keyboardType:
                      TextInputType.number, // Assuming doctor ID is a number
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(nav),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () async {
                if (selectedRole != null) {
                  if (selectedRole == 'Vet' &&
                      _doctorIdController.text.isEmpty) {
                    // Show a snackbar if doctor ID is required but not provided
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Please enter your doctor ID")),
                    );
                    return;
                  }

                  // Save the selected role in SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('userRole', selectedRole!);

                  // Update the role and possibly doctor ID in Firestore
                  String? doctorId =
                      selectedRole == 'Vet' ? _doctorIdController.text : null;
                  await _updateUserRoleInFirestore(selectedRole!, doctorId);

                  // Navigate to different screens based on the role
                  if (selectedRole == 'Client') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Nav()),
                    );
                  } else if (selectedRole == 'Vet') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => VetScreen()),
                    );
                  }
                } else {
                  // Show a snackbar to ask user to select a role
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a role")),
                  );
                }
              },
              child: const Text(
                "Continue",
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
