import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/panel_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final double PanelHeightClosed = MediaQuery.of(context).size.height * 0.25;
    final double PanelHeightOpen = MediaQuery.of(context).size.height * 1.0;
    return Scaffold(
      body: Stack(
        children: [
          SlidingUpPanel(
            minHeight: PanelHeightClosed,
            maxHeight: PanelHeightOpen,
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            body: OpenstreetmapScreen(),
            panelBuilder: (controller) => PanelWidget(
              controller: controller,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            color: Color.fromARGB(255, 229, 243, 255),
          ),
          Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 90, 0, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 229, 243, 255),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        color: Color.fromARGB(255, 0, 59, 115),
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(230, 90, 0, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 229, 243, 255),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        color: Color.fromARGB(255, 0, 59, 115),
                        icon: const Icon(Icons.person_outlined),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget buildAboutText() => Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'About',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 12),
          Text(
            'nkmdkfsdjjjjjjjjjjjjjksldfskdfjfkdjflsfjijejoeiwwwwwiiiiiiiiiiiiiiiejfje',
          ),
        ],
      ),
    );
