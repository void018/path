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
      body: Stack(
        children: [
          //
          // Background Image

          Positioned.fill(
            child: Image.asset(
              'assets/publictransport.png',
              fit: BoxFit.cover,
            ),
          ),
          //
          // Main Content

          Column(
            children: [
              //
              // Title text
              //
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 150, 0, 19),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome to PATH',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 167, 38),
                      fontSize: 32,
                      fontFamily: 'inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              //
              // Subtitle text
              //
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 0, 10),
                child: Text(
                  'The perfect companion for your public transportation trips!',
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 167, 38),
                    fontSize: 18,
                    fontFamily: 'inter',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              // Button with drop shadow
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    30, 400, 30, 0), // Reduce horizontal padding
                child: SizedBox(
                  width: double.infinity, // Stretch to fill available width
                  height: 71,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          spreadRadius: 0,
                          blurRadius: 4,
                          offset: Offset(0, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 255, 167, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0, // Remove default shadow
                      ),
                      onPressed: () {},
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 59, 115),
                          fontSize: 18,
                          fontFamily: 'inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
