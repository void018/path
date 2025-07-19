import 'package:flutter/material.dart';
import 'package:public_transportation/Navgation%20Bar/home_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _navigateBottomBar(int index) {
    setState(() {
      _selectedindex = index;
    });
  }

  int _selectedindex = 0;
  final List<Widget> _pages = [
    HomeNav(),
    Center(child: Text('Search Screen')),
    Center(child: Text('Settings Screen')),
    Center(child: Text('Profile Screen')),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        onTap: _navigateBottomBar,
        currentIndex: _selectedindex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor:
            Color.fromARGB(255, 255, 167, 38), // <-- Focused icon color
        unselectedItemColor:
            Colors.grey, // Optional: to differentiate unfocused icons
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Routes',
          ),
        ],
      ),
      body: _pages[_selectedindex],
    );
  }
}
