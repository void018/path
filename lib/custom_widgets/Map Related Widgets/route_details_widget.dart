// widgets/route_details_widget.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'pt_route_model.dart';

class RouteDetailsWidget extends StatelessWidget {
  final PublicTransportRoute route;
  final VoidCallback? onClear;

  const RouteDetailsWidget({
    super.key,
    required this.route,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with route summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_transit, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.formattedDuration,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        route.formattedDistance,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (route.transfers > 0)
                        Text(
                          route.transfersText,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${route.departureTime!.hour.toString().padLeft(2, '0')}:${route.departureTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Text('→'),
                    Text(
                      '${route.arrivalTime!.hour.toString().padLeft(2, '0')}:${route.arrivalTime!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear route',
                  ),
                ],
              ],
            ),
          ),

          // Route legs
          Container(
            height: 300,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: route.legs.length,
              itemBuilder: (context, index) {
                final leg = route.legs[index];
                return _buildLegItem(context, leg, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegItem(BuildContext context, RouteLeg leg, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: leg.isWalkingLeg ? Colors.orange : Colors.blue,
          child: Icon(
            leg.isWalkingLeg ? Icons.directions_walk : Icons.directions_bus,
            color: Colors.white,
          ),
        ),
        title: Text(
          _getLegTitle(leg),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _getLegSubtitle(leg),
          style: TextStyle(color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show departure and arrival times for transit legs
                if (leg.isPublicTransportLeg) ...[
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Depart: ${leg.formattedDepartureTime}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        'Arrive: ${leg.formattedArrivalTime}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Show stops for transit legs
                  if (leg.stops != null && leg.stops!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          '${leg.numberOfStops} stops',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 120,
                      child: ListView.builder(
                        itemCount: leg.stops!.length,
                        itemBuilder: (context, stopIndex) {
                          final stop = leg.stops![stopIndex];
                          final isFirst = stopIndex == 0;
                          final isLast = stopIndex == leg.stops!.length - 1;

                          return Row(
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isFirst
                                          ? Colors.green
                                          : isLast
                                              ? Colors.red
                                              : Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 20,
                                      color: Colors.grey[300],
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stop.stopName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (stop.arrivalTime != null)
                                      Text(
                                        stop.formattedArrivalTime,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],

                // Show instructions for walking legs
                if (leg.isWalkingLeg && leg.instructions.isNotEmpty) ...[
                  const Text(
                    'Walking directions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...leg.instructions.take(5).map(
                        (instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                _getInstructionIcon(instruction.sign),
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  instruction.text,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              if (instruction.distance > 0)
                                Text(
                                  '${instruction.distance.toInt()}m',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                  if (leg.instructions.length > 5)
                    Text(
                      '... and ${leg.instructions.length - 5} more steps',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLegTitle(RouteLeg leg) {
    if (leg.isWalkingLeg) {
      return 'Walking';
    } else {
      // For transit legs, show the trip headsign or route info
      if (leg.tripHeadsign != null &&
          leg.tripHeadsign!.isNotEmpty &&
          leg.tripHeadsign != 'extra') {
        return leg.tripHeadsign!;
      } else if (leg.routeId != null) {
        return 'Route ${leg.routeId}';
      } else {
        return 'Public Transport';
      }
    }
  }

  String _getLegSubtitle(RouteLeg leg) {
    final parts = <String>[];

    // Add distance - use calculated distance from geometry if leg distance is 0
    final distance = _getActualLegDistance(leg);
    if (distance > 0) {
      if (distance >= 1000) {
        parts.add('${(distance / 1000).toStringAsFixed(1)} km');
      } else {
        parts.add('${distance.toInt()} m');
      }
    }

    // Add duration
    final duration = _getActualLegDuration(leg);
    if (duration.inSeconds > 0) {
      parts.add(leg.formattedDuration);
    }

    // Add stop count for transit legs
    if (leg.isPublicTransportLeg && leg.numberOfStops > 0) {
      parts.add('${leg.numberOfStops} stops');
    }

    return parts.join(' • ');
  }

  double _getActualLegDistance(RouteLeg leg) {
    // If leg has distance, use it
    if (leg.distance > 0) {
      return leg.distance;
    }

    // Otherwise calculate from geometry
    if (leg.geometry.length >= 2) {
      double totalDistance = 0;
      for (int i = 0; i < leg.geometry.length - 1; i++) {
        final Distance distance = Distance();
        totalDistance +=
            distance.as(LengthUnit.Meter, leg.geometry[i], leg.geometry[i + 1]);
      }
      return totalDistance;
    }

    return 0;
  }

  Duration _getActualLegDuration(RouteLeg leg) {
    // For transit legs, use travelTime if available
    if (leg.isPublicTransportLeg && leg.travelTime != null) {
      return Duration(milliseconds: leg.travelTime!);
    }

    // Try to parse from departure/arrival times
    final dep = DateTime.tryParse(leg.departureTime);
    final arr = DateTime.tryParse(leg.arrivalTime);
    if (dep != null && arr != null) {
      return arr.difference(dep);
    }

    // Fallback: calculate from instructions
    final totalTime = leg.instructions.fold<int>(
      0,
      (sum, instruction) => sum + instruction.time,
    );

    return Duration(milliseconds: totalTime);
  }

  IconData _getInstructionIcon(int sign) {
    switch (sign) {
      case -7: // Keep left
        return Icons.subdirectory_arrow_left;
      case -3: // Sharp left
      case -2: // Left
        return Icons.turn_left;
      case -1: // Slight left
        return Icons.turn_slight_left;
      case 0: // Continue straight
        return Icons.straight;
      case 1: // Slight right
        return Icons.turn_slight_right;
      case 2: // Right
      case 3: // Sharp right
        return Icons.turn_right;
      case 7: // Keep right
        return Icons.subdirectory_arrow_right;
      case 4: // Finish
        return Icons.flag;
      case 101: // PT start
        return Icons.directions_bus;
      case 103: // PT end
        return Icons.directions_bus;
      default:
        return Icons.navigation;
    }
  }
}
