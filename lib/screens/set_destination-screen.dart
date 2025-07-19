import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';

class SetDestinationScreen extends StatelessWidget {
  const SetDestinationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background map
          const OpenstreetmapScreen(),

          /// Positioned inputs and buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _locationCard(),

                  // You can add more elements here if needed
                ],
              ),
            ),
          ),

          /// Back Arrow (plain icon only, no background)
          const Positioned(
            top: 40,
            left: 10,
            child: _BackArrowButton(),
          ),

          /// Swap Button
          const Positioned(
            top: 65,
            right: 60,
            child: _CircleIconButton(
              icon: Icons.swap_vert,
              color: Colors.white,
              onPressed: _onSwapPressed,
            ),
          ),

          /// Add Button
          Positioned(
            top: 85,
            right: 5,
            child: IconButton(
              icon:
                  const Icon(Icons.add, color: Color.fromARGB(255, 0, 59, 115)),
              onPressed: _onAddPressed,
              splashRadius: 1, // Optional: controls ripple effect size
            ),
          ),
        ],
      ),
    );
  }

  /// Card containing starting and destination inputs
  Widget _locationCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 0.5)),
      child: Column(
        children: const [
          _LocationInput(
            icon: Icons.radio_button_checked,
            iconColor: Colors.blue,
            hintText: "Starting Point",
          ),
          Divider(height: 1),
          _LocationInput(
            icon: Icons.location_on,
            iconColor: Colors.red,
            hintText: "Destination",
          ),
        ],
      ),
    );
  }

  static void _onSwapPressed() {
    // TODO: Implement swap logic
  }

  static void _onAddPressed() {
    // TODO: Implement add logic
  }
}

/// Single input row with icon and text field
class _LocationInput extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String hintText;

  const _LocationInput({
    required this.icon,
    required this.iconColor,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circle-shaped button used for swap and add
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final void Function() onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.7, // 👈 70% of original size = 30% smaller
      child: Material(
        color: Color.fromARGB(255, 0, 59, 115),
        shape: const CircleBorder(),
        elevation: 4,
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Placeholder for OpenStreetMap widget (as a black box)
class OpenStreetMap extends StatelessWidget {
  const OpenStreetMap({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace this with your actual OpenStreetMap implementation
    return Container(color: Colors.grey[300]); // Placeholder
  }
}

class _BackArrowButton extends StatelessWidget {
  const _BackArrowButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon:
          const Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 59, 115)),
      onPressed: () => Navigator.pop(context),
      splashRadius: 24, // Optional: smaller tap effect
    );
  }
}
