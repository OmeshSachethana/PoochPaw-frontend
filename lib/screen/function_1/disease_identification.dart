import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/function_1/components/capture_image.dart';
import 'package:poochpaw/screen/function_1/components/disease_prediction.dart';
import 'package:poochpaw/screen/function_1/notify/notifyscreen.dart';

class DiseaseIdentification extends StatefulWidget {
  @override
  _DiseaseIdentificationState createState() => _DiseaseIdentificationState();
}

class _DiseaseIdentificationState extends State<DiseaseIdentification> {
  String? diseaseResult; // Result of disease identification
  File? selectedImage; // Selected image for disease identification
  double? confidenceScore; // Confidence score of disease identification

  // Method to handle image capture and disease identification result
  void _handleImageCaptured(File image, String result, dynamic confidence) {
    setState(() {
      selectedImage = image;
      diseaseResult = result;
      confidenceScore = confidence;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sp =
        context.watch<SignInProvider>(); // Watch for SignInProvider changes
    final blocUser = context
        .read<AuthenticationBloc>()
        .state
        .user; // Read current user from AuthenticationBloc state
    String imageUrl = sp.imageUrl ??
        blocUser?.image_url ??
        'assets/images/placeholder.png'; // Get user image URL

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Disease Identification', // Set app bar title
        leadingImage: imageUrl, // Set leading image to user's profile image
        actionImage: null, // No action image for this screen
        onLeadingPressed: () {
          print("Leading icon pressed"); // Handle leading icon press
        },
        onActionPressed: () {
          print("Action icon pressed"); // Handle action icon press
        },
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(),
          ),
          SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 90.0,
                bottom: 50.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Image.asset('assets/icons/disease.png',
                          height: 100), // Show disease icon
                      const SizedBox(height: 20),
                      Text(
                        'Identify dog skin related diseases and other odd visuals to predict its name and suggest reasons and remedies.', // Description of disease identification feature
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.0,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CaptureImage(
                          onImageCaptured:
                              _handleImageCaptured), // Widget to capture image
                      const SizedBox(height: 10),
                      DiseasePrediction(
                        diseaseResult: diseaseResult,
                        selectedImage: selectedImage,
                        confidenceScore: confidenceScore,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 5,
              ),
            ],
          ),
          child: FloatingActionButton(
            splashColor: Color(nav),
            backgroundColor: Colors.transparent,
            elevation: 0,
            onPressed: () {
              // Handle floating action button press
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotifyScreen()),
              );
            },
            child: Icon(
              Icons.notifications,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
