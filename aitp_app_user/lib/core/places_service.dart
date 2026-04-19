import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class PlacesService {
  final Dio _dio = Dio();
  // TODO: Replace with your actual Google Maps API Key
  final String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  Future<List<String>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'types': '(regions)', // typically we want cities/regions for a trip
        },
      );

      if (response.data['status'] == 'OK') {
        final predictions = response.data['predictions'] as List;
        return predictions.map((p) => p['description'] as String).toList();
      } else {
        // Handle API errors like invalid key (REQUEST_DENIED, etc.)
        debugPrint('Places API Error: ${response.data['status']}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
      return [];
    }
  }
}
