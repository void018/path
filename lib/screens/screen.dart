import 'package:flutter/material.dart';
// Optional for icons

void main() => runApp(const routeselectionscreen());

class routeselectionscreen extends StatelessWidget {
  const routeselectionscreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const RouteSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class RouteSelectionScreen extends StatelessWidget {
  const RouteSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffdceeff),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDestinationInputs(),
              const SizedBox(height: 20),
              const Text(
                'Routes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(child: _buildRouteList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationInputs() {
    return Stack(
      children: [
        Column(
          children: [
            _buildInputCard(
              icon: Icons.radio_button_checked,
              label: 'Starting Point',
              iconColor: Colors.blue,
            ),
            const SizedBox(height: 6),
            _buildInputCard(
              icon: Icons.location_on,
              label: 'Destination',
              iconColor: Colors.red,
            ),
          ],
        ),
        const Positioned(
          top: 0,
          left: -10,
          child: _BackArrowButton(),
        ),
        Positioned(
          right: 65,
          top: 40,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                ),
              ],
              color: Color.fromARGB(255, 0, 59, 115),
              borderRadius: BorderRadius.circular(10), // Rounded square
            ),
            child: const Icon(Icons.swap_vert, color: Colors.white, size: 22),
          ),
        ),
        Positioned(
          right: 0,
          top: 72,
          child: const Icon(
            Icons.add,
            size: 26,
            color: Color.fromARGB(255, 0, 59, 115),
          ),
        ),
        Positioned(
          right: 0,
          top: 15,
          child: const Icon(
            Icons.tune_rounded,
            size: 26,
            color: Color.fromARGB(255, 0, 59, 115),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    Color iconColor = Colors.black, // Default color
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRouteList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 4,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Estimated time and icons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '13:50 min',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(Icons.directions_walk,
                            color: Color.fromARGB(255, 0, 59, 115)),
                        SizedBox(width: 4),
                        Icon(Icons.directions_bus,
                            color: Color.fromARGB(255, 0, 59, 115)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Vertical line and arrival time aligned at the top
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('|', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 16),
                // Arrival Time aligned with Estimated Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Arrival time: 5:30pm',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
