import 'package:flutter/material.dart';
import 'package:public_transportation/screens/home_screen.dart';
import 'package:public_transportation/screens/set_destination-screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SetDestinationScreen(),
    );
  }
}
