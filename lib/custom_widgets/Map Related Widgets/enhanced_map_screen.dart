import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

// A simple data class to hold both coordinates and a readable address.
class PointData {
  final LatLng point;
  final String address;
  PointData(this.point, this.address);
}

// Enum to define what the user is currently selecting on the map.
enum PointSelectionMode { none, origin, destination }

// Enhanced route data classes
class PublicTransportRoute {
  final List<LatLng> coordinates;
  final List<RouteLeg> legs;
  final Duration totalDuration;
  final double totalDistance;
  final String summary;

  PublicTransportRoute({
    required this.coordinates,
    required this.legs,
    required this.totalDuration,
    required this.totalDistance,
    required this.summary,
  });
}

class RouteLeg {
  final List<LatLng> geometry;
  final Duration duration;
  final double distance;
  final String mode; // 'walking', 'bus', 'train', etc.
  final String instruction;
  final List<TransitStop>? stops;
  final String? routeName;
  final String? routeColor;

  RouteLeg({
    required this.geometry,
    required this.duration,
    required this.distance,
    required this.mode,
    required this.instruction,
    this.stops,
    this.routeName,
    this.routeColor,
  });

  bool get isWalkingLeg => mode == 'walking' || mode == 'foot';
  bool get isPublicTransportLeg => !isWalkingLeg;
}

class TransitStop {
  final LatLng geometry;
  final String name;
  final String? code;

  TransitStop({
    required this.geometry,
    required this.name,
    this.code,
  });
}

class OpenstreetmapScreen extends StatefulWidget {
  // Callback functions to notify the parent widget of changes.
  final ValueChanged<PointData?> onOriginChanged;
  final ValueChanged<PointData?> onDestinationChanged;
  final ValueChanged<List<LatLng>>? onRouteChanged;
  final ValueChanged<PublicTransportRoute?>? onPublicTransportRouteChanged;

  // Input parameters from the parent widget.
  final PointSelectionMode selectionMode;
  final Stream<String> searchStream;

  const OpenstreetmapScreen({
    super.key,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    this.onRouteChanged,
    this.onPublicTransportRouteChanged,
    this.selectionMode = PointSelectionMode.none,
    required this.searchStream,
  });

  @override
  State<OpenstreetmapScreen> createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  late StreamSubscription<String> _searchSubscription;

  bool isLoading = true;

  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _route = [];
  PublicTransportRoute? _publicTransportRoute;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    // Listen to the search stream provided by the parent.
    _searchSubscription = widget.searchStream.listen((query) {
      if (query.isNotEmpty) {
        _searchLocation(query);
      }
    });
  }

  @override
  void dispose() {
    // Clean up the stream subscription to prevent memory leaks.
    _searchSubscription.cancel();
    super.dispose();
  }

  // Initializes location services and sets the user's current location as the default origin.
  Future<void> _initializeLocation() async {
    bool permissionGranted = await _checkRequestPermission();
    if (!permissionGranted) {
      setState(() => isLoading = false);
      // Fallback to a default location if permission is denied
      const fallbackPoint = LatLng(51.5074, -0.1278);
      _updateOrigin(fallbackPoint, "London");

      // Wait for the first frame to render before moving the map
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(fallbackPoint, 13);
        }
      });
      return;
    }

    try {
      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final initialPoint =
            LatLng(locationData.latitude!, locationData.longitude!);
        _updateOrigin(initialPoint);

        // Wait for the first frame to render before moving the map
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(initialPoint, 15);
          }
        });
      }

      setState(() => isLoading = false);

      _location.onLocationChanged.listen((newLocation) {
        if (newLocation.latitude != null && newLocation.longitude != null) {
          // This can be used to continuously update the user's blue dot,
          // but we won't automatically re-assign the origin here unless specified.
        }
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage("Error initializing location: $e");
    }
  }

  // Sets or updates the origin point.
  Future<void> _updateOrigin(LatLng point, [String? knownAddress]) async {
    setState(() => _origin = point);
    final address = knownAddress ?? await _reverseGeocode(point);
    widget.onOriginChanged(PointData(point, address));
    if (_destination != null) {
      await _fetchEnhancedRoute();
    }
  }

  // Sets or updates the destination point.
  Future<void> _updateDestination(LatLng point, [String? knownAddress]) async {
    setState(() => _destination = point);
    final address = knownAddress ?? await _reverseGeocode(point);
    widget.onDestinationChanged(PointData(point, address));
    if (_origin != null) {
      await _fetchEnhancedRoute();
    }
    _mapController.move(point, 13);
  }

  // Handles map taps to select points.
  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (widget.selectionMode == PointSelectionMode.destination) {
      _updateDestination(point);
    } else if (widget.selectionMode == PointSelectionMode.origin) {
      _updateOrigin(point);
    }
  }

  // Converts coordinates (LatLng) to a human-readable address.
  Future<String> _reverseGeocode(LatLng point) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}');
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'AppName/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Unknown Location';
      }
    } catch (e) {
      return 'Could not find address';
    }
    return 'Unknown Location';
  }

  // Enhanced search function that can handle both destination and origin setting
  Future<void> _searchLocation(String location) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1");
    try {
      final response =
          await http.get(url, headers: {'User-Agent': 'AppName/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]["lat"]);
          final lon = double.parse(data[0]["lon"]);
          final displayName = data[0]['display_name'];
          final searchPoint = LatLng(lat, lon);

          // Depending on selection mode, set either origin or destination
          if (widget.selectionMode == PointSelectionMode.origin) {
            _updateOrigin(searchPoint, displayName);
          } else {
            _updateDestination(searchPoint, displayName);
          }
        } else {
          _showMessage("Location not found. Please try another search.");
        }
      } else {
        _showMessage("Failed to fetch location. Please try again later.");
      }
    } catch (e) {
      _showMessage("An error occurred during search.");
    }
  }

  // Enhanced route fetching with public transport support
  Future<void> _fetchEnhancedRoute() async {
    if (_origin == null || _destination == null) return;

    try {
      // Try to fetch public transport route first
      final ptRoute = await _fetchPublicTransportRoute();
      if (ptRoute != null) {
        setState(() {
          _publicTransportRoute = ptRoute;
          _route = ptRoute.coordinates;
        });
        widget.onRouteChanged?.call(ptRoute.coordinates);
        widget.onPublicTransportRouteChanged?.call(ptRoute);
        return;
      }

      // Fallback to driving route if PT route fails
      await _fetchDrivingRoute();
    } catch (e) {
      _showMessage("Error fetching route: $e");
      // Fallback to driving route
      await _fetchDrivingRoute();
    }
  }

  // Fetch public transport route (enhanced method)
  Future<PublicTransportRoute?> _fetchPublicTransportRoute() async {
    if (_origin == null || _destination == null) return null;

    try {
      // This is a mock implementation - replace with actual PT API
      // For now, we'll create a hybrid route with walking + simulated PT
      final List<RouteLeg> legs = [];
      final List<LatLng> allCoordinates = [];

      // Walking leg to transit stop
      final walkingToStop = await _createWalkingLeg(
        _origin!,
        _interpolatePoint(_origin!, _destination!, 0.3),
        "Walk to bus stop",
      );
      legs.add(walkingToStop);
      allCoordinates.addAll(walkingToStop.geometry);

      // Simulated bus leg
      final busLeg = await _createTransitLeg(
        _interpolatePoint(_origin!, _destination!, 0.3),
        _interpolatePoint(_origin!, _destination!, 0.7),
        "Take Bus Route 42",
        "bus",
      );
      legs.add(busLeg);
      allCoordinates.addAll(busLeg.geometry);

      // Walking leg from transit stop to destination
      final walkingFromStop = await _createWalkingLeg(
        _interpolatePoint(_origin!, _destination!, 0.7),
        _destination!,
        "Walk to destination",
      );
      legs.add(walkingFromStop);
      allCoordinates.addAll(walkingFromStop.geometry);

      final totalDuration = legs.fold(
        Duration.zero,
        (prev, leg) => prev + leg.duration,
      );

      final totalDistance = legs.fold(
        0.0,
        (prev, leg) => prev + leg.distance,
      );

      return PublicTransportRoute(
        coordinates: allCoordinates,
        legs: legs,
        totalDuration: totalDuration,
        totalDistance: totalDistance,
        summary: "Public transport route via Bus Route 42",
      );
    } catch (e) {
      print("Error fetching PT route: $e");
      return null;
    }
  }

  // Helper method to create walking leg
  Future<RouteLeg> _createWalkingLeg(
    LatLng start,
    LatLng end,
    String instruction,
  ) async {
    final geometry = await _getRouteGeometry(start, end, 'foot');
    final distance = _calculateDistance(start, end);

    return RouteLeg(
      geometry: geometry,
      duration:
          Duration(minutes: (distance * 12).round()), // ~5 km/h walking speed
      distance: distance,
      mode: 'walking',
      instruction: instruction,
    );
  }

  // Helper method to create transit leg
  Future<RouteLeg> _createTransitLeg(
    LatLng start,
    LatLng end,
    String instruction,
    String mode,
  ) async {
    final geometry = await _getRouteGeometry(start, end, 'driving');
    final distance = _calculateDistance(start, end);

    // Create mock transit stops
    final stops = <TransitStop>[
      TransitStop(geometry: start, name: "Bus Stop A"),
      TransitStop(geometry: end, name: "Bus Stop B"),
    ];

    return RouteLeg(
      geometry: geometry,
      duration:
          Duration(minutes: (distance * 2).round()), // ~30 km/h average speed
      distance: distance,
      mode: mode,
      instruction: instruction,
      stops: stops,
      routeName: "Route 42",
      routeColor: "#FF0000",
    );
  }

  // Helper method to get route geometry
  Future<List<LatLng>> _getRouteGeometry(
      LatLng start, LatLng end, String profile) async {
    final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/$profile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=polyline");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          return _decodePolyline(geometry);
        }
      }
    } catch (e) {
      print("Error getting route geometry: $e");
    }

    // Fallback to straight line
    return [start, end];
  }

  // Fallback driving route method
  Future<void> _fetchDrivingRoute() async {
    if (_origin == null || _destination == null) return;

    final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/${_origin!.longitude},${_origin!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final points = _decodePolyline(geometry);
          setState(() {
            _route = points;
            _publicTransportRoute = null;
          });
          // Notify parent widget about route changes
          widget.onRouteChanged?.call(points);
          widget.onPublicTransportRouteChanged?.call(null);
        }
      } else {
        _showMessage("Failed to fetch route.");
      }
    } catch (e) {
      _showMessage("An error occurred fetching the route.");
    }
  }

  // Helper methods
  LatLng _interpolatePoint(LatLng start, LatLng end, double ratio) {
    final lat = start.latitude + (end.latitude - start.latitude) * ratio;
    final lng = start.longitude + (end.longitude - start.longitude) * ratio;
    return LatLng(lat, lng);
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, start, end);
  }

  // Decodes an encoded polyline string into a list of LatLng points.
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  // Utility to show a SnackBar message.
  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // Boilerplate for checking and requesting location permissions.
  Future<bool> _checkRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) return false;
    }
    return true;
  }

  // Public method to clear origin
  void clearOrigin() {
    setState(() {
      _origin = null;
      _route.clear();
      _publicTransportRoute = null;
    });
    widget.onOriginChanged(null);
    widget.onPublicTransportRouteChanged?.call(null);
  }

  // Public method to clear destination
  void clearDestination() {
    setState(() {
      _destination = null;
      _route.clear();
      _publicTransportRoute = null;
    });
    widget.onDestinationChanged(null);
    widget.onPublicTransportRouteChanged?.call(null);
  }

  // Public method to swap origin and destination
  void swapOriginDestination() {
    if (_origin != null && _destination != null) {
      final tempOrigin = _origin;
      final tempDest = _destination;

      setState(() {
        _origin = tempDest;
        _destination = tempOrigin;
      });

      // Update addresses
      _reverseGeocode(_origin!).then((address) {
        widget.onOriginChanged(PointData(_origin!, address));
      });

      _reverseGeocode(_destination!).then((address) {
        widget.onDestinationChanged(PointData(_destination!, address));
      });

      _fetchEnhancedRoute();
    }
  }

  // Build enhanced route polylines
  List<Polyline> _buildRoutePolylines() {
    List<Polyline> polylines = [];

    if (_publicTransportRoute != null) {
      // Individual leg polylines with different colors
      for (int i = 0; i < _publicTransportRoute!.legs.length; i++) {
        final leg = _publicTransportRoute!.legs[i];
        if (leg.geometry.isNotEmpty) {
          Color legColor;
          double strokeWidth;

          if (leg.isWalkingLeg) {
            legColor = Colors.orange;
            strokeWidth = 3.0;
          } else {
            legColor = Colors.blue;
            strokeWidth = 6.0;
          }

          polylines.add(
            Polyline(
              points: leg.geometry,
              strokeWidth: strokeWidth,
              color: legColor,
            ),
          );
        }
      }
    } else if (_route.isNotEmpty) {
      // Simple driving route
      polylines.add(
        Polyline(
          points: _route,
          strokeWidth: 5,
          color: Colors.blueAccent,
        ),
      );
    }

    return polylines;
  }

  // Build enhanced route markers
  List<Marker> _buildRouteMarkers() {
    List<Marker> markers = [];

    // Origin marker
    if (_origin != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _origin!,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }

    // Destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _destination!,
          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
      );
    }

    // Transit stop markers
    if (_publicTransportRoute != null) {
      for (final leg in _publicTransportRoute!.legs) {
        if (leg.isPublicTransportLeg && leg.stops != null) {
          for (final stop in leg.stops!) {
            markers.add(
              Marker(
                point: stop.geometry,
                width: 20,
                height: 20,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _origin ?? const LatLng(51.5074, -0.1278),
              initialZoom: 13,
              onTap: _handleMapTap,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.transport_app',
                maxZoom: 19,
              ),
              CurrentLocationLayer(
                alignPositionOnUpdate: AlignOnUpdate.once,
                alignDirectionOnUpdate: AlignOnUpdate.never,
                style: const LocationMarkerStyle(
                  marker: DefaultLocationMarker(
                    child: Icon(
                      Icons.navigation,
                      color: Colors.white,
                    ),
                  ),
                  markerSize: Size(40, 40),
                  markerDirection: MarkerDirection.heading,
                ),
              ),
              // Enhanced route polylines
              PolylineLayer(polylines: _buildRoutePolylines()),
              // Enhanced route markers
              MarkerLayer(markers: _buildRouteMarkers()),
            ],
          );
  }
}
