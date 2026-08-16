class ReceivedDeeplink {
  const ReceivedDeeplink({
    required this.uri,
    required this.destination,
    required this.receivedAt,
    this.pathParameters = const {},
  });

  final Uri uri;
  final String destination;
  final DateTime receivedAt;
  final Map<String, String> pathParameters;
}
