import 'package:deeplink_test_app/deeplink_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home deeplink resolves to Home', () {
    final received = parseDeeplink(Uri.parse('deeplinktest://home'));

    expect(received.destination, 'Home');
  });

  test('profile deeplink resolves to Profile', () {
    final received = parseDeeplink(Uri.parse('deeplinktest://profile'));

    expect(received.destination, 'Profile');
  });

  test('transfer deeplink keeps all query parameters', () {
    final received = parseDeeplink(
      Uri.parse('deeplinktest://transfer?id=123&amount=500'),
    );

    expect(received.destination, 'Transfer');
    expect(received.uri.queryParameters['id'], '123');
    expect(received.uri.queryParameters['amount'], '500');
  });

  test('product deeplink resolves path and source', () {
    final received = parseDeeplink(
      Uri.parse('deeplinktest://product/42?source=test'),
    );

    expect(received.destination, 'Product');
    expect(received.uri.path, '/42');
    expect(received.pathParameters['productId'], '42');
    expect(received.uri.queryParameters['source'], 'test');
  });

  test('unknown deeplink resolves to Unknown deeplink', () {
    final received = parseDeeplink(Uri.parse('deeplinktest://random'));

    expect(received.destination, 'Unknown deeplink');
  });

  test('query encoding is decoded by Dart Uri', () {
    final received = parseDeeplink(
      Uri.parse('deeplinktest://profile?name=John%20Doe'),
    );

    expect(received.destination, 'Profile');
    expect(received.uri.queryParameters['name'], 'John Doe');
  });
}
