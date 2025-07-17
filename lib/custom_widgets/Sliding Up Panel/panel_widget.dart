import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/drag_handle.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';
import 'package:public_transportation/screens/home_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PanelWidget extends StatelessWidget {
  final ScrollController controller;
  final PanelController panelController;
  const PanelWidget({
    Key? key,
    required this.controller,
    required this.panelController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: EdgeInsets.zero,
        controller: controller,
        children: [
          SizedBox(height: 12),
          buildDragHandle(panelController),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 13),
                  child: Text(
                    'Where to?',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
                  ),
                ),
                /*


              Search bar for destination input 



              */
                TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    suffixIcon: Icon(Icons.search),
                    hintText: 'Search for a destination',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 0, 59, 115)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 0, 59, 115)),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                /*



              */
                Container(
                  height: 30,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 8, top: 8),
                        child: ElevatedButton(
                          onPressed: () {},
                          child: Text('All'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ]);
  }
}
