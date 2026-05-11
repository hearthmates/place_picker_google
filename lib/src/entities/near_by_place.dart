import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Nearby place data will be deserialized into this model.
class NearbyPlace {
  /// The human-readable name of the location provided. This value is provided
  /// for [LocationResult.name] when the user selects this nearby place.
  final String? name;

  /// The icon mask URI for the place category (append .png or .svg to use).
  final String? icon;

  /// The background color for the icon mask, as a hex string (e.g. "#FF9E67").
  final String? iconBackgroundColor;

  /// Latitude/Longitude of the provided location.
  final LatLng? latLng;

  const NearbyPlace({
    this.name,
    this.icon,
    this.iconBackgroundColor,
    this.latLng,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
        name: json["name"],
        icon: json["icon"],
        iconBackgroundColor: json["iconBackgroundColor"],
        latLng: json["latLng"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "icon": icon,
        "iconBackgroundColor": iconBackgroundColor,
        "latLng": latLng,
      };
}
