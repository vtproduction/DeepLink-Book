import 'package:deep_link_book/features/deeplinks/validation/deeplink_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeeplinkValidator.validateUrl', () {
    test('accepts a valid custom scheme', () {
      final error = DeeplinkValidator.validateUrl(
        'ascendbank-qa://transfer_out',
      );

      expect(error, isNull);
    });

    test('accepts a valid custom scheme with query parameters', () {
      final error = DeeplinkValidator.validateUrl(
        'ascendbank-qa://transfer_out?type=tag29',
      );

      expect(error, isNull);
    });

    test('accepts a valid HTTPS URL', () {
      final error = DeeplinkValidator.validateUrl('https://example.com/path');

      expect(error, isNull);
    });

    test('rejects a missing scheme', () {
      final error = DeeplinkValidator.validateUrl('transfer_out');

      expect(error, 'Enter a valid deeplink URL.');
    });

    test('rejects an empty URL', () {
      final error = DeeplinkValidator.validateUrl('');

      expect(error, 'Enter a deeplink URL.');
    });

    test('rejects a whitespace-only URL', () {
      final error = DeeplinkValidator.validateUrl('   ');

      expect(error, 'Enter a deeplink URL.');
    });

    test('rejects obvious invalid text', () {
      final error = DeeplinkValidator.validateUrl('just some text');

      expect(error, 'Enter a valid deeplink URL.');
    });
  });
}
