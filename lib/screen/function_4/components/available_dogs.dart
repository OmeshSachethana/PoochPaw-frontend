import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class AvailableDogs extends StatefulWidget {
  const AvailableDogs({super.key});

  @override
  _AvailableDogsState createState() => _AvailableDogsState();
}

class _AvailableDogsState extends State<AvailableDogs> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> _fetchAvailableDogs() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('availableDogs').get();
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error fetching dogs: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Available Dogs',
        leadingImage: 'assets/icons/Back.png',
        actionImage: null,
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAvailableDogs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading dogs.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No available dogs at the moment.'));
          }

          final List<Map<String, dynamic>> dogs = snapshot.data!;

          return BackgroundWithBlur(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 24.0, right: 24.0, top: 90.0, bottom: 50.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: dogs.map((dog) => _buildDogCard(dog)).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build each dog's card with details like image, breed, and location
  Widget _buildDogCard(Map<String, dynamic> dog) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDogImage(dog['image']),
                const SizedBox(height: 10),
                Text(
                  '${dog['id'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Breed: ${dog['breed'] ?? 'Unknown Breed'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Age: ${dog['age'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gender: ${dog['gender'] ?? 'Unknown Gender'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Category: ${dog['category'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Location: ${dog['location'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Display dog's image, fallback to a placeholder if not available
  Widget _buildDogImage(String? imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          : Image.asset(
              'assets/images/placeholder_dog.png',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
    );
  }
}
