import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CaptureImage extends StatefulWidget {
  final Function(File, String, dynamic)
      onImageCaptured; // Callback function when image is captured

  CaptureImage({required this.onImageCaptured});

  @override
  _CaptureImageState createState() => _CaptureImageState();
}

class _CaptureImageState extends State<CaptureImage> {
  // Retrieve ML server IP from environment variables
  String? mlIP = dotenv.env['MLIP']?.isEmpty ?? true
      ? dotenv.env['DEFAULT_IP']
      : dotenv.env['MLIP'];

  File? _selectedImage; // Currently selected image

  // Method to send image to ML endpoint for prediction
  Future<void> _sendImageToEndpoint(File image) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$mlIP:8002/predict/'), // ML endpoint URL
      );
      request.files.add(await http.MultipartFile.fromPath(
          'file', image.path)); // Add image file to request

      final response = await request.send(); // Send request
      if (response.statusCode == 200) {
        final responseData =
            await response.stream.bytesToString(); // Get response data
        print('Response Data: $responseData');

        final jsonResponse = jsonDecode(responseData); // Decode JSON response
        final result = jsonResponse['class']; // Extract the class from response
        final confidence =
            jsonResponse['confidence_score']; // Extract confidence score
        print('Parsed Result: $result');
        widget.onImageCaptured(image, result,
            confidence); // Pass image and prediction result to callback function
      } else {
        print('Failed to get prediction, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending image to endpoint: $e');
    }
  }

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker()
        .pickImage(source: ImageSource.gallery); // Pick image from gallery
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      setState(() {
        _selectedImage = imageFile; // Update selected image
      });
      _sendImageToEndpoint(
          imageFile); // Send image to ML endpoint for prediction
    }
  }

  // Method to capture image from camera
  Future<void> _captureImage() async {
    final capturedFile = await ImagePicker()
        .pickImage(source: ImageSource.camera); // Capture image from camera
    if (capturedFile != null) {
      final imageFile = File(capturedFile.path);
      setState(() {
        _selectedImage = imageFile; // Update selected image
      });
      _sendImageToEndpoint(
          imageFile); // Send image to ML endpoint for prediction
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Capture Image of Dog\'s Skin',
          style: TextStyle(
              fontSize: 18,
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: _captureImage, // Capture image when tapped
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1), // Glassmorphism effect
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: _selectedImage == null
                  ? Icon(
                      Icons.camera_alt,
                      color: Colors.white.withOpacity(0.7),
                      size: 50,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 200,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              primary: Colors.white.withOpacity(0.3),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed:
                _pickImage, // Pick image from gallery when button pressed
            child: Text(
              'Choose Image',
              style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
