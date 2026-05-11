enum AddressComponentTypes {
  plusCode,
  locality,
  subLocality,
  subLocality1,
  subLocality2,
  postalCode,
  country,
  administrativeAreaLevel1,
  administrativeAreaLevel2,
}

enum PinState {
  preparing,
  idle,
  dragging,
}

enum SearchingState {
  idle,
  searching,
}

enum PlacesDetailsStatus {
  ok(status: "OK"),
  zeroResults(status: "ZERO_RESULTS"),
  notFound(status: "NOT_FOUND"),
  invalidRequest(status: "INVALID_REQUEST"),
  overQueryLimit(status: "OVER_QUERY_LIMIT"),
  requestDenied(status: "REQUEST_DENIED"),
  unknownError(status: "UNKNOWN_ERROR");

  const PlacesDetailsStatus({
    required this.status,
  });

  final String status;
}

