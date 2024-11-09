import 'dart:ui'; // For blur effect
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:poochpaw/core/services/sign_in_provider.dart';
import 'package:poochpaw/core/utils/app_bar.dart';
import 'package:poochpaw/screen/common/auth/authentication_bloc.dart';
import 'package:poochpaw/screen/function_4/components/add_dog.dart';
import 'package:poochpaw/screen/function_4/components/add_stray_dog.dart';
import 'package:poochpaw/screen/function_4/components/available_dogs.dart';
import 'package:poochpaw/screen/function_4/components/missing_dog_reports.dart';
import 'package:poochpaw/screen/function_4/components/view_search_stray_dogs.dart';
import 'package:poochpaw/screen/function_4/components/volunteer_emergency_notifications.dart';

class StrayDogScreen extends StatefulWidget {
  @override
  _StrayDogScreenState createState() => _StrayDogScreenState();
}

class _StrayDogScreenState extends State<StrayDogScreen> {
  @override
  Widget build(BuildContext context) {
    final sp = context.watch<SignInProvider>();
    final blocUser = context.read<AuthenticationBloc>().state.user;
    String imageUrl =
        sp.imageUrl ?? blocUser?.image_url ?? 'assets/images/placeholder.png';

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Stray Dog Management',
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
          Positioned.fill(
            child: Image.asset(
              'assets/images/4.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.black.withOpacity(0.4),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.add,
                  title: 'Add Stray Dog',
                  description:
                      'Report a stray dog you found so it can be taken care of.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddStrayDog()),
                  ),
                ),
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.add_circle,
                  title: 'Add Dogs',
                  description:
                      'Add a dog that you found or are taking care of to the system.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddDog()),
                  ),
                ),
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.pets,
                  title: 'Available Dogs',
                  description:
                      'View the list of stray dogs that are available for adoption or fostering.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AvailableDogs()),
                  ),
                ),
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.search,
                  title: 'Search Stray Dogs',
                  description: 'Search for stray dogs reported in your area.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ViewSearchStrayDogs()),
                  ),
                ),
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.report,
                  title: 'Missing Dog Reports',
                  description: 'View reports of missing dogs in the system.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MissingDogReports()),
                  ),
                ),
                _buildGlassmorphicSectionCard(
                  context,
                  icon: Icons.notifications,
                  title: 'Emergency Notifications',
                  description:
                      'Receive emergency notifications for distressed dogs.',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            VolunteerEmergencyNotifications()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Glassmorphism-style section card widget
  Widget _buildGlassmorphicSectionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Function onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
