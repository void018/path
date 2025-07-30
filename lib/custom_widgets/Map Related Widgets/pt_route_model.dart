import 'dart:convert';
import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class PublicTransportRoute {
  final double distance;
  final double weight;
  final int time;
  final int transfers;
  final List<dynamic> bbox;
  final List<LatLng> coordinates;
  final List<RouteInstruction> instructions;
  final List<RouteLeg> legs;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final double ascend;
  final double descend;
  final List<LatLng> snappedWaypoints;

  PublicTransportRoute({
    required this.distance,
    required this.weight,
    required this.time,
    required this.transfers,
    required this.bbox,
    required this.coordinates,
    required this.instructions,
    required this.legs,
    this.departureTime,
    this.arrivalTime,
    required this.ascend,
    required this.descend,
    required this.snappedWaypoints,
  });

  // Helper method to calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double lat1Rad = point1.latitude * (math.pi / 180);
    double lat2Rad = point2.latitude * (math.pi / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (math.pi / 180);
    double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // Helper method to calculate total distance from coordinates list
  static double _calculateTotalDistance(List<LatLng> coordinates) {
    if (coordinates.length < 2) return 0.0;

    double totalDistance = 0.0;
    for (int i = 0; i < coordinates.length - 1; i++) {
      totalDistance += _calculateDistance(coordinates[i], coordinates[i + 1]);
    }

    return totalDistance;
  }

  factory PublicTransportRoute.fromJson(Map<String, dynamic> json) {
    final path = json['paths'][0];

    // Parse coordinates
    final coords = (path['points']?['coordinates'] ?? []) as List;
    final coordinates =
        coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();

    // Parse bbox
    final bboxList = (path['bbox'] ?? []) as List;
    final bbox = bboxList.map((b) => b.toDouble()).toList();

    // Parse snapped waypoints
    final snappedCoords =
        (path['snapped_waypoints']?['coordinates'] ?? []) as List;
    final snappedWaypoints = snappedCoords
        .map((c) => LatLng(c[1] as double, c[0] as double))
        .toList();

    // Parse instructions
    final instructionsJson = path['instructions'] as List? ?? [];
    final instructions = instructionsJson
        .map((inst) => RouteInstruction.fromJson(inst))
        .toList();

    // Parse legs
    final legsJson = path['legs'] as List? ?? [];
    final legs = legsJson.map((l) => RouteLeg.fromJson(l)).toList();

    // Calculate departure and arrival times from legs
    final dep =
        legs.isNotEmpty ? DateTime.tryParse(legs.first.departureTime) : null;
    final arr =
        legs.isNotEmpty ? DateTime.tryParse(legs.last.arrivalTime) : null;

    // Calculate distance - use API provided distance or calculate from coordinates
    double calculatedDistance = (path['distance'] ?? 0.0).toDouble();
    if (calculatedDistance == 0.0 && coordinates.isNotEmpty) {
      calculatedDistance = _calculateTotalDistance(coordinates);
    }

    return PublicTransportRoute(
      distance: calculatedDistance,
      weight: (path['weight'] ?? 0.0).toDouble(),
      time: path['time'] ?? 0,
      transfers: path['transfers'] ?? 0,
      bbox: bbox,
      coordinates: coordinates,
      instructions: instructions,
      legs: legs,
      departureTime: dep,
      arrivalTime: arr,
      ascend: (path['ascend'] ?? 0.0).toDouble(),
      descend: (path['descend'] ?? 0.0).toDouble(),
      snappedWaypoints: snappedWaypoints,
    );
  }

  // Formatting methods
  String get formattedDuration {
    final dep = departureTime;
    final arr = arrivalTime;
    if (dep != null && arr != null) {
      final duration = arr.difference(dep);
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }

    // Fallback to time field, but assume it might be in different units
    // Try different interpretations
    if (time > 0) {
      // Try as seconds first
      var hours = time ~/ 3600;
      var minutes = (time % 3600) ~/ 60;

      if (hours > 24) {
        // Likely milliseconds
        hours = time ~/ 3600000;
        minutes = (time % 3600000) ~/ 60000;
      }

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${minutes}m';
      }
    }

    return '0m';
  }

  String get transfersText {
    if (transfers == 0) {
      return 'Direct';
    } else if (transfers == 1) {
      return '1 transfer';
    } else {
      return '$transfers transfers';
    }
  }

  String get formattedDistance {
    if (distance >= 1000) {
      final km = distance / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${distance.toInt()} m';
    }
  }
}

class RouteInstruction {
  final double distance;
  final double? heading;
  final double? lastHeading;
  final int sign;
  final String text;
  final int time;
  final String streetName;
  final List<int>? interval;

  RouteInstruction({
    required this.distance,
    required this.heading,
    this.lastHeading,
    required this.sign,
    required this.text,
    required this.time,
    required this.streetName,
    this.interval,
  });

  factory RouteInstruction.fromJson(Map<String, dynamic> json) {
    final intervalList = json['interval'] as List?;
    final interval = intervalList?.map((i) => i as int).toList();

    return RouteInstruction(
      distance: (json['distance'] ?? 0).toDouble(),
      heading: json['heading']?.toDouble(),
      lastHeading: json['last_heading']?.toDouble(),
      sign: json['sign'] ?? 0,
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
      streetName: json['street_name'] ?? '',
      interval: interval,
    );
  }
}

class TransitStop {
  final String stopId;
  final String stopName;
  final LatLng geometry;
  final DateTime? arrivalTime;
  final DateTime? plannedArrivalTime;
  final bool arrivalCancelled;
  final DateTime? departureTime;
  final DateTime? plannedDepartureTime;
  final bool departureCancelled;

  TransitStop({
    required this.stopId,
    required this.stopName,
    required this.geometry,
    this.arrivalTime,
    this.plannedArrivalTime,
    required this.arrivalCancelled,
    this.departureTime,
    this.plannedDepartureTime,
    required this.departureCancelled,
  });

  factory TransitStop.fromJson(Map<String, dynamic> json) {
    final coords = json['geometry']['coordinates'];
    final geometry = LatLng(coords[1] as double, coords[0] as double);

    return TransitStop(
      stopId: json['stop_id'] ?? '',
      stopName: json['stop_name'] ?? '',
      geometry: geometry,
      arrivalTime: json['arrival_time'] != null
          ? DateTime.tryParse(json['arrival_time'])
          : null,
      plannedArrivalTime: json['planned_arrival_time'] != null
          ? DateTime.tryParse(json['planned_arrival_time'])
          : null,
      arrivalCancelled: json['arrival_cancelled'] ?? false,
      departureTime: json['departure_time'] != null
          ? DateTime.tryParse(json['departure_time'])
          : null,
      plannedDepartureTime: json['planned_departure_time'] != null
          ? DateTime.tryParse(json['planned_departure_time'])
          : null,
      departureCancelled: json['departure_cancelled'] ?? false,
    );
  }

  // Formatting method
  String get formattedArrivalTime {
    final time = arrivalTime ?? plannedArrivalTime;
    if (time == null) return '--:--';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class RouteLeg {
  final String type;
  final String departureLocation;
  final List<LatLng> geometry;
  final double distance;
  final List<RouteInstruction> instructions;
  final String departureTime;
  final String arrivalTime;
  final Map<String, dynamic> details;

  // Transit-specific fields
  final String? feedId;
  final bool? isInSameVehicleAsPrevious;
  final String? tripHeadsign;
  final int? travelTime;
  final List<TransitStop>? stops;
  final String? tripId;
  final String? routeId;

  RouteLeg({
    required this.type,
    required this.departureLocation,
    required this.geometry,
    required this.distance,
    required this.instructions,
    required this.departureTime,
    required this.arrivalTime,
    required this.details,
    this.feedId,
    this.isInSameVehicleAsPrevious,
    this.tripHeadsign,
    this.travelTime,
    this.stops,
    this.tripId,
    this.routeId,
  });

  factory RouteLeg.fromJson(Map<String, dynamic> json) {
    // Parse geometry coordinates
    final coords = json['geometry']?['coordinates'] ?? [];
    final geometry = (coords as List)
        .map((c) => LatLng(c[1] as double, c[0] as double))
        .toList();

    // Parse instructions
    final instructionsJson = json['instructions'] as List? ?? [];
    final instructions = instructionsJson
        .map((inst) => RouteInstruction.fromJson(inst))
        .toList();

    // Parse stops for transit legs
    List<TransitStop>? stops;
    if (json['stops'] != null) {
      final stopsJson = json['stops'] as List;
      stops = stopsJson.map((stop) => TransitStop.fromJson(stop)).toList();
    }

    return RouteLeg(
      type: json['type'] ?? 'walk',
      departureLocation: json['departure_location'] ?? 'Unknown',
      geometry: geometry,
      distance: (json['distance'] ?? 0.0).toDouble(),
      instructions: instructions,
      departureTime: json['departure_time'] ?? '',
      arrivalTime: json['arrival_time'] ?? '',
      details: json['details'] ?? {},
      feedId: json['feed_id'],
      isInSameVehicleAsPrevious: json['is_in_same_vehicle_as_previous'],
      tripHeadsign: json['trip_headsign'],
      travelTime: json['travel_time'],
      stops: stops,
      tripId: json['trip_id'],
      routeId: json['route_id'],
    );
  }

  bool get isWalkingLeg => type == 'walk';
  bool get isPublicTransportLeg => type == 'pt';

  // Helper methods for transit legs
  String get displayName {
    if (isPublicTransportLeg && tripHeadsign != null) {
      return tripHeadsign!;
    }
    return type == 'walk' ? 'Walking' : 'Transit';
  }

  int get numberOfStops => stops?.length ?? 0;

  Duration get duration {
    final dep = DateTime.tryParse(departureTime);
    final arr = DateTime.tryParse(arrivalTime);
    if (dep != null && arr != null) {
      return arr.difference(dep);
    }

    if (travelTime != null) {
      return Duration(milliseconds: travelTime!);
    }

    return Duration.zero;
  }

  // Formatting methods
  String get formattedDepartureTime {
    final depTime = DateTime.tryParse(departureTime);
    if (depTime == null) return '--:--';

    final hour = depTime.hour.toString().padLeft(2, '0');
    final minute = depTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedArrivalTime {
    final arrTime = DateTime.tryParse(arrivalTime);
    if (arrTime == null) return '--:--';

    final hour = arrTime.hour.toString().padLeft(2, '0');
    final minute = arrTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String get formattedDuration {
    final dur = duration;
    final hours = dur.inHours;
    final minutes = dur.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class RouteRequest {
  final LatLng origin;
  final LatLng destination;
  final DateTime departureTime;
  final String profile;

  RouteRequest({
    required this.origin,
    required this.destination,
    required this.departureTime,
    this.profile = 'pt',
  });

  Map<String, String> toQueryParameters(String baseUrl) {
    final String originParam = '${origin.latitude}%2C${origin.longitude}';
    final String destinationParam =
        '${destination.latitude}%2C${destination.longitude}';
    final departureTimeParam =
        departureTime.toUtc().toIso8601String().replaceAll('ZZ', 'Z');

    return {
      'originPoint': originParam,
      'destinationPoint': destinationParam,
      'profile': profile,
      'pt.earliest_departure_time': departureTimeParam,
    };
  }

  String buildUrl(String baseUrl) {
    final originParam = '${origin.latitude},${origin.longitude}';
    final destinationParam = '${destination.latitude},${destination.longitude}';
    final departureTimeParam =
        '${departureTime.toUtc().toIso8601String().split('.').first}Z';

    return "$baseUrl/route?pt.earliest_departure_time=$departureTimeParam&pt.arrive_by=false&locale=en-US&profile=pt&pt.profile=false&pt.access_profile=foot&pt.beta_access_time=1&pt.egress_profile=foot&pt.beta_egress_time=1&pt.profile_duration=PT120M&pt.limit_street_time=PT200M&pt.ignore_transfers=false&point=$originParam&point=$destinationParam";
  }
}

// Additional classes for full API response handling
class ApiHints {
  final int visitedNodesSum;
  final int visitedNodesAverage;

  ApiHints({
    required this.visitedNodesSum,
    required this.visitedNodesAverage,
  });

  factory ApiHints.fromJson(Map<String, dynamic> json) {
    return ApiHints(
      visitedNodesSum: json['visited_nodes.sum'] ?? 0,
      visitedNodesAverage: json['visited_nodes.average'] ?? 0,
    );
  }
}

class ApiInfo {
  final List<String> copyrights;
  final int took;

  ApiInfo({
    required this.copyrights,
    required this.took,
  });

  factory ApiInfo.fromJson(Map<String, dynamic> json) {
    final copyrightsJson = json['copyrights'] as List? ?? [];
    final copyrights = copyrightsJson.map((c) => c.toString()).toList();

    return ApiInfo(
      copyrights: copyrights,
      took: json['took'] ?? 0,
    );
  }
}

class PublicTransportResponse {
  final ApiHints hints;
  final ApiInfo info;
  final List<PublicTransportRoute> paths;

  PublicTransportResponse({
    required this.hints,
    required this.info,
    required this.paths,
  });

  factory PublicTransportResponse.fromJson(Map<String, dynamic> json) {
    final pathsJson = json['paths'] as List? ?? [];
    final paths = pathsJson.map((path) {
      return PublicTransportRoute.fromJson({
        'paths': [path]
      });
    }).toList();

    return PublicTransportResponse(
      hints: ApiHints.fromJson(json['hints'] ?? {}),
      info: ApiInfo.fromJson(json['info'] ?? {}),
      paths: paths,
    );
  }

  PublicTransportRoute? get bestRoute => paths.isNotEmpty ? paths.first : null;
}
