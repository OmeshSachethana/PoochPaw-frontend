import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, int> breedMap = {
    'Boxer': 0,
    'Doberman': 1,
    'German Shepherd': 2,
    'Pitbull Terrier': 3,
    'Rottweiler': 4
  };

  Map<String, int> genderMap = {'Female': 0, 'Male': 1};

  Map<String, dynamic> mapPetDetailsToNumeric(String breed, String gender,
      int ageMonths, double weightLb, double weightGoal) {
    return {
      'Breed': breedMap[breed] ?? 0,
      'Age_Months': ageMonths,
      'Weight_lb': weightLb,
      'Gender': genderMap[gender] ?? 0,
      'Weight_Goal_max_lb': weightGoal
    };
  }

  Future<List<String>> fetchPetTypes() async {
    List<String> petTypes = [];
    String uid = _auth.currentUser!.uid;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('petids')
          .get();

      for (var doc in snapshot.docs) {
        String petType = doc['pet_type'];
        petTypes.add(petType);
      }
    } catch (e) {
      print(e);
    }

    return petTypes;
  }

  Future<Map<String, dynamic>> fetchPetDetails(String petType) async {
    String uid = _auth.currentUser!.uid;

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('petids')
          .where('pet_type', isEqualTo: petType)
          .get();

      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return {
          'pet_id': doc.id,
          'pet_type': doc['pet_type'],
          'pet_age': doc['pet_age'],
          'pet_Weight': doc['pet_Weight'],
          'pet_Gender': doc['pet_Gender'],
          'pet_Energylvl': doc['pet_Energylvl'],
          'pet_HealthC': doc['pet_HealthC'],
        };
      } else {
        throw Exception("No pet details found for pet type: $petType");
      }
    } catch (e) {
      print(e);
      throw Exception("Error fetching pet details: $e");
    }
  }

  Future<void> savePetDataToFirestore({
    required String petId,
    required String breed,
    required int ageMonths,
    required double weightLb,
    required String gender,
    required String energyLevel,
    required String healthConcerns,
    required double selectedWeightGoal,
    required String recommendationTime,
    required List<String> recommendedExercises,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('pet-reports').doc(petId).update({
        'dog_id': petId,
        'breed': breed,
        'ageMonths': ageMonths,
        'weightLb': weightLb,
        'gender': gender,
        'energyLevel': energyLevel,
        'healthConcerns': healthConcerns,
        'selectedWeightGoal': selectedWeightGoal,
        'recommendationTime': recommendationTime,
        'recommendedExercises': recommendedExercises,
      });
      print('Pet data saved successfully');
    } catch (e) {
      print('Error saving pet data to Firestore: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchPetDataFromFirestore(String petId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      DocumentSnapshot docSnapshot =
          await firestore.collection('pet-reports').doc(petId).get();

      if (docSnapshot.exists) {
        return docSnapshot.data() as Map<String, dynamic>?;
      } else {
        print('No pet data found for petId: $petId');
        return null;
      }
    } catch (e) {
      print('Error fetching pet data from Firestore: $e');
      return null;
    }
  }

  Future<void> deleteRecommendedExercisesFromFirestore(String petId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('pet-reports').doc(petId).update({
        'recommendedExercises': FieldValue.delete(),
      });
      print('Recommended exercises deleted successfully');
    } catch (e) {
      print('Error deleting recommended exercises: $e');
    }
  }

  Future<void> saveExercisingPeriodAccelValuesToFirestore({
    required String petId,
    required List<double> accelValues,
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('pet-reports').doc(petId).update({
        'exercising_period_accel_values': accelValues,
      });
      print(
          'Exercising period accelerometer values saved to Firestore successfully');
    } catch (e) {
      print(
          'Error saving exercising period accelerometer values to Firestore: $e');
    }
  }

  Future<void> saveExcersingPeriodHeartRateToFirestore(
      {required String petId, required double heartRate}) async {
    try {
      await _firestore.collection('pet-reports').doc(petId).set({
        'latestHeartRate': heartRate,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use 'set' to create or update
      print('Latest heart rate saved to Firestore');
    } catch (e) {
      print('Error saving latest heart rate to Firestore: $e');
    }
  }

  Future<void> saveNormalAccelValuesToFirestore(
      {required String petId, required List<double> accelValues}) async {
    try {
      await _firestore.collection('pet-reports').doc(petId).set({
        'normal_accelometer_values': accelValues,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use 'set' to create or update
      print('Normal accelerometer values saved to Firestore');
    } catch (e) {
      print('Error saving normal accelerometer values to Firestore: $e');
    }
  }

  Future<void> saveLatestHeartRateToFirestore(
      {required String petId, required double heartRate}) async {
    try {
      await _firestore.collection('pet-reports').doc(petId).set({
        'heart_beat': heartRate,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Use 'set' to create or update
      print('Latest heart rate saved to Firestore');
    } catch (e) {
      print('Error saving latest heart rate to Firestore: $e');
    }
  }

  Future<void> calculateAndSaveExercisingPeriodAccelValues({
    required String petId,
    required String recommendationTime,
  }) async {
    final now = DateTime.now();
    final exerciseDurationMinutes =
        int.tryParse(recommendationTime.split(' ')[0]) ?? 0;
    final exercisePeriodEnd =
        now.add(Duration(minutes: exerciseDurationMinutes));

    print("Exercise End Time: $exercisePeriodEnd");

    final dbRef = FirebaseDatabase.instance.ref();
    List<double> accelXValues = [];
    List<double> accelYValues = [];
    List<double> accelZValues = [];

    try {
      final event = await dbRef.child(petId).child('collar_data').once();
      final collarData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (collarData != null) {
        collarData.forEach((node, minuteData) {
          try {
            final timestamp = DateTime.parse(node.toString());
            if (timestamp.isAfter(now) &&
                timestamp.isBefore(exercisePeriodEnd)) {
              final List<dynamic>? secondDataList =
                  minuteData as List<dynamic>?;
              // print("Second Data: $secondDataList");
              if (secondDataList != null) {
                for (var secondData in secondDataList) {
                  final List<dynamic>? secondDataValues =
                      secondData as List<dynamic>?;
                  if (secondDataValues != null && secondDataValues.isNotEmpty) {
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
          } catch (e) {
            print('Error parsing node key as DateTime: $node');
          }
        });

        if (accelXValues.isNotEmpty &&
            accelYValues.isNotEmpty &&
            accelZValues.isNotEmpty) {
          final avgAccelValues = [
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
            petId: petId,
            accelValues: avgAccelValues,
          );
        }
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }
}
