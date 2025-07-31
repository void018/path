import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';
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
  bool isRouteFetching = false; // New loading state for route fetching
  String routeFetchingMessage =
      "Finding route..."; // Message to show during loading

  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _route = [];
  PublicTransportRoute? _publicTransportRoute;
  double _mapRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    // Listen to the search stream provided by the parent.
    _searchSubscription = widget.searchStream.listen((query) {
      if (query.isNotEmpty && !isRouteFetching) {
        // Prevent search during route fetching
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

  Future<void> _initializeLocation() async {
    final status = await Permission.location.request();

    if (!status.isGranted) {
      setState(() => isLoading = false);
      const fallbackPoint = LatLng(51.5074, -0.1278);
      _updateOrigin(fallbackPoint, "London");

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(initialPoint, 15);
          }
        });
      }

      setState(() => isLoading = false);

      _location.onLocationChanged.listen((newLocation) {
        // Optionally handle live location updates
      });
    } catch (e) {
      setState(() => isLoading = false);
      _showMessage("Error initializing location: $e");
    }
  }

  // Sets or updates the origin point.
  Future<void> _updateOrigin(LatLng point, [String? knownAddress]) async {
    if (isRouteFetching) return; // Prevent updates during route fetching

    setState(() => _origin = point);
    final address = knownAddress ?? await _reverseGeocode(point);
    widget.onOriginChanged(PointData(point, address));
    if (_destination != null) {
      await _fetchRoute();
    }
  }

  // Sets or updates the destination point.
  Future<void> _updateDestination(LatLng point, [String? knownAddress]) async {
    if (isRouteFetching) return; // Prevent updates during route fetching

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
    if (isRouteFetching)
      return; // Prevent map interaction during route fetching

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
    if (isRouteFetching) return; // Prevent search during route fetching

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

  // Enhanced route fetching with proper loading states and error handling
  Future<void> _fetchRoute() async {
    if (_origin == null || _destination == null || isRouteFetching) return;

    setState(() {
      isRouteFetching = true;
      routeFetchingMessage = "Finding route...";
    });

    try {
      // Add a timeout for the API call
      final route = await _service
          .getRoute(
        origin: _origin!,
        destination: _destination!,
        departureTime: DateTime.now(),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException(
              'Request timed out', const Duration(seconds: 30));
        },
      );

      if (route != null) {
        setState(() {
          _publicTransportRoute = route;
          _route = route.coordinates;
          isRouteFetching = false;
        });
        widget.onRouteChanged?.call(route.coordinates);
        widget.onPublicTransportRouteChanged.call(route);
      } else {
        setState(() {
          isRouteFetching = false;
        });
        _showMessage("No routes found between the selected locations.");
      }
    } on TimeoutException catch (_) {
      setState(() {
        isRouteFetching = false;
      });
      _showMessage(
          "Request timed out. The server might be starting up. Please try again in a moment.");
    } on http.ClientException catch (e) {
      setState(() {
        isRouteFetching = false;
      });
      if (e.message.contains('Connection refused') ||
          e.message.contains('No address associated') ||
          e.message.contains('Network is unreachable')) {
        _showMessage(
            "Server is not available. It might be starting up. Please wait a moment and try again.");
      } else {
        _showMessage("Network error: ${e.message}");
      }
    } catch (e) {
      setState(() {
        isRouteFetching = false;
      });

      // Check if it's a server wake-up scenario
      String errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('502') ||
          errorMessage.contains('503') ||
          errorMessage.contains('504') ||
          errorMessage.contains('connection refused') ||
          errorMessage.contains('server error') ||
          errorMessage.contains('bad gateway')) {
        setState(() {
          routeFetchingMessage = "Server is waking up...";
          isRouteFetching = true;
        });

        // Wait a bit and retry once
        await Future.delayed(const Duration(seconds: 3));
        try {
          final retryRoute = await _service
              .getRoute(
                origin: _origin!,
                destination: _destination!,
                departureTime: DateTime.now(),
              )
              .timeout(const Duration(seconds: 45));

          if (retryRoute != null) {
            setState(() {
              _publicTransportRoute = retryRoute;
              _route = retryRoute.coordinates;
              isRouteFetching = false;
            });
            widget.onRouteChanged?.call(retryRoute.coordinates);
            widget.onPublicTransportRouteChanged.call(retryRoute);
          } else {
            setState(() {
              isRouteFetching = false;
            });
            _showMessage("No routes found after server wake-up.");
          }
        } catch (retryError) {
          setState(() {
            isRouteFetching = false;
          });
          _showMessage(
              "Server is still starting up. Please try again in a few moments.");
        }
      } else {
        _showMessage("Error fetching route: $e");
      }
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
      ));
    }
  }

  // Public method to clear origin
  void clearOrigin() {
    if (isRouteFetching) return; // Prevent clearing during route fetching

    setState(() {
      _origin = null;
      _route.clear();
      _publicTransportRoute = null;
    });
    widget.onOriginChanged(null);
  }

  // Public method to clear destination
  void clearDestination() {
    if (isRouteFetching) return; // Prevent clearing during route fetching

    setState(() {
      _destination = null;
      _route.clear();
      _publicTransportRoute = null;
    });
    widget.onDestinationChanged(null);
  }

  // Build route polylines with enhanced styling
  List<Polyline> _buildRoutePolylines() {
    List<Polyline> polylines = [];

    if (_publicTransportRoute != null) {
      for (final leg in _publicTransportRoute!.legs) {
        if (leg.geometry.isEmpty) continue;

        Color legColor;
        double strokeWidth;
        bool isDotted = false;

        if (leg.isWalkingLeg) {
          legColor = const Color.fromARGB(255, 0, 0, 0);
          strokeWidth = 5.0;
          isDotted = true;
        } else if (leg.isPublicTransportLeg) {
          legColor = leg.routeColor!;
          strokeWidth = 5.0;
        } else {
          legColor = Colors.blue;
          strokeWidth = 6.0;
        }

        polylines.add(
          Polyline(
              points: leg.geometry,
              strokeWidth: strokeWidth,
              color: legColor,
              pattern:
                  isDotted ? StrokePattern.dotted() : StrokePattern.solid()),
        );
      }
    } else if (_route.isNotEmpty) {
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

  List<Marker> _buildRouteMarkers() {
    List<Marker> markers = [];

    // Origin marker
    if (_origin != null) {
      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: _origin!,
          child: Transform.rotate(
            angle: -_mapRotation * (3.1415926535 / 180),
            child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
          ),
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
          child: Transform.rotate(
            angle: -_mapRotation * (3.1415926535 / 180),
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      );
    }

    // Transit stop markers (only first and last stop of each leg)
    if (_publicTransportRoute != null) {
      for (final leg in _publicTransportRoute!.legs) {
        if (leg.isPublicTransportLeg &&
            leg.stops != null &&
            leg.stops!.length >= 2) {
          final firstStop = leg.stops!.first;
          final lastStop = leg.stops!.last;

          for (final stop in [firstStop, lastStop]) {
            markers.add(
              Marker(
                point: stop.geometry,
                width: 30,
                height: 30,
                child: Transform.rotate(
                  angle: -_mapRotation * (3.1415926535 / 180),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 16,
                    ),
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
    return Stack(
      children: [
        // Main map
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _origin ?? const LatLng(51.5074, -0.1278),
                  initialZoom: 13,
                  onTap: _handleMapTap,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: InteractionOptions(
                    flags: isRouteFetching
                        ? InteractiveFlag
                            .none // Disable all interactions during route fetching
                        : InteractiveFlag.all,
                  ),
                  onPositionChanged: (MapCamera pos, bool hasGesture) {
                    if (!isRouteFetching) {
                      setState(() {
                        _mapRotation = pos.rotation;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.void_path',
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
              ),

        // Loading overlay during route fetching
        if (isRouteFetching)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        routeFetchingMessage,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please wait...",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
