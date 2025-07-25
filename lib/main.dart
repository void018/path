import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/enhanced_map_screen.dart';
import 'package:public_transportation/screens/home_screen.dart';
import 'package:public_transportation/screens/navigation_screen.dart';
import 'package:public_transportation/screens/set_destination_screen.dart';
import 'package:public_transportation/screens/set_destination_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: EnhancedOpenstreetmapScreen(),
    );
  }
}
