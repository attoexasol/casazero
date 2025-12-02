// core/services/geocoding_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  // Using Nominatim (OpenStreetMap) - Free, no API key required
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Get location name from coordinates
  /// Returns format: "City, Country" or "Unknown Location"
  Future<String> getLocationFromCoordinates(double lat, double lng) async {
    try {
      // Check if coordinates are valid
      if (lat == 0.0 && lng == 0.0) {
        return 'Location not available';
      }

      final url = Uri.parse(
        '$_baseUrl/reverse?format=json&lat=$lat&lon=$lng&zoom=10&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'CasaZero Mobile App', // Required by Nominatim
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Location lookup timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _formatLocationName(data);
      } else {
        print('Geocoding API error: ${response.statusCode}');
        return 'Unknown Location';
      }
    } catch (e) {
      print('Error getting location: $e');
      return 'Unknown Location';
    }
  }

  /// Format location name from Nominatim response
  String _formatLocationName(Map<String, dynamic> data) {
    try {
      final address = data['address'] as Map<String, dynamic>?;

      if (address == null) {
        return 'Unknown Location';
      }

      // Priority order: city, town, village, county, state, country
      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['municipality'] ??
          address['county'];

      final country = address['country'];

      if (city != null && country != null) {
        return '$city, $country';
      } else if (city != null) {
        return city;
      } else if (country != null) {
        return country;
      } else {
        return 'Unknown Location';
      }
    } catch (e) {
      print('Error formatting location: $e');
      return 'Unknown Location';
    }
  }

  /// Get multiple locations in batch (more efficient)
  Future<Map<String, String>> getMultipleLocations(
      List<Map<String, double>> coordinates,
      ) async {
    final results = <String, String>{};

    for (final coord in coordinates) {
      final lat = coord['lat']!;
      final lng = coord['lng']!;
      final key = '$lat,$lng';

      // Add small delay to respect API rate limits (1 request per second)
      await Future.delayed(const Duration(milliseconds: 1100));

      final location = await getLocationFromCoordinates(lat, lng);
      results[key] = location;
    }

    return results;
  }

  /// Create cache key for coordinates
  static String getCacheKey(double lat, double lng) {
    return '$lat,$lng';
  }
}