// widgets/route_search_widget.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'pt_route_model.dart';
import 'pt_route_service.dart';

class RouteSearchWidget extends StatefulWidget {
  final Function(PublicTransportRoute) onRouteFound;
  final Function(String) onError;
  final LatLng? currentLocation;

  const RouteSearchWidget({
    super.key,
    required this.onRouteFound,
    required this.onError,
    this.currentLocation,
  });

  @override
  State<RouteSearchWidget> createState() => _RouteSearchWidgetState();
}

class _RouteSearchWidgetState extends State<RouteSearchWidget> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final PublicTransportService _service = PublicTransportService();

  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;
  bool _useCurrentLocation = true;

  List<LatLng> _fromSuggestions = [];
  List<LatLng> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentLocation != null) {
      _setCurrentLocationAsFrom();
    }
  }

  void _setCurrentLocationAsFrom() async {
    if (widget.currentLocation != null) {
      final address = await _service.reverseGeocode(widget.currentLocation!);
      _fromController.text = address;
      setState(() {
        _useCurrentLocation = true;
      });
    }
  }

  Future<void> _searchFromLocations(String query) async {
    if (query.length < 3) return;

    final suggestions = await _service.geocodeLocation(query);
    setState(() {
      _fromSuggestions = suggestions;
      _showFromSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _searchToLocations(String query) async {
    if (query.length < 3) return;

    final suggestions = await _service.geocodeLocation(query);
    setState(() {
      _toSuggestions = suggestions;
      _showToSuggestions = suggestions.isNotEmpty;
    });
  }

  Future<void> _searchRoute() async {
    if (_fromController.text.isEmpty || _toController.text.isEmpty) {
      widget.onError('Please fill in both origin and destination');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      LatLng? origin;
      LatLng? destination;

      // Get origin coordinates
      if (_useCurrentLocation && widget.currentLocation != null) {
        origin = widget.currentLocation;
      } else {
        final fromLocations =
            await _service.geocodeLocation(_fromController.text);
        if (fromLocations.isEmpty) {
          widget.onError('Origin location not found');
          return;
        }
        origin = fromLocations.first;
      }

      // Get destination coordinates
      final toLocations = await _service.geocodeLocation(_toController.text);
      if (toLocations.isEmpty) {
        widget.onError('Destination location not found');
        return;
      }
      destination = toLocations.first;

      // Search for route
      final route = await _service.getRoute(
        origin: origin!,
        destination: destination,
        departureTime: _selectedDateTime,
      );

      if (route != null) {
        widget.onRouteFound(route);
      } else {
        widget.onError('No route found');
      }
    } catch (e) {
      widget.onError('Error searching route: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // From field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text('From',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    if (widget.currentLocation != null)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _useCurrentLocation = !_useCurrentLocation;
                          });
                          if (_useCurrentLocation) {
                            _setCurrentLocationAsFrom();
                          } else {
                            _fromController.clear();
                          }
                        },
                        icon: Icon(_useCurrentLocation
                            ? Icons.check_box
                            : Icons.check_box_outline_blank),
                        label: const Text('Current'),
                      ),
                  ],
                ),
                TextField(
                  controller: _fromController,
                  enabled: !_useCurrentLocation,
                  decoration: const InputDecoration(
                    hintText: 'Enter starting location',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _searchFromLocations,
                  onTap: () => setState(() => _showFromSuggestions = true),
                ),
                if (_showFromSuggestions && _fromSuggestions.isNotEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _fromSuggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_fromSuggestions[index].toString()),
                          onTap: () {
                            _fromController.text =
                                _fromSuggestions[index].toString();
                            setState(() {
                              _showFromSuggestions = false;
                              _useCurrentLocation = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // To field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 8),
                    Text('To', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                TextField(
                  controller: _toController,
                  decoration: const InputDecoration(
                    hintText: 'Enter destination',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _searchToLocations,
                  onTap: () => setState(() => _showToSuggestions = true),
                ),
                if (_showToSuggestions && _toSuggestions.isNotEmpty)
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: _toSuggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_toSuggestions[index].toString()),
                          onTap: () {
                            _toController.text =
                                _toSuggestions[index].toString();
                            setState(() => _showToSuggestions = false);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Date/Time selection
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: _selectDateTime,
                    child: Text(
                      'Departure: ${_selectedDateTime.day}/${_selectedDateTime.month} ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchRoute,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Search Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }
}
