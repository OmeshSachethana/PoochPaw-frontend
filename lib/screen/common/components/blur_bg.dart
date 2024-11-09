import 'dart:ui';
import 'package:flutter/material.dart';

class BackgroundWithBlur extends StatelessWidget {
  final double blurX;
  final double blurY;
  final double overlayOpacity;
  final Color overlayColor;
  final Widget child;

  const BackgroundWithBlur({
    Key? key,
    this.blurX = 15.0,
    this.blurY = 15.0,
    this.overlayOpacity = 0.4,
    this.overlayColor = Colors.black,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
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
            filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
            child: Container(
              color: overlayColor.withOpacity(overlayOpacity),
            ),
          ),
        ),
        child, // The content of the screen
      ],
    );
  }
}
