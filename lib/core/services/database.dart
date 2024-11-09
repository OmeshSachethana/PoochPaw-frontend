import 'dart:io';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendToVet({
    required File selectedImage,
    required String diseaseResult,
    required String vetId,
    required String dogYear,
    required String dogBreed,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Generate a unique document ID
      final uniqueId =
          '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      final storageRef =
          _storage.ref().child('vet_consultations/$uniqueId.jpg');
      final uploadTask = storageRef.putFile(selectedImage);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      final vetDoc = await _firestore.collection('users').doc(vetId).get();

      // Fetch the current user's profile details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final firstName = userDoc['name'] ?? 'Anonymous';
      final lastName = userDoc['lastName'] ?? '';
      final userName = '$firstName $lastName';
      final userImage = userDoc['image_url'] ?? '';

      final docRef = _firestore.collection('vet_consultations').doc(uniqueId);

      await docRef.set({
        'image_url': imageUrl,
        'disease_result': diseaseResult,
        'user_name': userName,
        'user_id': user.uid,
        'user_email': user.email ?? '',
        'user_image': userImage,
        'doctorId': vetDoc['doctorId'],
        'reviewed': false,
        'rating': '',
        'comment': '',
        'treatment': '',
        'dog_year': dogYear,
        'dog_breed': dogBreed,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error sending data to vet: $e');
      throw e;
    }
  }
}
