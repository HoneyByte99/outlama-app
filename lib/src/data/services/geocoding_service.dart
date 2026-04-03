import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Address suggestion from Places Autocomplete.
class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});
  final String placeId;
  final String description;
}

/// Handles address autocomplete and geocoding via Google Places API.
class GeocodingService {
  GeocodingService({required String apiKey}) : _apiKey = apiKey;

  final String _apiKey;

  /// Returns autocomplete suggestions for the given [input].
  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    if (input.trim().length < 2) return const [];

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': _apiKey,
        'language': 'fr',
        'types': '(regions)',
        'components': 'country:fr|country:sn',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return const [];

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final predictions = json['predictions'] as List? ?? [];

    return predictions.map((p) {
      final m = p as Map<String, dynamic>;
      return PlaceSuggestion(
        placeId: m['place_id'] as String,
        description: m['description'] as String,
      );
    }).toList();
  }

  /// Returns lat/lng for a given [placeId] via Place Details.
  Future<({double lat, double lng})?> getPlaceLatLng(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      {
        'place_id': placeId,
        'key': _apiKey,
        'fields': 'geometry',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final result = json['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final location =
        result['geometry']['location'] as Map<String, dynamic>;
    return (
      lat: (location['lat'] as num).toDouble(),
      lng: (location['lng'] as num).toDouble(),
    );
  }
}

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService(apiKey: 'AIzaSyA8LD81VepWh8J31k6WqRH8FCJ85OLXBFA');
});
