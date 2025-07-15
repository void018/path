import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';
import 'package:public_transportation/screens/landing_screen.dart';
import 'package:public_transportation/screens/sign_in_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignInScreen(),
    );
  }
}
