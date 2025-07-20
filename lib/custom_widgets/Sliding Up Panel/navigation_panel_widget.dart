import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/drag_handle.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/fiters_buttons.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/routes_tiles.dart';

// ignore: must_be_immutable
class NavigationPanelWidget extends StatefulWidget {
  NavigationPanelWidget({
    Key? key,
    required PanelController panelController,
    required ScrollController controller,
  }) : super(key: key);

  @override
  State<NavigationPanelWidget> createState() => _NavigationPanelWidgetState();
}

class _NavigationPanelWidgetState extends State<NavigationPanelWidget> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        routeStop(
          label: "Jabra, Block 20",
          color: Colors.orange,
          icon: Icons.directions_walk,
        ),
        routeDivider(),
        routeStop(
          label: "Minaa Barri",
          color: Colors.blue.shade900,
          icon: Icons.directions_bus,
        ),
        routeDivider(),
        routeStop(
          label: "Jackson",
          color: Colors.blue.shade900,
          icon: Icons.directions_bus,
        ),
      ],
    );
  }
}

Widget routeStop({
  required String label,
  required Color color,
  required IconData icon,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(30, 20, 0, 0),
        child: Row(
          children: [
            Icon(Icons.fiber_manual_record, color: color, size: 12),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      SizedBox(width: 100),
      Icon(icon, color: Colors.black),
    ],
  );
}

Widget routeDivider() {
  return Padding(
    padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
    child: SizedBox(
      height: 24,
      child: VerticalDivider(
        thickness: 1.5,
        color: Colors.grey.shade400,
      ),
    ),
  );
}
