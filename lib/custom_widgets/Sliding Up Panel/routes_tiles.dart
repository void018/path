import 'package:flutter/material.dart';

class RouteTile extends StatelessWidget {
  final String routeName;

  const RouteTile({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.25),
            blurRadius: 4,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            routeName,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              Icon(Icons.directions_walk, color: Colors.blue[800]),
              SizedBox(width: 8),
              Icon(Icons.directions_bus, color: Colors.blue[800]),
            ],
          )
        ],
      ),
    );
  }
}
