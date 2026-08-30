import 'deeplink_query_parameter.dart';

class ParsedDeeplink {
  ParsedDeeplink({
    required this.scheme,
    required this.host,
    required this.path,
    required List<DeeplinkQueryParameter> queryParameters,
    this.userInfo = '',
    this.port,
    this.fragment = '',
  }) : queryParameters = List.unmodifiable(queryParameters);

  final String scheme;
  final String host;
  final String path;
  final List<DeeplinkQueryParameter> queryParameters;
  final String userInfo;
  final int? port;
  final String fragment;

  ParsedDeeplink copyWith({
    String? scheme,
    String? host,
    String? path,
    List<DeeplinkQueryParameter>? queryParameters,
    String? userInfo,
    int? port,
    bool clearPort = false,
    String? fragment,
  }) {
    return ParsedDeeplink(
      scheme: scheme ?? this.scheme,
      host: host ?? this.host,
      path: path ?? this.path,
      queryParameters: queryParameters ?? this.queryParameters,
      userInfo: userInfo ?? this.userInfo,
      port: clearPort ? null : port ?? this.port,
      fragment: fragment ?? this.fragment,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ParsedDeeplink &&
            other.scheme == scheme &&
            other.host == host &&
            other.path == path &&
            _queryParametersEqual(other.queryParameters, queryParameters) &&
            other.userInfo == userInfo &&
            other.port == port &&
            other.fragment == fragment;
  }

  @override
  int get hashCode {
    return Object.hash(
      scheme,
      host,
      path,
      Object.hashAll(queryParameters),
      userInfo,
      port,
      fragment,
    );
  }

  static bool _queryParametersEqual(
    List<DeeplinkQueryParameter> first,
    List<DeeplinkQueryParameter> second,
  ) {
    if (first.length != second.length) {
      return false;
    }

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) {
        return false;
      }
    }

    return true;
  }
}
