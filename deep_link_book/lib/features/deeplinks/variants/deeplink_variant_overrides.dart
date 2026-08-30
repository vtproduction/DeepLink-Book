import 'dart:convert';

import '../builder/deeplink_query_parameter.dart';
import '../builder/parsed_deeplink.dart';

class DeeplinkVariantOverrides {
  const DeeplinkVariantOverrides({this.parameterOverrides = const []});

  static const empty = DeeplinkVariantOverrides();

  final List<DeeplinkParameterOverride> parameterOverrides;

  bool get isEmpty => parameterOverrides.isEmpty;

  ParsedDeeplink applyTo(ParsedDeeplink base) {
    if (parameterOverrides.isEmpty) {
      return base;
    }

    final overridesByIndex = {
      for (final override in parameterOverrides) override.index: override,
    };

    final parameters = <DeeplinkQueryParameter>[];

    for (var index = 0; index < base.queryParameters.length; index++) {
      final parameter = base.queryParameters[index];
      final override = overridesByIndex[index];

      if (override == null) {
        parameters.add(parameter);
        continue;
      }

      parameters.add(
        DeeplinkQueryParameter(
          key: parameter.key,
          value: override.hasValueOverride
              ? override.value ?? ''
              : parameter.value,
          enabled: override.enabled ?? parameter.enabled,
          type: parameter.type,
        ),
      );
    }

    return base.copyWith(queryParameters: parameters);
  }

  String toJsonString() {
    if (parameterOverrides.isEmpty) {
      return '{}';
    }

    return jsonEncode({
      'parameters': parameterOverrides
          .map((override) => override.toJson())
          .toList(),
    });
  }

  static DeeplinkVariantOverrides fromJsonString(String value) {
    if (value.trim().isEmpty) {
      return empty;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is! Map) {
        return empty;
      }

      final parameters = decoded['parameters'];

      if (parameters is! List) {
        return empty;
      }

      return DeeplinkVariantOverrides(
        parameterOverrides: parameters
            .map(DeeplinkParameterOverride.fromJson)
            .whereType<DeeplinkParameterOverride>()
            .toList(),
      );
    } on FormatException {
      return empty;
    }
  }

  static DeeplinkVariantOverrides fromDifference({
    required ParsedDeeplink base,
    required ParsedDeeplink effective,
  }) {
    final overrides = <DeeplinkParameterOverride>[];

    for (var index = 0; index < base.queryParameters.length; index++) {
      final baseParameter = base.queryParameters[index];
      final effectiveParameter = index < effective.queryParameters.length
          ? effective.queryParameters[index]
          : null;

      if (effectiveParameter == null) {
        overrides.add(DeeplinkParameterOverride(index: index, enabled: false));
        continue;
      }

      final hasValueOverride = effectiveParameter.value != baseParameter.value;
      final enabledOverride =
          effectiveParameter.enabled == baseParameter.enabled
          ? null
          : effectiveParameter.enabled;

      if (!hasValueOverride && enabledOverride == null) {
        continue;
      }

      overrides.add(
        DeeplinkParameterOverride(
          index: index,
          value: hasValueOverride ? effectiveParameter.value : null,
          hasValueOverride: hasValueOverride,
          enabled: enabledOverride,
        ),
      );
    }

    return DeeplinkVariantOverrides(parameterOverrides: overrides);
  }
}

class DeeplinkParameterOverride {
  const DeeplinkParameterOverride({
    required this.index,
    this.value,
    this.hasValueOverride = false,
    this.enabled,
  });

  final int index;
  final String? value;
  final bool hasValueOverride;
  final bool? enabled;

  Map<String, Object?> toJson() {
    return {
      'index': index,
      if (hasValueOverride) 'value': value ?? '',
      if (enabled != null) 'enabled': enabled,
    };
  }

  static DeeplinkParameterOverride? fromJson(Object? value) {
    if (value is! Map) {
      return null;
    }

    final index = value['index'];

    if (index is! int || index < 0) {
      return null;
    }

    final hasValueOverride = value.containsKey('value');
    final overrideValue = value['value'];
    final enabledValue = value['enabled'];

    return DeeplinkParameterOverride(
      index: index,
      value: hasValueOverride ? overrideValue?.toString() ?? '' : null,
      hasValueOverride: hasValueOverride,
      enabled: enabledValue is bool ? enabledValue : null,
    );
  }
}
