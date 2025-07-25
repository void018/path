import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/navigation_panel_widget.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/openstreetmap_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/panel_widget.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  final PanelController _panelController = PanelController();

  @override
  Widget build(BuildContext context) {
    final double PanelHeightClosed = MediaQuery.of(context).size.height * 0.235;
    final double PanelHeightOpen = MediaQuery.of(context).size.height * 1.0;
    return Scaffold(
      body: Stack(
        children: [
          OpenstreetmapScreen(),
          /*



          Floating Icons




          */
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
                        icon: const Icon(Icons.close),
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
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          /*



          Sliding Up Panel
          


          */
          SlidingUpPanel(
            controller: _panelController,
            minHeight: PanelHeightClosed,
            maxHeight: PanelHeightOpen,
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            panelBuilder: (controller) => NavigationPanelWidget(
              panelController: _panelController,
              controller: controller,
            ),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            color: Color.fromARGB(255, 229, 243, 255),
          ),
        ],
      ),
    );
  }
}
