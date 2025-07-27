import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/pt_route_model.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/pt_route_service.dart';
import 'package:public_transportation/screens/unified_screen.dart';

// A simple data class to hold both coordinates and a readable address.
class PointData {
  final LatLng point;
  final String address;
  PointData(this.point, this.address);
}

// Enum to define what the user is currently selecting on the map.
enum PointSelectionMode { none, origin, destination }

// Enhanced route data classes

// class RouteLeg {
//   final List<LatLng> geometry;
//   final Duration duration;
//   final double distance;
//   final String mode; // 'walking', 'bus', 'train', 'driving', etc.
//   final String instruction;
//   final List<TransitStop>? stops;
//   final String? routeName;
//   final String? routeColor;

//   RouteLeg({
//     required this.geometry,
//     required this.duration,
//     required this.distance,
//     required this.mode,
//     required this.instruction,
//     this.stops,
//     this.routeName,
//     this.routeColor,
//   });

//   bool get isWalkingLeg => mode == 'walking' || mode == 'foot';
//   bool get isDrivingLeg => mode == 'driving';
//   bool get isPublicTransportLeg => !isWalkingLeg && !isDrivingLeg;
// }

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
  final ValueChanged<PublicTransportRoute> onPublicTransportRouteChanged;

  // Input parameters from the parent widget.
  final PointSelectionMode selectionMode;
  final Stream<String> searchStream;

  const OpenstreetmapScreen({
    super.key,
    required this.onOriginChanged,
    required this.onDestinationChanged,
    this.onRouteChanged,
    required this.onPublicTransportRouteChanged,
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
  final PublicTransportService _service = PublicTransportService();

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
      await _fetchRoute();
    }
  }

  // Sets or updates the destination point.
  Future<void> _updateDestination(LatLng point, [String? knownAddress]) async {
    setState(() => _destination = point);
    final address = knownAddress ?? await _reverseGeocode(point);
    widget.onDestinationChanged(PointData(point, address));
    if (_origin != null) {
      await _fetchRoute();
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

  // Enhanced route fetching - creates a PublicTransportRoute for driving routes
  Future<void> _fetchRoute() async {
    if (_origin == null || _destination == null) return;

    try {
      final route = await _service.getRoute(
        origin: _origin!,
        destination: _destination!,
        departureTime: DateTime.now(),
      );
      if (route != null) {
        setState(() {
          _publicTransportRoute = route;
          _route = route.coordinates;
        });
        widget.onRouteChanged?.call(route.coordinates);
        widget.onPublicTransportRouteChanged.call(route);
      } else {
        _showMessage("no routes found");
      }
    } catch (e) {
      _showMessage("Error fetching route: $e");
    }
  }

  // Fetches the driving route and wraps it in PublicTransportRoute structure

  // Helper method to calculate distance between two points
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
    widget.onPublicTransportRouteChanged;
  }

  // Public method to clear destination
  void clearDestination() {
    setState(() {
      _destination = null;
      _route.clear();
      _publicTransportRoute = null;
    });
    widget.onDestinationChanged(null);
    widget.onPublicTransportRouteChanged;
  }

  // Public method to swap origin and destination
  // void swapOriginDestination() {
  //   if (_origin != null && _destination != null) {
  //     final tempOrigin = _origin;
  //     final tempDest = _destination;

  //     setState(() {
  //       _origin = tempDest;
  //       _destination = tempOrigin;
  //     });

  //     // Update addresses
  //     _reverseGeocode(_origin!).then((address) {
  //       widget.onOriginChanged(PointData(_origin!, address));
  //     });

  //     _reverseGeocode(_destination!).then((address) {
  //       widget.onDestinationChanged(PointData(_destination!, address));
  //     });

  //     _fetchRoute();
  //   }
  // }

  // Build route polylines with enhanced styling
  List<Polyline> _buildRoutePolylines() {
    List<Polyline> polylines = [];

    if (_publicTransportRoute != null) {
      // Individual leg polylines with appropriate colors
      for (int i = 0; i < _publicTransportRoute!.legs.length; i++) {
        final leg = _publicTransportRoute!.legs[i];
        if (leg.geometry.isNotEmpty) {
          Color legColor;
          double strokeWidth;

          if (leg.isWalkingLeg) {
            legColor = Colors.orange;
            strokeWidth = 3.0;
          } else if (leg.isPublicTransportLeg) {
            legColor = Colors.blueAccent;
            strokeWidth = 5.0;
          } else {
            // Public transport
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
      // Fallback simple route
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

    // Transit stop markers (if any)
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
