import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';

class ExerciseScreen extends StatelessWidget {
  final String petId;

  const ExerciseScreen({
    super.key,
    required this.petId,
  });

  Future<Map<String, dynamic>?> fetchPetDataFromFirestore(String petId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot docSnapshot =
          await firestore.collection('pet-reports').doc(petId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>?; // cast to Map
      } else {
        print('No pet data found for petId: $petId');
        return null;
      }
    } catch (e) {
      print('Error fetching pet data from Firestore: $e');
      return null;
    }
  }

  Future<void> logExercise(String day, String exercise) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentReference docRef =
          firestore.collection('pet-exercises').doc(petId);

      DocumentSnapshot docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        await docRef.update({
          day: FieldValue.arrayUnion([exercise]),
        });
      } else {
        await docRef.set({
          day: [exercise],
        });
      }
    } catch (e) {
      print('Error logging exercise: $e');
    }
  }

  Future<List<String>> fetchExercisesForDay(String day) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot docSnapshot =
          await firestore.collection('pet-exercises').doc(petId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?; // cast to Map
        return List<String>.from(data?[day] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching exercises: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Exercises',
        leadingImage: 'assets/icons/Back.png',
        onLeadingPressed: () {
          Navigator.of(context).pop();
        },
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(), 
          ),
          Container(
            padding: const EdgeInsets.only(top: 90.0),
            child: FutureBuilder<Map<String, dynamic>?>(
              future: fetchPetDataFromFirestore(petId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching pet data'));
                } else if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                      child: Text('No data available for this pet.'));
                } else {
                  final petData = snapshot.data!;

                  // Safely extract fields with type checks
                  final breed = petData['breed'] as String? ?? 'Unknown';
                  final ageMonths = petData['ageMonths'] is int
                      ? petData['ageMonths'].toString()
                      : 'Unknown';
                  final gender = petData['gender'] as String? ?? 'Unknown';
                  final weight = petData['weightLb'] is int
                      ? petData['weightLb'].toString()
                      : 'Unknown';
                  final time =
                      petData['recommendationTime'] as String? ?? '0 minutes';

                  // Extract the numerical part of the recommendationTime string
                  final recommendedTime = int.tryParse(time.split(' ')[0]) ?? 0;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPetInfo('Breed', breed),
                        _buildPetInfo('Age', '$ageMonths months'),
                        _buildPetInfo('Gender', gender),
                        _buildPetInfo('Weight', '$weight lbs'),
                        _buildPetInfo(
                            'Exercises',
                            (petData['recommendedExercises'] as List<dynamic>?)
                                    ?.join(', ') ??
                                'None'),
                        _buildPetInfo('Exercise Time', '$time per day'),
                        const SizedBox(height: 16),
                        _ExerciseTimer(recommendedTime: recommendedTime),
                        const SizedBox(height: 16),
                        const Text(
                          'Exercises for the Week:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(nav),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: _buildDayWiseExerciseList(context),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfo(String label, String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$label: $info',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Ensure contrast with the background
        ),
      ),
    );
  }

  Widget _buildDayWiseExerciseList(BuildContext context) {
    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    return ListView.builder(
      itemCount: daysOfWeek.length,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final day = daysOfWeek[index];
        return FutureBuilder<List<String>>(
          future: fetchExercisesForDay(day),
          builder: (context, snapshot) {
            List<String> exercises = [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              exercises = [];
            } else if (snapshot.hasError) {
              exercises = [];
            } else if (snapshot.hasData) {
              exercises = snapshot.data!;
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white.withOpacity(0.2), // Semi-transparent
              child: ListTile(
                leading: Icon(
                  Icons.calendar_today,
                  color: Color(nav),
                  size: 30,
                ),
                title: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Ensure contrast
                  ),
                ),
                subtitle: Text(
                  'Exercises: ${exercises.join(', ')}',
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70), // Light color for subtler info
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  color: Color(nav),
                  onPressed: () {
                    _logExerciseForDay(context, day);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _logExerciseForDay(BuildContext context, String day) {
    TextEditingController exerciseController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Log Exercise for $day'),
          backgroundColor: Colors.white
              .withOpacity(0.8), // Semi-transparent dialog background
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: exerciseController,
                decoration: InputDecoration(
                  labelText: 'Exercise Type',
                  hintText: 'e.g., Walk, Run, Fetch',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newExercise = exerciseController.text;
                if (newExercise.isNotEmpty) {
                  logExercise(day, newExercise);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged exercise for $day')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _ExerciseTimer extends StatefulWidget {
  final int recommendedTime;

  const _ExerciseTimer({required this.recommendedTime});

  @override
  __ExerciseTimerState createState() => __ExerciseTimerState();
}

class __ExerciseTimerState extends State<_ExerciseTimer> {
  late int _remainingTime;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingTime = widget.recommendedTime * 60; // Convert minutes to seconds
  }

  void _startTimer() {
    if (_isRunning) return;
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _pauseTimer() {
    if (!_isRunning) return;
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _stopTimer() {
    setState(() {
      _isRunning = false;
      _remainingTime = widget.recommendedTime * 60; // Reset to initial time
    });
    _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingTime % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Exercise Timer',
          style: TextStyle(
            fontSize: 16,
            color: Color(nav),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              '$minutes:$seconds',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  color: Colors.white,
                  iconSize: 32,
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  color: Colors.white,
                  iconSize: 32,
                  onPressed: _stopTimer,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
