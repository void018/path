import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

Widget buildDragHandle(PanelController panelController) => GestureDetector(
      behavior:
          HitTestBehavior.translucent, // Ensures the whole area is tappable
      onTap: () => panelController.isPanelOpen
          ? panelController.close()
          : panelController.open(),
      child: Container(
        width: 96, // 60 + 18 + 18 (30% extra on each side)
        height: 15, // Increase height for easier tapping
        alignment: Alignment.center,
        color: Colors.transparent, // Invisible but tappable
        child: Container(
          width: 60,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
      ),
    );
