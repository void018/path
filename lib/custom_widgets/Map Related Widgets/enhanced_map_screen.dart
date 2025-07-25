import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

import 'pt_route_model.dart';
import 'route_search_widget.dart';
import 'route_details_widget.dart';

class EnhancedOpenstreetmapScreen extends StatefulWidget {
  const EnhancedOpenstreetmapScreen({super.key});

  @override
  State<EnhancedOpenstreetmapScreen> createState() =>
      _EnhancedOpenstreetmapScreenState();
}

class _EnhancedOpenstreetmapScreenState
    extends State<EnhancedOpenstreetmapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Location _location = Location();
  bool isLoading = true;

  LatLng? _currentLocation;
  PublicTransportRoute? _currentRoute;
  bool _showRouteSearch = false;
  bool _showRouteDetails = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      if (!await _checkRequestPermission()) {
        setState(() => isLoading = false);
        _showErrorMessage("Location permission denied.");
        return;
      }

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final newLocation =
            LatLng(locationData.latitude!, locationData.longitude!);

        if (mounted) {
          setState(() {
            _currentLocation = newLocation;
          });

          // Move map after setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(newLocation, 15.0);
            }
          });
        }
      }

      _location.onLocationChanged.listen((LocationData newLocationData) {
        if (mounted &&
            newLocationData.latitude != null &&
            newLocationData.longitude != null) {
          setState(() {
            _currentLocation =
                LatLng(newLocationData.latitude!, newLocationData.longitude!);
          });
        }
      });
    } catch (e) {
      _showErrorMessage("Failed to get location: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<bool> _checkRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    } else {
      _showErrorMessage("Cannot find current location.");
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRouteFound(PublicTransportRoute route) {
    if (!mounted) return;

    setState(() {
      _currentRoute = route;
      _showRouteSearch = false;
      _showRouteDetails = true;
    });

    // Fit map to route bounds
    if (route.coordinates.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(route.coordinates),
                padding: const EdgeInsets.all(50.0),
              ),
            );
          } catch (e) {
            print("Error fitting bounds: $e");
          }
        }
      });
    }

    _showSuccessMessage("Route found!");
  }

  void _clearRoute() {
    setState(() {
      _currentRoute = null;
      _showRouteDetails = false;
    });
  }

  List<Polyline> _buildRoutePolylines() {
    if (_currentRoute == null) return [];

    List<Polyline> polylines = [];

    // Main route polyline
    if (_currentRoute!.coordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          points: _currentRoute!.coordinates,
          strokeWidth: 5.0,
          color: Colors.blueAccent,
        ),
      );
    }

    // Individual leg polylines with different colors
    for (int i = 0; i < _currentRoute!.legs.length; i++) {
      final leg = _currentRoute!.legs[i];
      if (leg.geometry.isNotEmpty) {
        Color legColor;
        if (leg.isWalkingLeg) {
          legColor = Colors.orange;
        } else {
          legColor = Colors.blue;
        }

        polylines.add(
          Polyline(
            points: leg.geometry,
            strokeWidth: leg.isWalkingLeg ? 3.0 : 6.0,
            color: legColor,
          ),
        );
      }
    }

    return polylines;
  }

  List<Marker> _buildRouteMarkers() {
    if (_currentRoute == null) return [];

    List<Marker> markers = [];

    // Add markers for transit stops
    for (final leg in _currentRoute!.legs) {
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

    // Start and end markers
    if (_currentRoute!.coordinates.isNotEmpty) {
      // Start marker
      markers.add(
        Marker(
          point: _currentRoute!.coordinates.first,
          width: 30,
          height: 30,
          child: const Icon(
            Icons.location_on,
            color: Colors.green,
            size: 30,
          ),
        ),
      );

      // End marker
      markers.add(
        Marker(
          point: _currentRoute!.coordinates.last,
          width: 30,
          height: 30,
          child: const Icon(
            Icons.flag,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Public Transport Map"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_currentLocation != null)
            IconButton(
              onPressed: _centerOnCurrentLocation,
              icon: const Icon(Icons.my_location),
              tooltip: "Center on me",
            ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ??
                  const LatLng(15.5874, 32.5438), // Khartoum coordinates
              initialZoom: 13.0,
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
              if (_currentLocation != null)
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
              // Route polylines
              if (_currentRoute != null)
                PolylineLayer(
                  polylines: _buildRoutePolylines(),
                ),
              // Route markers
              if (_currentRoute != null)
                MarkerLayer(
                  markers: _buildRouteMarkers(),
                ),
            ],
          ),

          // Loading indicator
          if (isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading location...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Route search widget
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: _showRouteSearch ? 0 : -400,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SafeArea(
                child: RouteSearchWidget(
                  onRouteFound: _handleRouteFound,
                  onError: _showErrorMessage,
                  currentLocation: _currentLocation,
                ),
              ),
            ),
          ),

          // Route details widget
          if (_currentRoute != null && _showRouteDetails)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: RouteDetailsWidget(
                  route: _currentRoute!,
                  onClear: _clearRoute,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showRouteSearch = !_showRouteSearch;
            if (_showRouteSearch) {
              _clearRoute();
            }
          });
        },
        tooltip: _showRouteSearch ? 'Close Search' : 'Search Route',
        backgroundColor: Theme.of(context).primaryColor,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _showRouteSearch ? Icons.close : Icons.directions,
            key: ValueKey(_showRouteSearch),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
