import 'package:flutter/material.dart';

class TxtWelcome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset('assets/images/jogging.png', height: 130),
        SizedBox(height: 20),
        Text(
          'Welcome to the Dog Exercise Recommendation System. Here, you can get personalized exercise plans for your pets based on their breed, age, weight, and health concerns.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15.0,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
