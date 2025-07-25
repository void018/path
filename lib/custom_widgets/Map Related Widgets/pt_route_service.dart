// services/public_transport_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'pt_route_model.dart';

class PublicTransportService {
  final String baseUrl;

  PublicTransportService({this.baseUrl = 'http://10.0.2.2:8989'});

  Future<PublicTransportRoute?> getRoute({
    required LatLng origin,
    required LatLng destination,
    DateTime? departureTime,
    String profile = 'pt',
  }) async {
    try {
      final request = RouteRequest(
        origin: origin,
        destination: destination,
        departureTime: departureTime ?? DateTime.now(),
        profile: profile,
      );

      final url = request.buildUrl(baseUrl);
      print('Requesting route: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        if (data['paths'] != null && (data['paths'] as List).isNotEmpty) {
          return PublicTransportRoute.fromJson(data);
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception(
            'Failed to fetch route: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching route: $e');
      rethrow;
    }
  }

  Future<List<LatLng>> geocodeLocation(String locationName) async {
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/search?q=$locationName&format=json&limit=5");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((item) {
          final lat = double.parse(item['lat']);
          final lon = double.parse(item['lon']);
          return LatLng(lat, lon);
        }).toList();
      } else {
        throw Exception('Failed to geocode location');
      }
    } catch (e) {
      print('Error geocoding location: $e');
      return [];
    }
  }

  Future<String> reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
          "https://nominatim.openstreetmap.org/reverse?lat=${location.latitude}&lon=${location.longitude}&format=json");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] ?? 'Unknown location';
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
      return 'Unknown location';
    }
  }
}
