import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  State<OpenstreetmapScreen> createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _locationController = TextEditingController();
  bool isLoading = true;

  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  Future<void> _inititalizeLocation() async {
    if (!await _checkRequestPermession()) return;

    _location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(
            locationData.latitude!,
            locationData.longitude!,
          );
          isLoading = false;
        });
      }
    });
  }

  Future<bool> _checkRequestPermession() async {
    bool serviceEnabled = await _location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted == PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    } else {
      errorMessage("Can not find current location.");
    }
  }

  Future<void> _fetchCoordinatesPoint(String location) async {
    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1");
    final resopnse = await http.get(url);
    if (resopnse.statusCode == 200) {
      final data = json.decode(resopnse.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]["lat"]);
        final lon = double.parse(data[0]["lon"]);

        setState(() {
          _destination = LatLng(lat, lon);
        });
        await _fetchRoute();
      } else {
        errorMessage("Location not found please try another search");
      }
    } else {
      errorMessage("failed to fetch location, try againg later");
    }
  }

  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("data")));
  }

  void _decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints =
        polylinePoints.decodePolyline(encodedPolyline);

    setState(() {
      _route = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    });
    print(_route[1]);
  }

  Future<void> _fetchRoute() async {
    if (_currentLocation == null || _destination == null) return;
    final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/${_currentLocation!.longitude},${_currentLocation!.latitude};${_destination!.longitude},${_destination!.latitude}?overview=full&geometries=polyline");

    final resopnse = await http.get(url);

    if (resopnse.statusCode == 200) {
      final data = json.decode(resopnse.body);
      if (data.isNotEmpty) {
        final geometry = data['routes'][0]['geometry'];
        _decodePolyline(geometry);
      } else {
        errorMessage("failed to fetch route, try againg later");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _inititalizeLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        isLoading
            ? Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? const LatLng(0, 0),
                  initialZoom: 2,
                  minZoom: 0,
                  maxZoom: 100,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName:
                        'net.tlserver6y.flutter_map_location_marker.example',
                    maxZoom: 19,
                  ),
                  CurrentLocationLayer(
                    style: const LocationMarkerStyle(
                      marker: DefaultLocationMarker(
                        child: Icon(Icons.location_pin),
                      ),
                      markerSize: Size(35, 35),
                    ),
                  ),
                  if (_destination != null)
                    MarkerLayer(markers: [
                      Marker(
                          width: 50,
                          height: 50,
                          point: _destination!,
                          child: const Icon(
                            size: 40,
                            Icons.location_pin,
                            color: Colors.red,
                          )),
                    ]),
                  if (_currentLocation != null &&
                      _destination != null &&
                      _route.isNotEmpty)
                    PolylineLayer(polylines: [
                      Polyline(
                          points: _route, strokeWidth: 5, color: Colors.red)
                    ])
                ],
              ),
      ]),
    );
  }
}
