import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/common/components/blur_bg.dart';
import 'package:poochpaw/screen/common/home/components/add_pet.dart';
import 'package:poochpaw/core/models/pet_Id_manager.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    // Access the Firebase user directly where context is valid
    final sp = context.watch<SignInProvider>();
    // Access the user from AuthenticationBloc directly within the build method
    final blocUser = context.read<AuthenticationBloc>().state.user;
    //Declare variables for batteryPercentage and camera_status
    String batteryPercentage = '';
    String camera_status = '';
    //Declare variable for petId
    String? petId = PetIdManager().petId;

    // Determine which image URL to use
    String imageUrl =
        sp.imageUrl ?? blocUser?.image_url ?? 'assets/images/placeholder.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Welcome',
        leadingImage: imageUrl,
        actionImage: null,
        onLeadingPressed: () {
          print("Leading icon pressed");
        },
        onActionPressed: () {
          print("Action icon pressed");
        },
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          BackgroundWithBlur(
            child: SizedBox.expand(), // Makes the blur cover the entire screen
          ),
          SingleChildScrollView(
            //padding: EdgeInsets.all(10),
            child: Container(
              //color: Color(0xFFF5F5F5),
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
                      Text(
                        'Hi,${sp.name ?? blocUser?.name ?? ''}',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Let’s take care of your pretty pets!',
                        style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            color: Colors.white.withOpacity(0.7)),
                      ),
                      SizedBox(height: 20), // Adds some space before the image
                      Center(
                        // Center the image
                        child: Image.asset(
                          "assets/images/dog.png",
                          width: 120, // Set your desired image width
                          height: 120, // Set your desired image height
                          fit: BoxFit.cover, // Cover the container's bounds
                        ),
                      ),
                      SizedBox(height: 15), // Adds space after the image
                      Text(
                        "Enhance Your Dog Feeding with AI",
                        style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.7)),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          AddPet(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
