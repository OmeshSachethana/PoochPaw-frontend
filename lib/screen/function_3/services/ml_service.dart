import 'package:poochpaw/screen/function_3/services/pet_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendPetDetailsToMlModel({
  required String breed,
  required String gender,
  required int ageMonths,
  required String energyLevel,
  required String healthConcerns,
  required String petId,
  required double weightLb,
  required double weightGoal,
  required Function(
          String recommendationTime, List<String> recommendedExercises)
      onResponse,
}) async {
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  final url = Uri.parse('http://$mlIP:8005/predict');

  String normalizedBreed = breed.trim();
  print('Normalized Breed: $normalizedBreed');
  final petService = PetService();
  final mappedDetails = petService.mapPetDetailsToNumeric(
      normalizedBreed, gender, ageMonths, weightLb, weightGoal);

  print(breed);
  print(gender);

  print('Mapped Details: $mappedDetails');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(mappedDetails),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      print('Response from ML Model: $responseData');

      String recommendationTime =
          '${responseData["Recommended Exercise Duration (minutes)"]} minutes';
      List<String> recommendedExercises = [responseData["Recommendation"]];

      // Call the callback to update state in the widget
      onResponse(recommendationTime, recommendedExercises);
      if (responseData != null) {
        await petService.savePetDataToFirestore(
            petId: petId,
            breed: breed,
            ageMonths: ageMonths,
            weightLb: weightLb,
            gender: gender,
            energyLevel: energyLevel,
            healthConcerns: healthConcerns,
            selectedWeightGoal: weightGoal,
            recommendationTime: recommendationTime,
            recommendedExercises: recommendedExercises);
      }
    } else {
      print('Failed to get response from ML Model: ${response.statusCode}');
    }
  } catch (e) {
    print('Error sending data to ML Model: $e');
  }
}
