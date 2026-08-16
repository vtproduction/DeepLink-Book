import 'received_deeplink.dart';

ReceivedDeeplink parseDeeplink(Uri uri, {DateTime? receivedAt}) {
  final destination = switch (uri.host) {
    'home' => 'Home',
    'profile' => 'Profile',
    'transfer' => 'Transfer',
    'product' => 'Product',
    _ => 'Unknown deeplink',
  };

  return ReceivedDeeplink(
    uri: uri,
    destination: destination,
    receivedAt: receivedAt ?? DateTime.now(),
    pathParameters: _pathParametersFor(uri),
  );
}

Map<String, String> _pathParametersFor(Uri uri) {
  if (uri.host != 'product' || uri.pathSegments.isEmpty) {
    return const {};
  }

  final productId = uri.pathSegments.first;
  if (productId.isEmpty) {
    return const {};
  }

  return {'productId': productId};
}
