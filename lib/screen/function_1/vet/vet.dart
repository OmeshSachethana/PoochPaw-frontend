import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:iconly/iconly.dart';
import 'package:poochpaw/core/constants/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:poochpaw/screen/common/home/home.dart';
import 'package:poochpaw/screen/common/role/role.dart';
import 'package:poochpaw/screen/function_3/vet_side_chat.dart';
import 'package:poochpaw/screen/function_1/vet/pages/consultations.dart';
import 'package:poochpaw/screen/function_1/vet/pages/reviewd-consulations.dart';
import 'package:poochpaw/screen/screen.dart';

class VetScreen extends StatefulWidget {
  static String routeName = '/VetScreen';
  const VetScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends State<VetScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final List<Widget> _pages = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists ||
          userDoc['role'] == null ||
          userDoc['role'].isEmpty) {
        // If role is empty or doesn't exist, navigate to role selection screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfileCompleteScreen()),
        );
      } else {
        // Role exists, initialize pages
        setState(() {
          _pages.add(ClientChatScreen());
          _pages.add(ConsultationsScreen());
          _pages.add(ReviewedConsultationsScreen());
          _pages.add(ProfileScreen());
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error, e.g., show an error message
      print('Error checking user role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(
          color: Color(nav),
        )), // Show a loading indicator while checking role
      );
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: CrystalNavigationBar(
        currentIndex: _currentIndex,
        height: 60,
        unselectedItemColor: Colors.white70,
        backgroundColor: Colors.black.withOpacity(0.1),
        marginR: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        onTap: _onTabTapped,
        items: [
          /// Home
          CrystalNavigationBarItem(
            icon: IconlyBold.home,
            unselectedIcon: IconlyLight.home,
            selectedColor: Colors.white,
          ),

          /// Diseases
          CrystalNavigationBarItem(
            icon: IconlyBold.heart,
            unselectedIcon: IconlyLight.heart,
            selectedColor: Colors.red,
          ),

          /// Add (or other feature you prefer)
          CrystalNavigationBarItem(
            icon: IconlyBold.plus,
            unselectedIcon: IconlyLight.plus,
            selectedColor: Colors.white,
          ),

          /// Profile
          CrystalNavigationBarItem(
            icon: IconlyBold.user_2,
            unselectedIcon: IconlyLight.user,
            selectedColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget gradientIcon(IconData iconData) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.yellow, // Replace with your desired start color
            Color(nav), // Replace with your desired end color
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(
        iconData,
        size: 25,
        color: Colors.white, // Temporary color, will be covered by gradient
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
