import 'package:flutter/material.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(child: Text('Welcome to PATH')),
          Expanded(
              child: Text(
            'The perfect companion for your public transportation trips!',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'inter',
              fontWeight: FontWeight.w400,
            ),
          )),
          ElevatedButton(onPressed: () {}, child: const Text('Get Started')),
        ],
      ),
    );
  }
}
