import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:place_picker_google/src/entities/component.dart';
import 'package:place_picker_google/src/services/google_maps_http_service.dart';

class GoogleMapsPlacesService extends GoogleMapsHTTPService {
  GoogleMapsPlacesService({
    super.apiKey,
    super.baseUrl,
    super.httpClient,
    super.apiHeaders,
    super.apiPath = 'place/',
  });

  Map<String, String> _buildHeaders({String? fieldMask}) {
    return {
      if (apiHeaders != null) ...apiHeaders!,
      if (apiKey != null) 'X-Goog-Api-Key': apiKey!,
      if (fieldMask != null) 'X-Goog-FieldMask': fieldMask,
    };
  }

  Future<http.Response> autocomplete(
    String input, {
    String? sessionToken,
    num? offset,
    LatLng? origin,
    LatLng? location,
    num? radius,
    String? language,
    List<String> types = const [],
    List<Component> components = const [],
    bool strictBounds = false,
    String? region,
  }) async {
    const url = 'https://places.googleapis.com/v1/places:autocomplete';

    final body = <String, dynamic>{
      'input': input,
    };

    if (sessionToken != null) {
      body['sessionToken'] = sessionToken;
    }

    if (language != null) {
      body['languageCode'] = language;
    }

    if (region != null) {
      body['regionCode'] = region;
    }

    if (location != null && radius != null) {
      final circle = {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius.toDouble(),
        },
      };
      body[strictBounds ? 'locationRestriction' : 'locationBias'] = circle;
    }

    if (origin != null) {
      body['origin'] = {
        'latitude': origin.latitude,
        'longitude': origin.longitude,
      };
    }

    if (types.isNotEmpty) {
      body['includedPrimaryTypes'] = types;
    }

    if (components.isNotEmpty) {
      final regionCodes = components
          .where((c) => c.component == Component.country)
          .map((c) => c.value)
          .toList();
      if (regionCodes.isNotEmpty) {
        body['includedRegionCodes'] = regionCodes;
      }
    }

    final headers = _buildHeaders(
      fieldMask: 'suggestions.placePrediction.placeId,'
          'suggestions.placePrediction.text,'
          'suggestions.placePrediction.structuredFormat.mainText,'
          'suggestions.placePrediction.structuredFormat.secondaryText',
    );

    return await doPost(url, jsonEncode(body), headers: headers);
  }

  Future<http.Response> nearbySearch(
    LatLng location, {
    num radius = 150,
    String? type,
    String? keyword,
    String? language,
  }) async {
    const url = 'https://places.googleapis.com/v1/places:searchNearby';

    final body = <String, dynamic>{
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': radius.toDouble(),
        },
      },
      'maxResultCount': 20,
    };

    if (type != null) {
      body['includedTypes'] = [type];
    }

    if (language != null) {
      body['languageCode'] = language;
    }

    final headers = _buildHeaders(
      fieldMask:
          'places.id,places.displayName,places.location,places.iconMaskBaseUri',
    );

    return await doPost(url, jsonEncode(body), headers: headers);
  }

  Future<http.Response> details(
    String placeId, {
    String? sessionToken,
    List<String> fields = const [],
    String? language,
    String? region,
  }) async {
    const fieldNameMap = {
      'place_id': 'id',
      'name': 'displayName',
      'formatted_address': 'formattedAddress',
      'geometry': 'location',
      'address_component': 'addressComponents',
      'type': 'types',
      'formatted_phone_number': 'nationalPhoneNumber',
      'international_phone_number': 'internationalPhoneNumber',
      'opening_hours': 'currentOpeningHours',
      'website': 'websiteUri',
      'url': 'googleMapsUri',
      'rating': 'rating',
      'user_ratings_total': 'userRatingCount',
      'price_level': 'priceLevel',
      'icon': 'iconMaskBaseUri',
    };

    String fieldMask;
    if (fields.isNotEmpty) {
      fieldMask = fields.map((f) => fieldNameMap[f] ?? f).join(',');
    } else {
      fieldMask = 'id,displayName,formattedAddress,location,addressComponents';
    }

    final params = <String, String>{};
    if (sessionToken != null) {
      params['sessionToken'] = sessionToken;
    }
    if (language != null) {
      params['languageCode'] = language;
    }
    if (region != null) {
      params['regionCode'] = region;
    }

    var detailsUrl = 'https://places.googleapis.com/v1/places/$placeId';
    if (params.isNotEmpty) {
      final queryString =
          params.entries.map((e) => '${e.key}=${e.value}').join('&');
      detailsUrl = '$detailsUrl?$queryString';
    }

    final headers = _buildHeaders(fieldMask: fieldMask);

    return await doGet(detailsUrl, headers: headers);
  }
}
