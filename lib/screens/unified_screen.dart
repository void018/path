import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/openstreetmap_screen.dart';
import 'package:public_transportation/custom_widgets/Map%20Related%20Widgets/pt_route_model.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// Import the enhanced data classes

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

// App states enum
enum AppState {
  home, // Initial home state with basic panel
  routeSelection, // Route selection screen
  navigation, // Active navigation state
  mapSelection, // When user is selecting points on map
}

// Point selection modes
enum MapSelectionMode {
  none,
  selectingOrigin,
  selectingDestination,
}

class UnifiedNavigationScreen extends StatefulWidget {
  const UnifiedNavigationScreen({super.key});

  @override
  State<UnifiedNavigationScreen> createState() =>
      _UnifiedNavigationScreenState();
}

class _UnifiedNavigationScreenState extends State<UnifiedNavigationScreen> {
  // State management
  AppState _currentState = AppState.home;
  MapSelectionMode _mapSelectionMode = MapSelectionMode.none;

  // Controllers
  final PanelController _panelController = PanelController();
  final StreamController<String> _searchController =
      StreamController<String>.broadcast();
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Data
  PointData? _origin;
  PointData? _destination;
  List<LatLng> _currentRoute = [];
  PublicTransportRoute? _publicTransportRoute;
  List<PublicTransportRoute> _availableRoutes = [];

  @override
  void dispose() {
    _searchController.close();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // State transition methods
  void _goToRouteSelection() {
    setState(() {
      _currentState = AppState.routeSelection;
    });
    _panelController.open();
  }

  void _goToHome() {
    setState(() {
      _currentState = AppState.home;
      _mapSelectionMode = MapSelectionMode.none;
    });
    _panelController.animatePanelToPosition(0.235);
  }

  void _startNavigation() {
    if (_origin != null && _destination != null) {
      setState(() {
        _currentState = AppState.navigation;
      });
      _panelController.animatePanelToPosition(0.235);
    }
  }

  void _startMapSelection(MapSelectionMode mode) {
    setState(() {
      _currentState = AppState.mapSelection;
      _mapSelectionMode = mode;
    });
    _panelController.animatePanelToPosition(0.4);
  }

  // Data handlers
  void _onOriginChanged(PointData? origin) {
    setState(() {
      _origin = origin;
      _originController.text = origin?.address ?? '';
    });
  }

  void _onDestinationChanged(PointData? destination) {
    setState(() {
      _destination = destination;
      _destinationController.text = destination?.address ?? '';
    });
  }

  void _onRouteChanged(List<LatLng> route) {
    setState(() {
      _currentRoute = route;
    });
  }

  void _onPublicTransportRouteChanged(PublicTransportRoute? route) {
    setState(() {
      _publicTransportRoute = route;
      if (route != null) {
        // Generate multiple route alternatives for the route list
        _availableRoutes = _generateRouteAlternatives(route);
      } else {
        _availableRoutes.clear();
      }
    });
  }

  List<PublicTransportRoute> _generateRouteAlternatives(
      PublicTransportRoute baseRoute) {
    // Generate 3 route alternatives with different timings and modes
    List<PublicTransportRoute> alternatives = [];

    // Add the base route
    alternatives.add(baseRoute);

    // Generate two variations
    for (int i = 1; i <= 2; i++) {
      final additionalTime = Duration(minutes: i * 5);
      final newRoute = PublicTransportRoute(
        coordinates: baseRoute.coordinates,
        legs: baseRoute.legs,
        time: baseRoute.time,
        distance: baseRoute.distance,
        weight: baseRoute.weight,
        transfers: baseRoute.transfers,
        bbox: baseRoute.bbox,
        instructions: baseRoute.instructions,
        ascend: baseRoute.ascend,
        descend: baseRoute.descend,
        snappedWaypoints: baseRoute.snappedWaypoints,
        // summary: "${baseRoute.summary} - Alternative ${i + 1}",
      );
      alternatives.add(newRoute);
    }

    return alternatives;
  }

  void _swapOriginDestination() {
    if (_origin != null && _destination != null) {
      final temp = _origin;
      setState(() {
        _origin = _destination;
        _destination = temp;
        _originController.text = _origin?.address ?? '';
        _destinationController.text = _destination?.address ?? '';
      });
    }
  }

  void _searchLocation(String query) {
    _searchController.add(query);
  }

  // UI Builders
  Widget _buildFloatingIcons() {
    return Positioned(
      top: 90,
      left: 30,
      right: 30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildFloatingButton(
            icon: _currentState == AppState.home
                ? Icons.notifications_none
                : Icons.arrow_back,
            onPressed: _currentState == AppState.home ? () {} : _goToHome,
          ),
          _buildFloatingButton(
            icon: _currentState == AppState.navigation
                ? Icons.close
                : Icons.person_outlined,
            onPressed: _currentState == AppState.navigation ? _goToHome : () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 229, 243, 255),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        color: const Color.fromARGB(255, 0, 59, 115),
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPanel(ScrollController controller) {
    switch (_currentState) {
      case AppState.home:
        return _buildHomePanel(controller);
      case AppState.routeSelection:
        return _buildRouteSelectionPanel(controller);
      case AppState.navigation:
        return _buildNavigationPanel(controller);
      case AppState.mapSelection:
        return _buildMapSelectionPanel(controller);
    }
  }

  Widget _buildHomePanel(ScrollController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search button
          GestureDetector(
            onTap: _goToRouteSelection,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Text('Where to?', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Quick actions
          if (_publicTransportRoute != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 0, 59, 115),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _publicTransportRoute!.transfersText,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_publicTransportRoute!.formattedDuration} • ${_publicTransportRoute!.formattedDistance}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteSelectionPanel(ScrollController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildDestinationInputs(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Routes',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w500),
              ),
              if (_publicTransportRoute != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Public Transport',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildRouteList()),
        ],
      ),
    );
  }

  Widget _buildNavigationPanel(ScrollController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Navigation Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003B73), Color(0xFF0074D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Navigation Active',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.my_location,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _publicTransportRoute?.transfersText ?? 'Direct',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_publicTransportRoute != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'To: ${_getDestinationText()}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'ETA: ${_publicTransportRoute!.formattedDuration}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003B73),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _publicTransportRoute!.formattedDistance,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Instructions Section
          Expanded(
            child: _buildInstructionsList(),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goToHome,
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('End Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF003B73),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      // Add recenter functionality
                    },
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Add this state variable at the top of your class
  final Set<int> _expandedLegs = <int>{0}; // First leg expanded by default

  Widget _buildInstructionsList() {
    if (_publicTransportRoute?.legs.isEmpty ?? true) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No route information available',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Journey Steps',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003B73),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_publicTransportRoute!.legs.length} segments',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF003B73),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: ScrollController(),
            itemCount: _publicTransportRoute!.legs.length,
            itemBuilder: (context, index) {
              final leg = _publicTransportRoute!.legs[index];
              final isExpanded = _expandedLegs.contains(index);

              return _buildLegCard(leg, index, isExpanded);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLegCard(RouteLeg leg, int legIndex, bool isExpanded) {
    final isWalking = leg.isWalkingLeg;
    final isPublicTransport = leg.isPublicTransportLeg;
    final isLast = legIndex == _publicTransportRoute!.legs.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Travel mode indicator with connecting line
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getLegColor(leg),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: _getLegIcon(leg),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Expandable leg card
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedLegs.remove(legIndex);
                  } else {
                    _expandedLegs.add(legIndex);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isExpanded
                        ? _getLegColor(leg).withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    width: isExpanded ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isExpanded ? 0.1 : 0.05),
                      blurRadius: isExpanded ? 8 : 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Leg summary header
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color:
                                            _getLegColor(leg).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getLegTypeText(leg),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getLegColor(leg),
                                        ),
                                      ),
                                    ),
                                    if (isPublicTransport &&
                                        leg.tripHeadsign != null) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          leg.displayName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF003B73),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${leg.formattedDepartureTime} - ${leg.formattedArrivalTime}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.straighten,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDistance(leg.distance),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isPublicTransport &&
                                    leg.numberOfStops > 0) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${leg.numberOfStops} stops',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),

                          // Expand/collapse indicator
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: _getLegColor(leg),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expandable instructions section
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              height: 1,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: _buildLegInstructions(leg),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegInstructions(RouteLeg leg) {
    if (leg.instructions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              leg.isWalkingLeg
                  ? Icons.directions_walk
                  : Icons.directions_transit,
              color: Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              leg.isWalkingLeg
                  ? 'Walk to your destination'
                  : 'Stay on this transport',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step-by-step instructions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getLegColor(leg).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${leg.instructions.length} steps',
                style: TextStyle(
                  fontSize: 10,
                  color: _getLegColor(leg),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...leg.instructions.asMap().entries.map((entry) {
          final index = entry.key;
          final instruction = entry.value;
          final isLastInstruction = index == leg.instructions.length - 1;

          return _buildCompactInstructionItem(
              instruction, index, isLastInstruction);
        }).toList(),
      ],
    );
  }

  Widget _buildCompactInstructionItem(
      RouteInstruction instruction, int index, bool isLast) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Mini direction icon
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: index == 0
                  ? Colors.green.withOpacity(0.1)
                  : isLast
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFF003B73).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getCompactDirectionIcon(instruction.sign, index, isLast),
                size: 12,
                color: index == 0
                    ? Colors.green
                    : isLast
                        ? Colors.red
                        : const Color(0xFF003B73),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Instruction details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instruction.text.isNotEmpty
                      ? instruction.text
                      : _getDefaultInstructionText(instruction.sign),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF003B73),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (instruction.streetName.isNotEmpty ||
                    instruction.distance > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (instruction.streetName.isNotEmpty) ...[
                        Text(
                          instruction.streetName,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (instruction.distance > 0) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ],
                      if (instruction.distance > 0)
                        Text(
                          _formatDistance(instruction.distance),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLegColor(RouteLeg leg) {
    if (leg.isWalkingLeg) {
      return Colors.green;
    } else if (leg.isPublicTransportLeg) {
      return const Color(0xFF0074D9);
    } else {
      return const Color(0xFF003B73);
    }
  }

  Widget _getLegIcon(RouteLeg leg) {
    IconData iconData;
    if (leg.isWalkingLeg) {
      iconData = Icons.directions_walk;
    } else if (leg.isPublicTransportLeg) {
      iconData = Icons.directions_bus;
    } else {
      iconData = Icons.directions_transit;
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 20,
    );
  }

  String _getLegTypeText(RouteLeg leg) {
    if (leg.isWalkingLeg) {
      return 'WALK';
    } else if (leg.isPublicTransportLeg) {
      return 'BUS/METRO';
    } else {
      return leg.type.toUpperCase();
    }
  }

  IconData _getCompactDirectionIcon(int sign, int index, bool isLast) {
    if (index == 0) {
      return Icons.play_arrow;
    } else if (isLast) {
      return Icons.location_on;
    } else {
      switch (sign) {
        case -7:
          return Icons.trending_flat;
        case -3:
          return Icons.turn_sharp_left;
        case -2:
          return Icons.turn_left;
        case -1:
          return Icons.turn_slight_left;
        case 0:
          return Icons.straight;
        case 1:
          return Icons.turn_slight_right;
        case 2:
          return Icons.turn_right;
        case 3:
          return Icons.turn_sharp_right;
        case 4:
          return Icons.location_on;
        case 5:
          return Icons.radio_button_checked;
        case 6:
          return Icons.roundabout_left;
        default:
          return Icons.navigation;
      }
    }
  }

  Widget _getDirectionIcon(int sign, int index, bool isLast) {
    IconData iconData;

    if (index == 0) {
      iconData = Icons.play_arrow;
    } else if (isLast) {
      iconData = Icons.location_on;
    } else {
      switch (sign) {
        case -7: // Keep left
          iconData = Icons.trending_flat;
          break;
        case -3: // Turn sharp left
          iconData = Icons.turn_sharp_left;
          break;
        case -2: // Turn left
          iconData = Icons.turn_left;
          break;
        case -1: // Turn slight left
          iconData = Icons.turn_slight_left;
          break;
        case 0: // Continue straight
          iconData = Icons.straight;
          break;
        case 1: // Turn slight right
          iconData = Icons.turn_slight_right;
          break;
        case 2: // Turn right
          iconData = Icons.turn_right;
          break;
        case 3: // Turn sharp right
          iconData = Icons.turn_sharp_right;
          break;
        case 4: // Finish
          iconData = Icons.location_on;
          break;
        case 5: // Via reached
          iconData = Icons.radio_button_checked;
          break;
        case 6: // Roundabout
          iconData = Icons.roundabout_left;
          break;
        default:
          iconData = Icons.navigation;
      }
    }

    return Icon(
      iconData,
      color: Colors.white,
      size: 18,
    );
  }

  String _getDefaultInstructionText(int sign) {
    switch (sign) {
      case -7:
        return 'Keep left';
      case -3:
        return 'Turn sharp left';
      case -2:
        return 'Turn left';
      case -1:
        return 'Turn slight left';
      case 0:
        return 'Continue straight';
      case 1:
        return 'Turn slight right';
      case 2:
        return 'Turn right';
      case 3:
        return 'Turn sharp right';
      case 4:
        return 'You have arrived at your destination';
      case 5:
        return 'Waypoint reached';
      case 6:
        return 'Enter roundabout';
      default:
        return 'Continue';
    }
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      final km = distance / 1000;
      return '${km.toStringAsFixed(1)} km';
    } else {
      return '${distance.toInt()} m';
    }
  }

  String _formatTime(int timeInSeconds) {
    if (timeInSeconds < 60) {
      return '${timeInSeconds}s';
    } else {
      final minutes = timeInSeconds ~/ 60;
      return '${minutes}m';
    }
  }

  String _getDestinationText() {
    // Try to get destination from _destination object first
    if (_destination != null) {
      // Check different possible property names for address
      if (_destination!.toString().contains('address')) {
        return _destination!.toString().split('address: ')[1].split(',')[0];
      }
      // If PointData has a different structure, you might need to adjust this
      // For now, let's try to use the destination controller text
      if (_destinationController.text.isNotEmpty) {
        return _destinationController.text;
      }
    }

    // Fallback: try to get destination from the route
    if (_publicTransportRoute != null &&
        _publicTransportRoute!.legs.isNotEmpty) {
      final lastLeg = _publicTransportRoute!.legs.last;

      // Try to get from the last leg's departure location (which would be close to destination)
      if (lastLeg.departureLocation.isNotEmpty &&
          lastLeg.departureLocation != 'Unknown') {
        return lastLeg.departureLocation;
      }

      // Try to get from coordinates of the last waypoint
      if (_publicTransportRoute!.snappedWaypoints.isNotEmpty) {
        final lastPoint = _publicTransportRoute!.snappedWaypoints.last;
        return '${lastPoint.latitude.toStringAsFixed(4)}, ${lastPoint.longitude.toStringAsFixed(4)}';
      }

      // Try to get from the last stop of the last public transport leg
      final lastPtLeg = _publicTransportRoute!.legs.reversed.firstWhere(
        (leg) =>
            leg.isPublicTransportLeg &&
            leg.stops != null &&
            leg.stops!.isNotEmpty,
        orElse: () => lastLeg,
      );

      if (lastPtLeg.stops != null && lastPtLeg.stops!.isNotEmpty) {
        return lastPtLeg.stops!.last.stopName;
      }
    }

    // Final fallback
    return _destinationController.text.isNotEmpty
        ? _destinationController.text
        : 'Destination';
  }

  Widget _buildMapSelectionPanel(ScrollController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  _mapSelectionMode == MapSelectionMode.selectingOrigin
                      ? Icons.my_location
                      : Icons.location_on,
                  color: _mapSelectionMode == MapSelectionMode.selectingOrigin
                      ? Colors.blue
                      : Colors.red,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _mapSelectionMode == MapSelectionMode.selectingOrigin
                      ? 'Tap on the map to select your starting point'
                      : 'Tap on the map to select your destination',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _goToRouteSelection(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 59, 115),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationInputs() {
    return Stack(
      children: [
        Column(
          children: [
            _buildInputCard(
              icon: Icons.radio_button_checked,
              label: 'Starting Point',
              iconColor: Colors.blue,
              controller: _originController,
              onTap: () => _startMapSelection(MapSelectionMode.selectingOrigin),
            ),
            const SizedBox(height: 6),
            _buildInputCard(
              icon: Icons.location_on,
              label: 'Destination',
              iconColor: Colors.red,
              controller: _destinationController,
              onTap: () =>
                  _startMapSelection(MapSelectionMode.selectingDestination),
            ),
          ],
        ),
        // Swap button
        Positioned(
          right: 65,
          top: 40,
          child: GestureDetector(
            onTap: () {
              _swapOriginDestination();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
                color: const Color.fromARGB(255, 0, 59, 115),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.swap_vert, color: Colors.white, size: 22),
            ),
          ),
        ),
        // Action buttons
        const Positioned(
          right: 0,
          top: 72,
          child: Icon(
            Icons.add,
            size: 26,
            color: Color.fromARGB(255, 0, 59, 115),
          ),
        ),
        const Positioned(
          right: 0,
          top: 15,
          child: Icon(
            Icons.tune_rounded,
            size: 26,
            color: Color.fromARGB(255, 0, 59, 115),
          ),
        ),
      ],
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required String label,
    required Color iconColor,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 12),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _searchLocation(value);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    if (_availableRoutes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Select origin and destination\nto see available routes',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _availableRoutes.length,
      itemBuilder: (_, index) {
        final route = _availableRoutes[index];
        final isRecommended = index == 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onTap: _startNavigation,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: isRecommended
                    ? Border.all(color: Colors.green, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  if (isRecommended)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'RECOMMENDED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left side: Estimated time and icons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _publicTransportRoute!.formattedDuration,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: _buildTransportIcons(route),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Vertical line
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('|', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Route details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distance: ${_publicTransportRoute!.formattedDistance}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "route.summary",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTransportIcons(PublicTransportRoute route) {
    List<Widget> icons = [];
    Set<String> modes = {};

    for (final leg in route.legs) {
      if (!modes.contains(leg.type)) {
        modes.add(leg.type);
        IconData iconData;
        switch (leg.type) {
          case 'walk':
          case 'Walking':
            iconData = Icons.directions_walk;
            break;
          case 'pt':
            iconData = Icons.directions_bus;
            break;
          default:
            iconData = Icons.directions_transit;
        }

        icons.add(
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              iconData,
              color: const Color.fromARGB(255, 0, 59, 115),
              size: 20,
            ),
          ),
        );
      }
    }

    return icons.isNotEmpty
        ? icons
        : [
            const Icon(
              Icons.directions_car,
              color: Color.fromARGB(255, 0, 59, 115),
              size: 20,
            ),
          ];
  }

  PointSelectionMode _getMapSelectionMode() {
    switch (_mapSelectionMode) {
      case MapSelectionMode.selectingOrigin:
        return PointSelectionMode.origin;
      case MapSelectionMode.selectingDestination:
        return PointSelectionMode.destination;
      case MapSelectionMode.none:
        return PointSelectionMode.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double panelHeightClosed = MediaQuery.of(context).size.height * 0.235;
    final double panelHeightOpen = MediaQuery.of(context).size.height * 1.0;

    return Scaffold(
      backgroundColor: const Color(0xffdceeff),
      body: Stack(
        children: [
          // Map layer
          OpenstreetmapScreen(
            onOriginChanged: _onOriginChanged,
            onDestinationChanged: _onDestinationChanged,
            onRouteChanged: _onRouteChanged,
            onPublicTransportRouteChanged: _onPublicTransportRouteChanged,
            selectionMode: _getMapSelectionMode(),
            searchStream: _searchController.stream,
          ),

          // Floating icons
          _buildFloatingIcons(),

          // Sliding panel
          SlidingUpPanel(
            controller: _panelController,
            minHeight: panelHeightClosed,
            maxHeight: panelHeightOpen,
            parallaxEnabled: true,
            parallaxOffset: 0.5,
            panelBuilder: _buildPanel,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            color: const Color.fromARGB(255, 229, 243, 255),
          ),
        ],
      ),
    );
  }
}
