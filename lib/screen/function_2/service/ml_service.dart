import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<int> sendDataToML(List<Map<String, dynamic>> data) async {
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  final url = Uri.parse('http://$mlIP:8004/predict/');
  print('Sending data to ML API: $data');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    final behaviorIndex = result['predicted_classes'][0];

    return behaviorIndex;
  } else {
    print(
        'Failed to get a response from ML API, Status Code: ${response.statusCode}');
    return -1;
  }
}

Future<String> MLAnomalyCheck(Map<String, dynamic> data) async {
  String? anomalyResult;
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];
  final url = Uri.parse('http://$mlIP:8007/predict');
  // print('Sending data to ML API: $data');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    anomalyResult = jsonDecode(response.body)['output'];
    // print('Anomaly Detection Response: $anomalyResult');
    return anomalyResult ?? 'No result';
  } else {
    print(
        'Failed to get a response from Anomaly ML API, Status Code: ${response.statusCode}');
    return 'Error';
  }
}

Future<String> MLAnomalyHeart(Map<String, dynamic> data) async {
  String? anomalyResult;
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];

  final url = Uri.parse('http://$mlIP:5000/predict');

  // Prepare the data to send as JSON
  final jsonData = jsonEncode(data);

  // Debug: print the data being sent
  print('Sending data to ML API: $jsonData');

  // Send the POST request to the API
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonData,
  );

  // Check the response status
  if (response.statusCode == 200) {
    final result = jsonDecode(response.body);
    anomalyResult =
        result['Prediction']; // Adjust based on the actual response structure
    print('Anomaly Detection Response: $anomalyResult');
    return anomalyResult ?? 'No result';
  } else {
    // Log detailed error information
    print(
        'Failed to get a response from Anomaly ML API, Status Code: ${response.statusCode}');
    print(
        'Response Body: ${response.body}'); // Log the response body for debugging
    return 'Error: ${response.reasonPhrase}';
  }
}
