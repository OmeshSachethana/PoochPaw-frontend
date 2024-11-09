import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/screen/function_3/services/pet_service.dart';

class ExerciseRecommendations extends StatefulWidget {
  final String recommendationTime;
  final String selectedPet;
  final List<String> recommendedExercises;
  final Color cardColor;
  final Color textColor;
  final String petId;

  ExerciseRecommendations({
    required this.recommendationTime,
    required this.selectedPet,
    required this.recommendedExercises,
    required this.cardColor,
    required this.textColor,
    required this.petId,
  });

  @override
  _ExerciseRecommendationsState createState() =>
      _ExerciseRecommendationsState();
}

class _ExerciseRecommendationsState extends State<ExerciseRecommendations> {
  bool isLoading = true;
  bool hasError = false;
  bool _isTimerRunning = false;
  bool _isPaused = false;

  late Duration _remainingTime;
  Timer? _timer;
  Duration _pausedTime = Duration.zero;

  String? _startTime;
  String? _endTime;

  Map<DateTime, List<double>> dailyHeartRates = {};
  List<double> accelXValues = [];
  List<double> accelYValues = [];
  List<double> accelZValues = [];

  @override
  void initState() {
    super.initState();
    _remainingTime = _parseTime(widget.recommendationTime);
    setupRealTimeListener();
  }

  void setupRealTimeListener() {
    final dbRef = FirebaseDatabase.instance
        .ref()
        .child(widget.petId)
        .child('collar_data');

    dbRef.onValue.listen((event) async {
      final collarData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (collarData != null) {
        await processCollarData(collarData);
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }).onError((error) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      print('Error listening to data: $error');
    });
  }

  Future<void> processCollarData(Map<dynamic, dynamic> collarData) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));

      print('Processing collar data...');
      collarData.forEach((node, minuteData) {
        if (node != 'battery_level') {
          final DateTime timestamp = _parseCustomDateTime(node.toString());
          if (timestamp.isAfter(sevenDaysAgo) && timestamp.isBefore(now)) {
            final dateKey =
                DateTime(timestamp.year, timestamp.month, timestamp.day);
            final List<dynamic>? secondDataList = minuteData as List<dynamic>?;

            if (secondDataList != null) {
              for (var secondData in secondDataList) {
                final List<dynamic>? secondDataValues =
                    secondData as List<dynamic>?;
                if (secondDataValues != null && secondDataValues.isNotEmpty) {
                  final double? heartbeat =
                      double.tryParse(secondDataValues[1].toString());
                  if (heartbeat != null) {
                    dailyHeartRates
                        .putIfAbsent(dateKey, () => [])
                        .add(heartbeat);
                  }

                  if (secondDataValues.length > 4) {
                    final double? accelX =
                        double.tryParse(secondDataValues[2].toString());
                    final double? accelY =
                        double.tryParse(secondDataValues[3].toString());
                    final double? accelZ =
                        double.tryParse(secondDataValues[4].toString());

                    if (accelX != null && accelY != null && accelZ != null) {
                      accelXValues.add(accelX);
                      accelYValues.add(accelY);
                      accelZValues.add(accelZ);
                    }
                  }
                }
              }
            }
          }
        }
      });

      setState(() {
        isLoading = false;
        hasError = false;
      });
    } catch (error) {
      print('Error processing collar data: $error');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  DateTime _parseCustomDateTime(String dateTimeString) {
    try {
      final dateFormat = DateFormat("yyyy-MM-dd HH-mm-ss");
      return dateFormat.parse(dateTimeString);
    } catch (e) {
      print('Error parsing date: $dateTimeString, Error: $e');
      return DateTime.now(); // Fallback to current date if parsing fails
    }
  }

  void _startTimer() {
    if (!_isTimerRunning) {
      _startTime = _formatDateTime(DateTime.now());

      DateTime endTime = DateTime.now().add(_remainingTime);
      _endTime = _formatDateTime(endTime);

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime -= Duration(seconds: 1);
          } else {
            _timer?.cancel();
            _isTimerRunning = false;
            _saveDataToFirestore(); // Save data to Firestore after timer ends
          }
        });
      });
      _isTimerRunning = true;
      _isPaused = false;
    }
  }

  void _pauseTimer() {
    if (_isTimerRunning && !_isPaused) {
      _timer?.cancel();
      _pausedTime = _remainingTime;
      setState(() {
        _isPaused = true;
      });
    }
  }

  void _resumeTimer() {
    if (_isPaused) {
      setState(() {
        _remainingTime = _pausedTime;
        _isPaused = false;
        _isTimerRunning = true;
      });

      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime.inSeconds > 0) {
            _remainingTime -= Duration(seconds: 1);
          } else {
            _timer?.cancel();
            _isTimerRunning = false;
            _saveDataToFirestore(); // Save data to Firestore after timer ends
          }
        });
      });
    }
  }

  Future<void> _saveDataToFirestore() async {
    try {
      List<_HeartbeatData> tempData = [];
      dailyHeartRates.forEach((date, heartRates) {
        if (heartRates.isNotEmpty) {
          double averageHeartRate =
              heartRates.reduce((a, b) => a + b) / heartRates.length;
          tempData.add(_HeartbeatData(date, averageHeartRate));
        }
      });

      tempData.sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (tempData.isNotEmpty) {
        final latestData = tempData.last;
        await PetService().saveExcersingPeriodHeartRateToFirestore(
          petId: widget.petId,
          heartRate: latestData.heartbeat,
        );

        if (accelXValues.isNotEmpty &&
            accelYValues.isNotEmpty &&
            accelZValues.isNotEmpty) {
          final normalAccelValues = [
            double.parse(
                (accelXValues.reduce((a, b) => a + b) / accelXValues.length)
                    .toStringAsFixed(2)),
            double.parse(
                (accelYValues.reduce((a, b) => a + b) / accelYValues.length)
                    .toStringAsFixed(2)),
            double.parse(
                (accelZValues.reduce((a, b) => a + b) / accelZValues.length)
                    .toStringAsFixed(2)),
          ];
          await PetService().saveExercisingPeriodAccelValuesToFirestore(
            petId: widget.petId,
            accelValues: normalAccelValues,
          );
        }
      }

      print('Data saved to Firestore');
    } catch (error) {
      print('Error saving data to Firestore: $error');
    }
  }

  Duration _parseTime(String time) {
    if (time.contains(':')) {
      List<String> parts = time.split(':');
      if (parts.length == 3) {
        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);
        int seconds = int.parse(parts[2]);
        return Duration(hours: hours, minutes: minutes, seconds: seconds);
      } else if (parts.length == 2) {
        int minutes = int.parse(parts[0]);
        int seconds = int.parse(parts[1]);
        return Duration(minutes: minutes, seconds: seconds);
      }
    } else if (time.contains('minutes')) {
      int minutes = int.parse(time.split(' ')[0]);
      return Duration(minutes: minutes);
    }
    throw FormatException('Invalid time format');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd HH-mm-ss").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(8),
      child: Card(
        color: widget.cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exercise Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: widget.textColor,
                ),
              ),
              SizedBox(height: 10),
              ...widget.recommendedExercises.map((exercise) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      exercise,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.textColor,
                      ),
                    ),
                  )),
              SizedBox(height: 10),
              if (_isTimerRunning)
                Center(
                  child: Text(
                    _formatDuration(_remainingTime),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              // SizedBox(height: 10),
              // Center(
              //   child: Column(
              //     children: [
              //       if (!_isTimerRunning)
              //         ElevatedButton(
              //           style: ElevatedButton.styleFrom(
              //             primary: Color(nav),
              //             padding: EdgeInsets.symmetric(
              //                 horizontal: 24, vertical: 12),
              //           ),
              //           onPressed: _startTimer,
              //           child: Text(
              //             _isPaused ? 'Resume Timer' : 'Start Timer',
              //             style: TextStyle(
              //                 fontSize: 16,
              //                 fontFamily: 'Nunito',
              //                 fontWeight: FontWeight.bold,
              //                 color: Colors.white),
              //           ),
              //         ),
              //       if (_isTimerRunning && !_isPaused)
              //         ElevatedButton(
              //           style: ElevatedButton.styleFrom(
              //             primary: Color(nav),
              //             padding: EdgeInsets.symmetric(
              //                 horizontal: 24, vertical: 12),
              //           ),
              //           onPressed: _pauseTimer,
              //           child: Text(
              //             'Pause Timer',
              //             style: TextStyle(
              //                 fontSize: 16,
              //                 fontFamily: 'Nunito',
              //                 fontWeight: FontWeight.bold,
              //                 color: Colors.white),
              //           ),
              //         ),
              //       if (_isPaused)
              //         ElevatedButton(
              //           style: ElevatedButton.styleFrom(
              //             primary: Color(nav),
              //             padding: EdgeInsets.symmetric(
              //                 horizontal: 24, vertical: 12),
              //           ),
              //           onPressed: _resumeTimer,
              //           child: Text(
              //             'Resume Timer',
              //             style: TextStyle(
              //                 fontSize: 16,
              //                 fontFamily: 'Nunito',
              //                 fontWeight: FontWeight.bold,
              //                 color: Colors.white),
              //           ),
              //         ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeartbeatData {
  final DateTime dateTime;
  final double heartbeat;

  _HeartbeatData(this.dateTime, this.heartbeat);
}
