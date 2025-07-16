import 'package:flutter/material.dart';

Widget buildDragHandle() => Container(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(160, 0, 160, 0),
        child: Container(
          width: 30,
          height: 5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
        ),
      ),
    );
