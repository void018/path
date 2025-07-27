import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/openstreetmap_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/panel_widget.dart';

class HomeNav extends StatefulWidget {
  const HomeNav({super.key});

  @override
  State<HomeNav> createState() => _HomeNavState();
}

class _HomeNavState extends State<HomeNav> {
  final PanelController _panelController = PanelController();
  @override
  Widget build(BuildContext context) {
    final double PanelHeightClosed = MediaQuery.of(context).size.height * 0.235;
    final double PanelHeightOpen = MediaQuery.of(context).size.height * 1.0;
    return Scaffold(
      body: Stack(
        children: [
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
          /*



          Sliding Up Panel
          


          */
          SlidingUpPanel(
            controller: _panelController,
            minHeight: PanelHeightClosed,
            maxHeight: PanelHeightOpen,
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            panelBuilder: (controller) => PanelWidget(
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
