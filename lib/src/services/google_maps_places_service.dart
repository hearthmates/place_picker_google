import 'dart:convert';
import 'dart:developer' as developer;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:place_picker_google/src/entities/component.dart';
import 'package:place_picker_google/src/services/google_maps_http_service.dart';

class GoogleMapsPlacesService extends GoogleMapsHTTPService {
  static const _placesBaseUrl = 'https://places.googleapis.com/v1/places';

  static const _legacyToNewFieldNames = {
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

  static const _defaultDetailFields =
      'id,displayName,formattedAddress,location,addressComponents';

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
    @Deprecated('Not supported in Places API (New)') num? offset,
    LatLng? origin,
    LatLng? location,
    num? radius,
    String? language,
    List<String> types = const [],
    List<Component> components = const [],
    bool strictBounds = false,
    String? region,
  }) async {
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
    } else if (location != null) {
      developer.log(
        'location was provided without radius — locationBias will not be sent. '
        'Set radius to enable location biasing.',
        name: 'place_picker_google',
      );
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
      final regionCodes = <String>[];
      for (final c in components) {
        if (c.component == Component.country) {
          regionCodes.add(c.value);
        } else {
          developer.log(
            'Component type "${c.component}" is not supported in Places API (New) '
            'and will be ignored. Only country components are supported.',
            name: 'place_picker_google',
          );
        }
      }
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

    return doPost('$_placesBaseUrl:autocomplete', jsonEncode(body),
        headers: headers);
  }

  Future<http.Response> nearbySearch(
    LatLng location, {
    num radius = 150,
    String? type,
    @Deprecated('Not supported in Places API (New). Use type instead.')
    String? keyword,
    String? language,
  }) async {
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
          'places.id,places.displayName,places.location,places.iconMaskBaseUri,places.iconBackgroundColor',
    );

    return doPost('$_placesBaseUrl:searchNearby', jsonEncode(body),
        headers: headers);
  }

  Future<http.Response> details(
    String placeId, {
    String? sessionToken,
    List<String> fields = const [],
    String? language,
    String? region,
  }) async {
    final fieldMask = fields.isNotEmpty
        ? fields.map((f) => _legacyToNewFieldNames[f] ?? f).join(',')
        : _defaultDetailFields;

    final params = <String, String>{
      if (sessionToken != null) 'sessionToken': sessionToken,
      if (language != null) 'languageCode': language,
      if (region != null) 'regionCode': region,
    };

    var detailsUri =
        Uri.parse('$_placesBaseUrl/${Uri.encodeComponent(placeId)}');
    if (params.isNotEmpty) {
      detailsUri = detailsUri.replace(queryParameters: params);
    }

    final headers = _buildHeaders(fieldMask: fieldMask);

    return doGet(detailsUri.toString(), headers: headers);
  }
}
