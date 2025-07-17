import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/drag_handle.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/fiters_buttons.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/routes_tiles.dart';

// ignore: must_be_immutable
class PanelWidget extends StatefulWidget {
  final List<String> filters = [
    'All',
    'Khartoum',
    'Bahri',
    'Um Durman',
    'Sharg Elneel',
  ];

  final List<String> routes = [
    'Jabra - UofK',
    'Kalakla - UofK',
    'Um durman - UofK',
    'Burri - UofK',
    'Jabra - UofK',
    'Jabra - UofK',
    'Jabra - UofK',
  ];
  // index of the selected filter
  final ScrollController controller;
  final PanelController panelController;
  PanelWidget({
    Key? key,
    required this.controller,
    required this.panelController,
  }) : super(key: key);

  @override
  State<PanelWidget> createState() => _PanelWidgetState();
}

class _PanelWidgetState extends State<PanelWidget> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: EdgeInsets.zero,
        controller: widget.controller,
        children: [
          SizedBox(height: 12),
          buildDragHandle(widget.panelController),
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
                SizedBox(height: 8),
                /*

              Sliding Buttons List

              */

                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.filters.length,
                    itemBuilder: (context, index) {
                      bool isSelected = index == selectedIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5.0, vertical: 11.0),
                        child: FilterButton(
                          label: widget.filters[index],
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Text(
                    'Previous Trips',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height:
                          1000, // Set the height you want for the previous routes list
                      child: ListView.builder(
                        itemCount: widget.routes.length,
                        itemBuilder: (context, index) {
                          return RouteTile(routeName: widget.routes[index]);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]);
  }
}
