import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/screen/function_2/service/ml_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poochpaw/core/constants/constants.dart';

class PetsOverviewDataStream extends StatefulWidget {
  final String petId;
  final String uid;
  final Widget Function(
    BuildContext context,
    num? currentHeartRate,
  )? heartRateBuilder;
  final Widget Function(
    BuildContext context,
    num? ANeck_x,
    num? ANeck_y,
    num? ANeck_z,
    num? GNeck_x,
    num? GNeck_y,
    num? GNeck_z,
  )? behaviorBuilder;

  const PetsOverviewDataStream({
    super.key,
    required this.petId,
    required this.uid,
    this.heartRateBuilder,
    this.behaviorBuilder,
  });

  @override
  State<PetsOverviewDataStream> createState() => _PetsOverviewDataStreamState();
}

class _PetsOverviewDataStreamState extends State<PetsOverviewDataStream> {
  DatabaseReference? dbRef;
  final firestore = FirebaseFirestore.instance;

  // State variables for heart rate and behavior data
  num? currentHeartRate;
  num? ANeck_x, ANeck_y, ANeck_z, GNeck_x, GNeck_y, GNeck_z;

  @override
  void initState() {
    super.initState();
    print("Initializing PetsOverviewDataStream for petId: ${widget.petId}");
    _initializeDbRef();
  }

  void _initializeDbRef() {
    print("Initializing database reference");
    DatabaseReference baseRef = FirebaseDatabase.instance
        .ref()
        .child(widget.petId)
        .child('collar_data');

    print("Listening to changes on path: ${baseRef.path}");

    baseRef.onValue.listen((event) async {
      print("Received database event");
      if (event.snapshot.exists) {
        print("Snapshot exists");
        Map<dynamic, dynamic>? collarData =
            event.snapshot.value as Map<dynamic, dynamic>?;
        if (collarData != null) {
          // print("Collar data keys: ${collarData.keys.toList()}");
          String? latestTimestampKey;
          for (var key in collarData.keys) {
            if (key != 'battery_level' &&
                (latestTimestampKey == null ||
                    key.compareTo(latestTimestampKey) > 0)) {
              latestTimestampKey = key;
            }
          }
          print("Latest timestamp key: $latestTimestampKey");

          if (latestTimestampKey != null) {
            List<dynamic>? dataList =
                collarData[latestTimestampKey] as List<dynamic>?;
            if (dataList != null && dataList.isNotEmpty) {
              print("Data list length: ${dataList.length}");
              List<dynamic> latestDataPoint = dataList.last;
              print("Latest data point: $latestDataPoint");

              setState(() {
                // Update state variables for heart rate and behavior data
                currentHeartRate = latestDataPoint[1] as num?;
                ANeck_x = latestDataPoint[2] as num?;
                ANeck_y = latestDataPoint[3] as num?;
                ANeck_z = latestDataPoint[4] as num?;
                GNeck_x = latestDataPoint[5] as num?;
                GNeck_y = latestDataPoint[6] as num?;
                GNeck_z = latestDataPoint[7] as num?;
              });

              // Send data to ML and save predicted behavior
              final mlData = [
                {
                  'ANeck_x': ANeck_x,
                  'ANeck_y': ANeck_y,
                  'ANeck_z': ANeck_z,
                  'GNeck_x': GNeck_x,
                  'GNeck_y': GNeck_y,
                  'GNeck_z': GNeck_z,
                }
              ];

              sendDataToML(mlData).then((behaviorIndex) {
                if (behaviorIndex != -1) {
                  _savePredictedBehaviorIndexToFirestore(behaviorIndex);
                }
              });
            } else {
              print("Data list is null or empty");
            }
          } else {
            print("No valid timestamp key found");
          }
        } else {
          print("Collar data is null");
        }
      } else {
        print("Snapshot does not exist");
      }
    }, onError: (error) {
      print("Error in database listener: $error");
    });
  }

  Future<void> _savePredictedBehaviorIndexToFirestore(int behaviorIndex) async {
    final uid = widget.uid;
    final petId = widget.petId;
    final now = DateTime.now();
    final dateStr = DateTime(now.year, now.month, now.day)
        .toIso8601String()
        .split('T')
        .first;

    final docRef = firestore
        .collection('users')
        .doc(uid)
        .collection('petBehavior')
        .doc(petId)
        .collection(dateStr)
        .doc('behaviorData');

    try {
      await firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        Map<String, dynamic> existingData = {};
        if (docSnapshot.exists) {
          existingData = docSnapshot.data() as Map<String, dynamic>;
        }

        List<Map<String, dynamic>> behaviorList =
            List<Map<String, dynamic>>.from(existingData['behaviors'] ?? []);

        // Check if the behavior already exists in the list
        final existingBehavior = behaviorList.firstWhere(
          (behavior) => behavior['index'] == behaviorIndex,
          orElse: () => {},
        );

        if (existingBehavior.isNotEmpty) {
          existingBehavior['count'] = (existingBehavior['count'] ?? 0) + 1;
        } else {
          // Add new behavior with an initial count
          behaviorList.add({
            'index': behaviorIndex,
            'count': 1,
          });
        }

        transaction.set(docRef, {
          'behaviors': behaviorList,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error saving behavior index: $e');
    }
  }

  Future<void> _saveDataLocally(String key, dynamic data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String timestamp = DateTime.now().toIso8601String();
    Map<String, dynamic> dataWithTimestamp = {
      'timestamp': timestamp,
      'data': data,
    };
    String jsonData = jsonEncode(dataWithTimestamp);
    await prefs.setString(timestamp, jsonData);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator if data is null
    if (currentHeartRate == null && ANeck_x == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(nav)),
      );
    }

    // Display heart rate and behavior data
    return Column(
      children: [
        if (widget.heartRateBuilder != null)
          widget.heartRateBuilder!(context, currentHeartRate),
        if (widget.behaviorBuilder != null)
          widget.behaviorBuilder!(
            context,
            ANeck_x,
            ANeck_y,
            ANeck_z,
            GNeck_x,
            GNeck_y,
            GNeck_z,
          ),
      ],
    );
  }
}
