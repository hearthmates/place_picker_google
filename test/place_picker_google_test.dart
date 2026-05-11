import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:place_picker_google/src/entities/component.dart';
import 'package:place_picker_google/src/services/google_maps_places_service.dart';

void main() {
  const apiKey = 'test-api-key';

  group('GoogleMapsPlacesService.autocomplete()', () {
    test('sends POST to the correct endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://places.googleapis.com/v1/places:autocomplete',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete('pizza');
    });

    test('sends API key in X-Goog-Api-Key header, not in URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Goog-Api-Key'], apiKey);
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete('pizza');
    });

    test('sends correct X-Goog-FieldMask header', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['X-Goog-FieldMask'],
          'suggestions.placePrediction.placeId,'
          'suggestions.placePrediction.text,'
          'suggestions.placePrediction.structuredFormat.mainText,'
          'suggestions.placePrediction.structuredFormat.secondaryText',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete('pizza');
    });

    test('sends input, sessionToken, languageCode, regionCode in body',
        () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['input'], 'pizza');
        expect(body['sessionToken'], 'token-123');
        expect(body['languageCode'], 'en');
        expect(body['regionCode'], 'us');
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        sessionToken: 'token-123',
        language: 'en',
        region: 'us',
      );
    });

    test('uses locationBias when strictBounds is false', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('locationBias'), isTrue);
        expect(body.containsKey('locationRestriction'), isFalse);

        final circle = body['locationBias']['circle'] as Map<String, dynamic>;
        expect(circle['center']['latitude'], 37.7749);
        expect(circle['center']['longitude'], -122.4194);
        expect(circle['radius'], 1000.0);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        location: const LatLng(37.7749, -122.4194),
        radius: 1000,
        strictBounds: false,
      );
    });

    test('uses locationRestriction when strictBounds is true', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('locationRestriction'), isTrue);
        expect(body.containsKey('locationBias'), isFalse);

        final circle =
            body['locationRestriction']['circle'] as Map<String, dynamic>;
        expect(circle['center']['latitude'], 37.7749);
        expect(circle['center']['longitude'], -122.4194);
        expect(circle['radius'], 500.0);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        location: const LatLng(37.7749, -122.4194),
        radius: 500,
        strictBounds: true,
      );
    });

    test('maps components with country to includedRegionCodes', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['includedRegionCodes'], ['us']);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        components: [const Component(Component.country, 'us')],
      );
    });

    test('maps types to includedPrimaryTypes', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['includedPrimaryTypes'], ['restaurant']);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        types: ['restaurant'],
      );
    });

    test('accepts offset param but does not send it in body', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('offset'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete('pizza', offset: 3);
    });

    test('does not send locationBias when location provided without radius',
        () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('locationBias'), isFalse);
        expect(body.containsKey('locationRestriction'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        location: const LatLng(37.7749, -122.4194),
      );
    });

    test('excludes non-country components from body', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['includedRegionCodes'], ['us']);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        components: [
          const Component(Component.country, 'us'),
          const Component(Component.locality, 'new york'),
          const Component(Component.postalCode, '10001'),
        ],
      );
    });

    test('does not send includedRegionCodes when only non-country components',
        () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('includedRegionCodes'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.autocomplete(
        'pizza',
        components: [
          const Component(Component.locality, 'new york'),
        ],
      );
    });

    test('returns error response without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "INVALID_REQUEST"}', 400);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      final response = await service.autocomplete('');
      expect(response.statusCode, 400);
    });
  });

  group('GoogleMapsPlacesService.nearbySearch()', () {
    test('sends POST to the correct endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          'https://places.googleapis.com/v1/places:searchNearby',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(const LatLng(37.7749, -122.4194));
    });

    test('sends locationRestriction.circle with center and radius in body',
        () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final circle =
            body['locationRestriction']['circle'] as Map<String, dynamic>;
        expect(circle['center']['latitude'], 37.7749);
        expect(circle['center']['longitude'], -122.4194);
        expect(circle['radius'], 150.0);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(const LatLng(37.7749, -122.4194));
    });

    test('sends maxResultCount: 20', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['maxResultCount'], 20);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(const LatLng(37.7749, -122.4194));
    });

    test('maps type param to includedTypes list', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['includedTypes'], ['restaurant']);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(
        const LatLng(37.7749, -122.4194),
        type: 'restaurant',
      );
    });

    test('accepts keyword param but does not send it in body', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('keyword'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(
        const LatLng(37.7749, -122.4194),
        keyword: 'best pizza',
      );
    });

    test('sends correct X-Goog-FieldMask header', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['X-Goog-FieldMask'],
          'places.id,places.displayName,places.location,places.iconMaskBaseUri,places.iconBackgroundColor',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(const LatLng(37.7749, -122.4194));
    });

    test('uses custom radius when provided', () async {
      final mockClient = MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final circle =
            body['locationRestriction']['circle'] as Map<String, dynamic>;
        expect(circle['radius'], 500.0);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.nearbySearch(
        const LatLng(37.7749, -122.4194),
        radius: 500,
      );
    });

    test('returns error response without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "INVALID_REQUEST"}', 400);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      final response =
          await service.nearbySearch(const LatLng(37.7749, -122.4194));
      expect(response.statusCode, 400);
    });
  });

  group('GoogleMapsPlacesService.details()', () {
    const placeId = 'test-place-id';

    test('sends GET to the correct endpoint with placeId in path', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(
          request.url.path,
          '/v1/places/$placeId',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(placeId);
    });

    test('sends API key in X-Goog-Api-Key header, not in URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.headers['X-Goog-Api-Key'], apiKey);
        expect(request.url.queryParameters.containsKey('key'), isFalse);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(placeId);
    });

    test('uses default fieldMask when no fields specified', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['X-Goog-FieldMask'],
          'id,displayName,formattedAddress,location,addressComponents',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(placeId);
    });

    test('maps legacy field names to new API field names', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.headers['X-Goog-FieldMask'],
          'id,formattedAddress,location',
        );
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(
        placeId,
        fields: ['place_id', 'formatted_address', 'geometry'],
      );
    });

    test('sends sessionToken, languageCode, regionCode as query params',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['sessionToken'], 'token-123');
        expect(request.url.queryParameters['languageCode'], 'en');
        expect(request.url.queryParameters['regionCode'], 'us');
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(
        placeId,
        sessionToken: 'token-123',
        language: 'en',
        region: 'us',
      );
    });

    test('does not append query string when no optional params provided',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.query, isEmpty);
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details(placeId);
    });

    test('URL-encodes special characters in placeId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, contains(Uri.encodeComponent('place/id#1')));
        return http.Response('{}', 200);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      await service.details('place/id#1');
    });

    test('returns error response without throwing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "NOT_FOUND"}', 404);
      });

      final service = GoogleMapsPlacesService(
        apiKey: apiKey,
        httpClient: mockClient,
      );

      final response = await service.details('nonexistent-place');
      expect(response.statusCode, 404);
    });
  });
}
