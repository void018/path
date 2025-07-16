import 'package:flutter/material.dart';
import 'package:public_transportation/custom_widgets/Sliding%20Up%20Panel/drag_handle.dart';
import 'package:public_transportation/custom_widgets/openstreetmap_screen.dart';
import 'package:public_transportation/screens/home_screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class PanelWidget extends StatelessWidget {
  final ScrollController controller;
  const PanelWidget({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      controller: controller,
      children: [
        SizedBox(height: 12),
        buildDragHandle(),
        SizedBox(height: 18),
        Center(),
        SizedBox(
          height: 24,
        ),
      ],
    );
  }
}
