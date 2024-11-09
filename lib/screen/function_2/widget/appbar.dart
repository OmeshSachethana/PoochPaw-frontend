import 'package:flutter/material.dart';
import 'package:poochpaw/core/constants/constants.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  // Define preferred size for the app bar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Build method for the app bar widget
  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0, // No elevation
      backgroundColor: const Color(0xFFF5F5F5), // Background color
      leading: IconButton(
        // Leading icon button (back button)
        icon: Image.asset(
          'assets/icons/Back.png', // Image asset for the back button
          width: 27,
          height: 27,
        ),
        onPressed: () {
          Navigator.of(context).pop(); // Navigate back when pressed
        },
      ),
    );
  }
}
