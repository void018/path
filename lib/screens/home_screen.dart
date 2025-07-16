import 'package:flutter/material.dart';
import 'package:public_transportation/Navgation%20Bar/home_nav.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/panel_widget.dart';

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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      body: _pages[_selectedindex],
    );
  }
}
