import 'dart:async';
import 'package:flutter/material.dart';
import 'package:poochpaw/screen/common/auth/launcherScreen/launcher_screen.dart';
import 'package:poochpaw/screen/function_1/vet/vet.dart';
import 'package:provider/provider.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/next_screen.dart';
import '../../nav/nav.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = '/splash';
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    final spm = context.read<SignInProvider>();
    super.initState();
    Timer(const Duration(seconds: 5), () async {
      if (spm.isSignedIn) {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final userDoc =
                FirebaseFirestore.instance.collection('users').doc(user.uid);
            final docSnapshot = await userDoc.get();

            if (docSnapshot.exists) {
              final role = docSnapshot.get('role') as String?;
              print('User role fetched: $role');

              if (role == 'Vet') {
                nextScreen(context, const VetScreen());
              } else if (role == 'Client') {
                nextScreen(context, const Nav());
              } else {
                nextScreen(context, const LauncherScreen());
              }
            } else {
              print('User document does not exist');
              nextScreen(context, const LauncherScreen());
            }
          } else {
            print('User is not authenticated');
            nextScreen(context, const LauncherScreen());
          }
        } catch (e) {
          print('Error fetching user role: $e');
          nextScreen(context, const LauncherScreen());
        }
      } else {
        nextScreen(context, const LauncherScreen());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/icons/poochpaw.gif"),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
