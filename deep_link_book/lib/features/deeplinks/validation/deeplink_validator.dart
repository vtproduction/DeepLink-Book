abstract final class DeeplinkValidator {
  static final _schemePattern = RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*$');
  static final _whitespacePattern = RegExp(r'\s');

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a name.';
    }

    return null;
  }

  static String? validateUrl(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Enter a deeplink URL.';
    }

    if (_whitespacePattern.hasMatch(trimmedValue)) {
      return 'Enter a valid deeplink URL.';
    }

    final uri = Uri.tryParse(trimmedValue);

    if (uri == null ||
        uri.scheme.isEmpty ||
        !_schemePattern.hasMatch(uri.scheme)) {
      return 'Enter a valid deeplink URL.';
    }

    return null;
  }
}
