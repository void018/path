import 'package:flutter/material.dart';
import 'package:public_transportation/Navgation%20Bar/home_nav.dart';
import 'package:public_transportation/screens/home_screen.dart';
import 'package:public_transportation/screens/landing_screen.dart';
import 'package:public_transportation/screens/navigation_screen.dart';
import 'package:public_transportation/screens/sign_in_screen.dart';
import 'package:public_transportation/screens/unified_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LandingScreen(), // Start with the animated landing screen
      debugShowCheckedModeBanner: false, // Optional: removes debug banner
    );
  }
}
