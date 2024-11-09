import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'components/body.dart';

class ProfileScreen extends StatelessWidget {
  // Get the current user
  final user = FirebaseAuth.instance.currentUser;

  // Set the route name
  static String routeName = '/profile';

  // Create the widget
  ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Get the current user
    final user = FirebaseAuth.instance.currentUser!;
    // Return the scaffold with the app bar and body
    return Scaffold(
      appBar: CustomAppBar(
        title: 'profile',
        leadingImage: null, // Pass the user's photo URL directly
        actionImage: null,
        onLeadingPressed: () {
          print("Leading icon pressed");
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: Body(user: user),
    );
  }
}
