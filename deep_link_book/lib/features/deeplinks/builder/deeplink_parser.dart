import 'deeplink_query_parameter.dart';
import 'parsed_deeplink.dart';

abstract final class DeeplinkParser {
  static ParsedDeeplink parse(String rawUrl) {
    final parsed = tryParse(rawUrl);

    if (parsed == null) {
      throw FormatException('Invalid deeplink URL.', rawUrl);
    }

    return parsed;
  }

  static ParsedDeeplink? tryParse(String rawUrl) {
    final trimmedUrl = rawUrl.trim();

    if (trimmedUrl.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmedUrl);

    if (uri == null || uri.scheme.isEmpty) {
      return null;
    }

    if (uri.host.isEmpty && uri.path.isEmpty) {
      return null;
    }

    return ParsedDeeplink(
      scheme: uri.scheme,
      host: uri.host,
      path: uri.path,
      queryParameters: _parseQueryParameters(uri.query),
      userInfo: uri.userInfo,
      port: uri.hasPort ? uri.port : null,
      fragment: uri.fragment,
    );
  }

  static String build(ParsedDeeplink deeplink) {
    final uri = Uri(
      scheme: deeplink.scheme,
      userInfo: deeplink.userInfo,
      host: deeplink.host,
      port: deeplink.port,
      path: deeplink.path,
      query: _buildQuery(deeplink.queryParameters),
      fragment: deeplink.fragment,
    );

    return uri.toString();
  }

  static List<DeeplinkQueryParameter> _parseQueryParameters(String query) {
    if (query.isEmpty) {
      return const [];
    }

    return query.split('&').map((part) {
      final separatorIndex = part.indexOf('=');

      if (separatorIndex == -1) {
        return DeeplinkQueryParameter(
          key: Uri.decodeQueryComponent(part),
          value: '',
        );
      }

      return DeeplinkQueryParameter(
        key: Uri.decodeQueryComponent(part.substring(0, separatorIndex)),
        value: Uri.decodeQueryComponent(part.substring(separatorIndex + 1)),
      );
    }).toList();
  }

  static String? _buildQuery(List<DeeplinkQueryParameter> queryParameters) {
    if (queryParameters.isEmpty) {
      return null;
    }

    return queryParameters
        .map((parameter) {
          final key = Uri.encodeQueryComponent(parameter.key);
          final value = Uri.encodeQueryComponent(parameter.value);

          return '$key=$value';
        })
        .join('&');
  }
}
