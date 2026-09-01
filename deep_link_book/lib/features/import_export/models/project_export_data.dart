import 'dart:convert';

class ProjectExportData {
  const ProjectExportData({
    required this.version,
    required this.project,
    required this.environments,
    required this.deeplinks,
  });

  static const currentVersion = 1;

  final int version;
  final ExportedProject project;
  final List<ExportedEnvironment> environments;
  final List<ExportedDeeplink> deeplinks;

  factory ProjectExportData.fromJson(Map<String, Object?> json) {
    return ProjectExportData(
      version: _readInt(json, 'version'),
      project: ExportedProject.fromJson(_readMap(json, 'project')),
      environments: _readList(
        json,
        'environments',
      ).map((item) => ExportedEnvironment.fromJson(_asMap(item))).toList(),
      deeplinks: _readList(
        json,
        'deeplinks',
      ).map((item) => ExportedDeeplink.fromJson(_asMap(item))).toList(),
    );
  }

  factory ProjectExportData.fromJsonString(String content) {
    final decoded = jsonDecode(content);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Import file must contain a JSON object.');
    }

    return ProjectExportData.fromJson(decoded);
  }

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'project': project.toJson(),
      'environments': environments.map((environment) {
        return environment.toJson();
      }).toList(),
      'deeplinks': deeplinks.map((deeplink) {
        return deeplink.toJson();
      }).toList(),
    };
  }

  String toPrettyJson() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}

class ExportedProject {
  const ExportedProject({required this.name, this.description});

  final String name;
  final String? description;

  factory ExportedProject.fromJson(Map<String, Object?> json) {
    return ExportedProject(
      name: _readString(json, 'name'),
      description: _readOptionalString(json, 'description'),
    );
  }

  Map<String, Object?> toJson() {
    return {'name': name, 'description': description};
  }
}

class ExportedEnvironment {
  const ExportedEnvironment({
    required this.key,
    required this.name,
    this.scheme,
  });

  final String key;
  final String name;
  final String? scheme;

  factory ExportedEnvironment.fromJson(Map<String, Object?> json) {
    return ExportedEnvironment(
      key: _readString(json, 'key'),
      name: _readString(json, 'name'),
      scheme: _readOptionalString(json, 'scheme'),
    );
  }

  Map<String, Object?> toJson() {
    return {'key': key, 'name': name, 'scheme': scheme};
  }
}

class ExportedDeeplink {
  const ExportedDeeplink({
    required this.name,
    required this.url,
    required this.favorite,
    this.description,
    this.environmentKey,
  });

  final String name;
  final String url;
  final bool favorite;
  final String? description;
  final String? environmentKey;

  factory ExportedDeeplink.fromJson(Map<String, Object?> json) {
    return ExportedDeeplink(
      name: _readString(json, 'name'),
      url: _readString(json, 'url'),
      description: _readOptionalString(json, 'description'),
      environmentKey: _readOptionalString(json, 'environmentKey'),
      favorite: _readBool(json, 'favorite'),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'description': description,
      'url': url,
      'environmentKey': environmentKey,
      'favorite': favorite,
    };
  }
}

int _readInt(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  throw FormatException('$key must be a number.');
}

bool _readBool(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is bool) {
    return value;
  }

  throw FormatException('$key must be true or false.');
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is String) {
    return value;
  }

  throw FormatException('$key must be text.');
}

String? _readOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  if (value is String) {
    return value;
  }

  throw FormatException('$key must be text.');
}

Map<String, Object?> _readMap(Map<String, Object?> json, String key) {
  return _asMap(json[key]);
}

List<Object?> _readList(Map<String, Object?> json, String key) {
  final value = json[key];

  if (value is List<Object?>) {
    return value;
  }

  throw FormatException('$key must be a list.');
}

Map<String, Object?> _asMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }

  throw const FormatException('Expected a JSON object.');
}
