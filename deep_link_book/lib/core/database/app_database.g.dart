// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Project({
    required this.id,
    required this.name,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Project copyWith({
    int? id,
    String? name,
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Project(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, description, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ProjectsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EnvironmentsTable extends Environments
    with TableInfo<$EnvironmentsTable, Environment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnvironmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemeMeta = const VerificationMeta('scheme');
  @override
  late final GeneratedColumn<String> scheme = GeneratedColumn<String>(
    'scheme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    name,
    scheme,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'environments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Environment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scheme')) {
      context.handle(
        _schemeMeta,
        scheme.isAcceptableOrUnknown(data['scheme']!, _schemeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Environment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Environment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scheme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheme'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EnvironmentsTable createAlias(String alias) {
    return $EnvironmentsTable(attachedDatabase, alias);
  }
}

class Environment extends DataClass implements Insertable<Environment> {
  final int id;
  final int projectId;
  final String name;
  final String? scheme;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Environment({
    required this.id,
    required this.projectId,
    required this.name,
    this.scheme,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || scheme != null) {
      map['scheme'] = Variable<String>(scheme);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EnvironmentsCompanion toCompanion(bool nullToAbsent) {
    return EnvironmentsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      name: Value(name),
      scheme: scheme == null && nullToAbsent
          ? const Value.absent()
          : Value(scheme),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Environment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Environment(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      name: serializer.fromJson<String>(json['name']),
      scheme: serializer.fromJson<String?>(json['scheme']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'name': serializer.toJson<String>(name),
      'scheme': serializer.toJson<String?>(scheme),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Environment copyWith({
    int? id,
    int? projectId,
    String? name,
    Value<String?> scheme = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Environment(
    id: id ?? this.id,
    projectId: projectId ?? this.projectId,
    name: name ?? this.name,
    scheme: scheme.present ? scheme.value : this.scheme,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Environment copyWithCompanion(EnvironmentsCompanion data) {
    return Environment(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      name: data.name.present ? data.name.value : this.name,
      scheme: data.scheme.present ? data.scheme.value : this.scheme,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Environment(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('scheme: $scheme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, projectId, name, scheme, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Environment &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.name == this.name &&
          other.scheme == this.scheme &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EnvironmentsCompanion extends UpdateCompanion<Environment> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> name;
  final Value<String?> scheme;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EnvironmentsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.name = const Value.absent(),
    this.scheme = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EnvironmentsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String name,
    this.scheme = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : projectId = Value(projectId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Environment> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? name,
    Expression<String>? scheme,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (name != null) 'name': name,
      if (scheme != null) 'scheme': scheme,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EnvironmentsCompanion copyWith({
    Value<int>? id,
    Value<int>? projectId,
    Value<String>? name,
    Value<String?>? scheme,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return EnvironmentsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      scheme: scheme ?? this.scheme,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scheme.present) {
      map['scheme'] = Variable<String>(scheme.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnvironmentsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('name: $name, ')
          ..write('scheme: $scheme, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DeeplinksTable extends Deeplinks
    with TableInfo<$DeeplinksTable, Deeplink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeeplinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _environmentIdMeta = const VerificationMeta(
    'environmentId',
  );
  @override
  late final GeneratedColumn<int> environmentId = GeneratedColumn<int>(
    'environment_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES environments (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openCountMeta = const VerificationMeta(
    'openCount',
  );
  @override
  late final GeneratedColumn<int> openCount = GeneratedColumn<int>(
    'open_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    projectId,
    environmentId,
    name,
    url,
    description,
    isFavorite,
    openCount,
    lastOpenedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deeplinks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deeplink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('environment_id')) {
      context.handle(
        _environmentIdMeta,
        environmentId.isAcceptableOrUnknown(
          data['environment_id']!,
          _environmentIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('open_count')) {
      context.handle(
        _openCountMeta,
        openCount.isAcceptableOrUnknown(data['open_count']!, _openCountMeta),
      );
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deeplink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deeplink(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}project_id'],
      ),
      environmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}environment_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      openCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}open_count'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeeplinksTable createAlias(String alias) {
    return $DeeplinksTable(attachedDatabase, alias);
  }
}

class Deeplink extends DataClass implements Insertable<Deeplink> {
  final int id;
  final int? projectId;
  final int? environmentId;
  final String name;
  final String url;
  final String? description;
  final bool isFavorite;
  final int openCount;
  final DateTime? lastOpenedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Deeplink({
    required this.id,
    this.projectId,
    this.environmentId,
    required this.name,
    required this.url,
    this.description,
    required this.isFavorite,
    required this.openCount,
    this.lastOpenedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<int>(projectId);
    }
    if (!nullToAbsent || environmentId != null) {
      map['environment_id'] = Variable<int>(environmentId);
    }
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['open_count'] = Variable<int>(openCount);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeeplinksCompanion toCompanion(bool nullToAbsent) {
    return DeeplinksCompanion(
      id: Value(id),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      environmentId: environmentId == null && nullToAbsent
          ? const Value.absent()
          : Value(environmentId),
      name: Value(name),
      url: Value(url),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isFavorite: Value(isFavorite),
      openCount: Value(openCount),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Deeplink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deeplink(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int?>(json['projectId']),
      environmentId: serializer.fromJson<int?>(json['environmentId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      description: serializer.fromJson<String?>(json['description']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      openCount: serializer.fromJson<int>(json['openCount']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int?>(projectId),
      'environmentId': serializer.toJson<int?>(environmentId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'description': serializer.toJson<String?>(description),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'openCount': serializer.toJson<int>(openCount),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Deeplink copyWith({
    int? id,
    Value<int?> projectId = const Value.absent(),
    Value<int?> environmentId = const Value.absent(),
    String? name,
    String? url,
    Value<String?> description = const Value.absent(),
    bool? isFavorite,
    int? openCount,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Deeplink(
    id: id ?? this.id,
    projectId: projectId.present ? projectId.value : this.projectId,
    environmentId: environmentId.present
        ? environmentId.value
        : this.environmentId,
    name: name ?? this.name,
    url: url ?? this.url,
    description: description.present ? description.value : this.description,
    isFavorite: isFavorite ?? this.isFavorite,
    openCount: openCount ?? this.openCount,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Deeplink copyWithCompanion(DeeplinksCompanion data) {
    return Deeplink(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      environmentId: data.environmentId.present
          ? data.environmentId.value
          : this.environmentId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      description: data.description.present
          ? data.description.value
          : this.description,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      openCount: data.openCount.present ? data.openCount.value : this.openCount,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deeplink(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('openCount: $openCount, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    environmentId,
    name,
    url,
    description,
    isFavorite,
    openCount,
    lastOpenedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deeplink &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.environmentId == this.environmentId &&
          other.name == this.name &&
          other.url == this.url &&
          other.description == this.description &&
          other.isFavorite == this.isFavorite &&
          other.openCount == this.openCount &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeeplinksCompanion extends UpdateCompanion<Deeplink> {
  final Value<int> id;
  final Value<int?> projectId;
  final Value<int?> environmentId;
  final Value<String> name;
  final Value<String> url;
  final Value<String?> description;
  final Value<bool> isFavorite;
  final Value<int> openCount;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DeeplinksCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.environmentId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.description = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.openCount = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DeeplinksCompanion.insert({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.environmentId = const Value.absent(),
    required String name,
    required String url,
    this.description = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.openCount = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       url = Value(url),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Deeplink> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<int>? environmentId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<String>? description,
    Expression<bool>? isFavorite,
    Expression<int>? openCount,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (environmentId != null) 'environment_id': environmentId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (description != null) 'description': description,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (openCount != null) 'open_count': openCount,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DeeplinksCompanion copyWith({
    Value<int>? id,
    Value<int?>? projectId,
    Value<int?>? environmentId,
    Value<String>? name,
    Value<String>? url,
    Value<String?>? description,
    Value<bool>? isFavorite,
    Value<int>? openCount,
    Value<DateTime?>? lastOpenedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DeeplinksCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      environmentId: environmentId ?? this.environmentId,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
      openCount: openCount ?? this.openCount,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (environmentId.present) {
      map['environment_id'] = Variable<int>(environmentId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (openCount.present) {
      map['open_count'] = Variable<int>(openCount.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinksCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('environmentId: $environmentId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('description: $description, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('openCount: $openCount, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DeeplinkHistoriesTable extends DeeplinkHistories
    with TableInfo<$DeeplinkHistoriesTable, DeeplinkHistory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeeplinkHistoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deeplinkIdMeta = const VerificationMeta(
    'deeplinkId',
  );
  @override
  late final GeneratedColumn<int> deeplinkId = GeneratedColumn<int>(
    'deeplink_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSuccessMeta = const VerificationMeta(
    'isSuccess',
  );
  @override
  late final GeneratedColumn<bool> isSuccess = GeneratedColumn<bool>(
    'is_success',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_success" IN (0, 1))',
    ),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deeplinkId,
    name,
    url,
    isSuccess,
    errorMessage,
    openedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deeplink_histories';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeeplinkHistory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deeplink_id')) {
      context.handle(
        _deeplinkIdMeta,
        deeplinkId.isAcceptableOrUnknown(data['deeplink_id']!, _deeplinkIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('is_success')) {
      context.handle(
        _isSuccessMeta,
        isSuccess.isAcceptableOrUnknown(data['is_success']!, _isSuccessMeta),
      );
    } else if (isInserting) {
      context.missing(_isSuccessMeta);
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeeplinkHistory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeeplinkHistory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deeplinkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deeplink_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      isSuccess: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_success'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
    );
  }

  @override
  $DeeplinkHistoriesTable createAlias(String alias) {
    return $DeeplinkHistoriesTable(attachedDatabase, alias);
  }
}

class DeeplinkHistory extends DataClass implements Insertable<DeeplinkHistory> {
  final int id;
  final int? deeplinkId;
  final String name;
  final String url;
  final bool isSuccess;
  final String? errorMessage;
  final DateTime openedAt;
  const DeeplinkHistory({
    required this.id,
    this.deeplinkId,
    required this.name,
    required this.url,
    required this.isSuccess,
    this.errorMessage,
    required this.openedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || deeplinkId != null) {
      map['deeplink_id'] = Variable<int>(deeplinkId);
    }
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['is_success'] = Variable<bool>(isSuccess);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    return map;
  }

  DeeplinkHistoriesCompanion toCompanion(bool nullToAbsent) {
    return DeeplinkHistoriesCompanion(
      id: Value(id),
      deeplinkId: deeplinkId == null && nullToAbsent
          ? const Value.absent()
          : Value(deeplinkId),
      name: Value(name),
      url: Value(url),
      isSuccess: Value(isSuccess),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      openedAt: Value(openedAt),
    );
  }

  factory DeeplinkHistory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeeplinkHistory(
      id: serializer.fromJson<int>(json['id']),
      deeplinkId: serializer.fromJson<int?>(json['deeplinkId']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      isSuccess: serializer.fromJson<bool>(json['isSuccess']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deeplinkId': serializer.toJson<int?>(deeplinkId),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'isSuccess': serializer.toJson<bool>(isSuccess),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'openedAt': serializer.toJson<DateTime>(openedAt),
    };
  }

  DeeplinkHistory copyWith({
    int? id,
    Value<int?> deeplinkId = const Value.absent(),
    String? name,
    String? url,
    bool? isSuccess,
    Value<String?> errorMessage = const Value.absent(),
    DateTime? openedAt,
  }) => DeeplinkHistory(
    id: id ?? this.id,
    deeplinkId: deeplinkId.present ? deeplinkId.value : this.deeplinkId,
    name: name ?? this.name,
    url: url ?? this.url,
    isSuccess: isSuccess ?? this.isSuccess,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    openedAt: openedAt ?? this.openedAt,
  );
  DeeplinkHistory copyWithCompanion(DeeplinkHistoriesCompanion data) {
    return DeeplinkHistory(
      id: data.id.present ? data.id.value : this.id,
      deeplinkId: data.deeplinkId.present
          ? data.deeplinkId.value
          : this.deeplinkId,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      isSuccess: data.isSuccess.present ? data.isSuccess.value : this.isSuccess,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinkHistory(')
          ..write('id: $id, ')
          ..write('deeplinkId: $deeplinkId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('isSuccess: $isSuccess, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deeplinkId, name, url, isSuccess, errorMessage, openedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeeplinkHistory &&
          other.id == this.id &&
          other.deeplinkId == this.deeplinkId &&
          other.name == this.name &&
          other.url == this.url &&
          other.isSuccess == this.isSuccess &&
          other.errorMessage == this.errorMessage &&
          other.openedAt == this.openedAt);
}

class DeeplinkHistoriesCompanion extends UpdateCompanion<DeeplinkHistory> {
  final Value<int> id;
  final Value<int?> deeplinkId;
  final Value<String> name;
  final Value<String> url;
  final Value<bool> isSuccess;
  final Value<String?> errorMessage;
  final Value<DateTime> openedAt;
  const DeeplinkHistoriesCompanion({
    this.id = const Value.absent(),
    this.deeplinkId = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.isSuccess = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.openedAt = const Value.absent(),
  });
  DeeplinkHistoriesCompanion.insert({
    this.id = const Value.absent(),
    this.deeplinkId = const Value.absent(),
    required String name,
    required String url,
    required bool isSuccess,
    this.errorMessage = const Value.absent(),
    required DateTime openedAt,
  }) : name = Value(name),
       url = Value(url),
       isSuccess = Value(isSuccess),
       openedAt = Value(openedAt);
  static Insertable<DeeplinkHistory> custom({
    Expression<int>? id,
    Expression<int>? deeplinkId,
    Expression<String>? name,
    Expression<String>? url,
    Expression<bool>? isSuccess,
    Expression<String>? errorMessage,
    Expression<DateTime>? openedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deeplinkId != null) 'deeplink_id': deeplinkId,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (isSuccess != null) 'is_success': isSuccess,
      if (errorMessage != null) 'error_message': errorMessage,
      if (openedAt != null) 'opened_at': openedAt,
    });
  }

  DeeplinkHistoriesCompanion copyWith({
    Value<int>? id,
    Value<int?>? deeplinkId,
    Value<String>? name,
    Value<String>? url,
    Value<bool>? isSuccess,
    Value<String?>? errorMessage,
    Value<DateTime>? openedAt,
  }) {
    return DeeplinkHistoriesCompanion(
      id: id ?? this.id,
      deeplinkId: deeplinkId ?? this.deeplinkId,
      name: name ?? this.name,
      url: url ?? this.url,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage ?? this.errorMessage,
      openedAt: openedAt ?? this.openedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deeplinkId.present) {
      map['deeplink_id'] = Variable<int>(deeplinkId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (isSuccess.present) {
      map['is_success'] = Variable<bool>(isSuccess.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinkHistoriesCompanion(')
          ..write('id: $id, ')
          ..write('deeplinkId: $deeplinkId, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('isSuccess: $isSuccess, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('openedAt: $openedAt')
          ..write(')'))
        .toString();
  }
}

class $DeeplinkVariantsTable extends DeeplinkVariants
    with TableInfo<$DeeplinkVariantsTable, DeeplinkVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeeplinkVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _deeplinkIdMeta = const VerificationMeta(
    'deeplinkId',
  );
  @override
  late final GeneratedColumn<int> deeplinkId = GeneratedColumn<int>(
    'deeplink_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES deeplinks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overridesJsonMeta = const VerificationMeta(
    'overridesJson',
  );
  @override
  late final GeneratedColumn<String> overridesJson = GeneratedColumn<String>(
    'overrides_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deeplinkId,
    name,
    overridesJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deeplink_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeeplinkVariant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('deeplink_id')) {
      context.handle(
        _deeplinkIdMeta,
        deeplinkId.isAcceptableOrUnknown(data['deeplink_id']!, _deeplinkIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deeplinkIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('overrides_json')) {
      context.handle(
        _overridesJsonMeta,
        overridesJson.isAcceptableOrUnknown(
          data['overrides_json']!,
          _overridesJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeeplinkVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeeplinkVariant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      deeplinkId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deeplink_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      overridesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overrides_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DeeplinkVariantsTable createAlias(String alias) {
    return $DeeplinkVariantsTable(attachedDatabase, alias);
  }
}

class DeeplinkVariant extends DataClass implements Insertable<DeeplinkVariant> {
  final int id;
  final int deeplinkId;
  final String name;
  final String overridesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  const DeeplinkVariant({
    required this.id,
    required this.deeplinkId,
    required this.name,
    required this.overridesJson,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['deeplink_id'] = Variable<int>(deeplinkId);
    map['name'] = Variable<String>(name);
    map['overrides_json'] = Variable<String>(overridesJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DeeplinkVariantsCompanion toCompanion(bool nullToAbsent) {
    return DeeplinkVariantsCompanion(
      id: Value(id),
      deeplinkId: Value(deeplinkId),
      name: Value(name),
      overridesJson: Value(overridesJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory DeeplinkVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeeplinkVariant(
      id: serializer.fromJson<int>(json['id']),
      deeplinkId: serializer.fromJson<int>(json['deeplinkId']),
      name: serializer.fromJson<String>(json['name']),
      overridesJson: serializer.fromJson<String>(json['overridesJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'deeplinkId': serializer.toJson<int>(deeplinkId),
      'name': serializer.toJson<String>(name),
      'overridesJson': serializer.toJson<String>(overridesJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  DeeplinkVariant copyWith({
    int? id,
    int? deeplinkId,
    String? name,
    String? overridesJson,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => DeeplinkVariant(
    id: id ?? this.id,
    deeplinkId: deeplinkId ?? this.deeplinkId,
    name: name ?? this.name,
    overridesJson: overridesJson ?? this.overridesJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  DeeplinkVariant copyWithCompanion(DeeplinkVariantsCompanion data) {
    return DeeplinkVariant(
      id: data.id.present ? data.id.value : this.id,
      deeplinkId: data.deeplinkId.present
          ? data.deeplinkId.value
          : this.deeplinkId,
      name: data.name.present ? data.name.value : this.name,
      overridesJson: data.overridesJson.present
          ? data.overridesJson.value
          : this.overridesJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinkVariant(')
          ..write('id: $id, ')
          ..write('deeplinkId: $deeplinkId, ')
          ..write('name: $name, ')
          ..write('overridesJson: $overridesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, deeplinkId, name, overridesJson, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeeplinkVariant &&
          other.id == this.id &&
          other.deeplinkId == this.deeplinkId &&
          other.name == this.name &&
          other.overridesJson == this.overridesJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DeeplinkVariantsCompanion extends UpdateCompanion<DeeplinkVariant> {
  final Value<int> id;
  final Value<int> deeplinkId;
  final Value<String> name;
  final Value<String> overridesJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const DeeplinkVariantsCompanion({
    this.id = const Value.absent(),
    this.deeplinkId = const Value.absent(),
    this.name = const Value.absent(),
    this.overridesJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  DeeplinkVariantsCompanion.insert({
    this.id = const Value.absent(),
    required int deeplinkId,
    required String name,
    this.overridesJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : deeplinkId = Value(deeplinkId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DeeplinkVariant> custom({
    Expression<int>? id,
    Expression<int>? deeplinkId,
    Expression<String>? name,
    Expression<String>? overridesJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deeplinkId != null) 'deeplink_id': deeplinkId,
      if (name != null) 'name': name,
      if (overridesJson != null) 'overrides_json': overridesJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  DeeplinkVariantsCompanion copyWith({
    Value<int>? id,
    Value<int>? deeplinkId,
    Value<String>? name,
    Value<String>? overridesJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return DeeplinkVariantsCompanion(
      id: id ?? this.id,
      deeplinkId: deeplinkId ?? this.deeplinkId,
      name: name ?? this.name,
      overridesJson: overridesJson ?? this.overridesJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (deeplinkId.present) {
      map['deeplink_id'] = Variable<int>(deeplinkId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (overridesJson.present) {
      map['overrides_json'] = Variable<String>(overridesJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeeplinkVariantsCompanion(')
          ..write('id: $id, ')
          ..write('deeplinkId: $deeplinkId, ')
          ..write('name: $name, ')
          ..write('overridesJson: $overridesJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $EnvironmentsTable environments = $EnvironmentsTable(this);
  late final $DeeplinksTable deeplinks = $DeeplinksTable(this);
  late final $DeeplinkHistoriesTable deeplinkHistories =
      $DeeplinkHistoriesTable(this);
  late final $DeeplinkVariantsTable deeplinkVariants = $DeeplinkVariantsTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    projects,
    environments,
    deeplinks,
    deeplinkHistories,
    deeplinkVariants,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'environments',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deeplinks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'deeplinks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deeplink_variants', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> description,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$EnvironmentsTable, List<Environment>>
  _environmentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.environments,
    aliasName: 'projects__id__environments__project_id',
  );

  $$EnvironmentsTableProcessedTableManager get environmentsRefs {
    final manager = $$EnvironmentsTableTableManager(
      $_db,
      $_db.environments,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_environmentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeeplinksTable, List<Deeplink>>
  _deeplinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deeplinks,
    aliasName: 'projects__id__deeplinks__project_id',
  );

  $$DeeplinksTableProcessedTableManager get deeplinksRefs {
    final manager = $$DeeplinksTableTableManager(
      $_db,
      $_db.deeplinks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_deeplinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> environmentsRefs(
    Expression<bool> Function($$EnvironmentsTableFilterComposer f) f,
  ) {
    final $$EnvironmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.environments,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnvironmentsTableFilterComposer(
            $db: $db,
            $table: $db.environments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deeplinksRefs(
    Expression<bool> Function($$DeeplinksTableFilterComposer f) f,
  ) {
    final $$DeeplinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableFilterComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> environmentsRefs<T extends Object>(
    Expression<T> Function($$EnvironmentsTableAnnotationComposer a) f,
  ) {
    final $$EnvironmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.environments,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnvironmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.environments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> deeplinksRefs<T extends Object>(
    Expression<T> Function($$DeeplinksTableAnnotationComposer a) f,
  ) {
    final $$DeeplinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableAnnotationComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, $$ProjectsTableReferences),
          Project,
          PrefetchHooks Function({bool environmentsRefs, bool deeplinksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ProjectsCompanion.insert(
                id: id,
                name: name,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({environmentsRefs = false, deeplinksRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (environmentsRefs) db.environments,
                    if (deeplinksRefs) db.deeplinks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (environmentsRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          Environment
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._environmentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).environmentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deeplinksRefs)
                        await $_getPrefetchedData<
                          Project,
                          $ProjectsTable,
                          Deeplink
                        >(
                          currentTable: table,
                          referencedTable: $$ProjectsTableReferences
                              ._deeplinksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProjectsTableReferences(
                                db,
                                table,
                                p0,
                              ).deeplinksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.projectId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, $$ProjectsTableReferences),
      Project,
      PrefetchHooks Function({bool environmentsRefs, bool deeplinksRefs})
    >;
typedef $$EnvironmentsTableCreateCompanionBuilder =
    EnvironmentsCompanion Function({
      Value<int> id,
      required int projectId,
      required String name,
      Value<String?> scheme,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$EnvironmentsTableUpdateCompanionBuilder =
    EnvironmentsCompanion Function({
      Value<int> id,
      Value<int> projectId,
      Value<String> name,
      Value<String?> scheme,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$EnvironmentsTableReferences
    extends BaseReferences<_$AppDatabase, $EnvironmentsTable, Environment> {
  $$EnvironmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('environments__project_id__projects__id');

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DeeplinksTable, List<Deeplink>>
  _deeplinksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deeplinks,
    aliasName: 'environments__id__deeplinks__environment_id',
  );

  $$DeeplinksTableProcessedTableManager get deeplinksRefs {
    final manager = $$DeeplinksTableTableManager(
      $_db,
      $_db.deeplinks,
    ).filter((f) => f.environmentId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_deeplinksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EnvironmentsTableFilterComposer
    extends Composer<_$AppDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheme => $composableBuilder(
    column: $table.scheme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> deeplinksRefs(
    Expression<bool> Function($$DeeplinksTableFilterComposer f) f,
  ) {
    final $$DeeplinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.environmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableFilterComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EnvironmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheme => $composableBuilder(
    column: $table.scheme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$EnvironmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnvironmentsTable> {
  $$EnvironmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scheme =>
      $composableBuilder(column: $table.scheme, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> deeplinksRefs<T extends Object>(
    Expression<T> Function($$DeeplinksTableAnnotationComposer a) f,
  ) {
    final $$DeeplinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.environmentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableAnnotationComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EnvironmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnvironmentsTable,
          Environment,
          $$EnvironmentsTableFilterComposer,
          $$EnvironmentsTableOrderingComposer,
          $$EnvironmentsTableAnnotationComposer,
          $$EnvironmentsTableCreateCompanionBuilder,
          $$EnvironmentsTableUpdateCompanionBuilder,
          (Environment, $$EnvironmentsTableReferences),
          Environment,
          PrefetchHooks Function({bool projectId, bool deeplinksRefs})
        > {
  $$EnvironmentsTableTableManager(_$AppDatabase db, $EnvironmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnvironmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnvironmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnvironmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> projectId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> scheme = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => EnvironmentsCompanion(
                id: id,
                projectId: projectId,
                name: name,
                scheme: scheme,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int projectId,
                required String name,
                Value<String?> scheme = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => EnvironmentsCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                scheme: scheme,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$EnvironmentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({projectId = false, deeplinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (deeplinksRefs) db.deeplinks],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (projectId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.projectId,
                                referencedTable: $$EnvironmentsTableReferences
                                    ._projectIdTable(db),
                                referencedColumn: $$EnvironmentsTableReferences
                                    ._projectIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (deeplinksRefs)
                    await $_getPrefetchedData<
                      Environment,
                      $EnvironmentsTable,
                      Deeplink
                    >(
                      currentTable: table,
                      referencedTable: $$EnvironmentsTableReferences
                          ._deeplinksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$EnvironmentsTableReferences(
                            db,
                            table,
                            p0,
                          ).deeplinksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.environmentId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$EnvironmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnvironmentsTable,
      Environment,
      $$EnvironmentsTableFilterComposer,
      $$EnvironmentsTableOrderingComposer,
      $$EnvironmentsTableAnnotationComposer,
      $$EnvironmentsTableCreateCompanionBuilder,
      $$EnvironmentsTableUpdateCompanionBuilder,
      (Environment, $$EnvironmentsTableReferences),
      Environment,
      PrefetchHooks Function({bool projectId, bool deeplinksRefs})
    >;
typedef $$DeeplinksTableCreateCompanionBuilder =
    DeeplinksCompanion Function({
      Value<int> id,
      Value<int?> projectId,
      Value<int?> environmentId,
      required String name,
      required String url,
      Value<String?> description,
      Value<bool> isFavorite,
      Value<int> openCount,
      Value<DateTime?> lastOpenedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DeeplinksTableUpdateCompanionBuilder =
    DeeplinksCompanion Function({
      Value<int> id,
      Value<int?> projectId,
      Value<int?> environmentId,
      Value<String> name,
      Value<String> url,
      Value<String?> description,
      Value<bool> isFavorite,
      Value<int> openCount,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DeeplinksTableReferences
    extends BaseReferences<_$AppDatabase, $DeeplinksTable, Deeplink> {
  $$DeeplinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('deeplinks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<int>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $EnvironmentsTable _environmentIdTable(_$AppDatabase db) => db
      .environments
      .createAlias('deeplinks__environment_id__environments__id');

  $$EnvironmentsTableProcessedTableManager? get environmentId {
    final $_column = $_itemColumn<int>('environment_id');
    if ($_column == null) return null;
    final manager = $$EnvironmentsTableTableManager(
      $_db,
      $_db.environments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_environmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$DeeplinkVariantsTable, List<DeeplinkVariant>>
  _deeplinkVariantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deeplinkVariants,
    aliasName: 'deeplinks__id__deeplink_variants__deeplink_id',
  );

  $$DeeplinkVariantsTableProcessedTableManager get deeplinkVariantsRefs {
    final manager = $$DeeplinkVariantsTableTableManager(
      $_db,
      $_db.deeplinkVariants,
    ).filter((f) => f.deeplinkId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _deeplinkVariantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DeeplinksTableFilterComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EnvironmentsTableFilterComposer get environmentId {
    final $$EnvironmentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.environmentId,
      referencedTable: $db.environments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnvironmentsTableFilterComposer(
            $db: $db,
            $table: $db.environments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> deeplinkVariantsRefs(
    Expression<bool> Function($$DeeplinkVariantsTableFilterComposer f) f,
  ) {
    final $$DeeplinkVariantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinkVariants,
      getReferencedColumn: (t) => t.deeplinkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinkVariantsTableFilterComposer(
            $db: $db,
            $table: $db.deeplinkVariants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeeplinksTableOrderingComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openCount => $composableBuilder(
    column: $table.openCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EnvironmentsTableOrderingComposer get environmentId {
    final $$EnvironmentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.environmentId,
      referencedTable: $db.environments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnvironmentsTableOrderingComposer(
            $db: $db,
            $table: $db.environments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeeplinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeeplinksTable> {
  $$DeeplinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openCount =>
      $composableBuilder(column: $table.openCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$EnvironmentsTableAnnotationComposer get environmentId {
    final $$EnvironmentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.environmentId,
      referencedTable: $db.environments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EnvironmentsTableAnnotationComposer(
            $db: $db,
            $table: $db.environments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> deeplinkVariantsRefs<T extends Object>(
    Expression<T> Function($$DeeplinkVariantsTableAnnotationComposer a) f,
  ) {
    final $$DeeplinkVariantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deeplinkVariants,
      getReferencedColumn: (t) => t.deeplinkId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinkVariantsTableAnnotationComposer(
            $db: $db,
            $table: $db.deeplinkVariants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DeeplinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeeplinksTable,
          Deeplink,
          $$DeeplinksTableFilterComposer,
          $$DeeplinksTableOrderingComposer,
          $$DeeplinksTableAnnotationComposer,
          $$DeeplinksTableCreateCompanionBuilder,
          $$DeeplinksTableUpdateCompanionBuilder,
          (Deeplink, $$DeeplinksTableReferences),
          Deeplink,
          PrefetchHooks Function({
            bool projectId,
            bool environmentId,
            bool deeplinkVariantsRefs,
          })
        > {
  $$DeeplinksTableTableManager(_$AppDatabase db, $DeeplinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeeplinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeeplinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeeplinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<int?> environmentId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DeeplinksCompanion(
                id: id,
                projectId: projectId,
                environmentId: environmentId,
                name: name,
                url: url,
                description: description,
                isFavorite: isFavorite,
                openCount: openCount,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> projectId = const Value.absent(),
                Value<int?> environmentId = const Value.absent(),
                required String name,
                required String url,
                Value<String?> description = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<int> openCount = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DeeplinksCompanion.insert(
                id: id,
                projectId: projectId,
                environmentId: environmentId,
                name: name,
                url: url,
                description: description,
                isFavorite: isFavorite,
                openCount: openCount,
                lastOpenedAt: lastOpenedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeeplinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                projectId = false,
                environmentId = false,
                deeplinkVariantsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (deeplinkVariantsRefs) db.deeplinkVariants,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (projectId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.projectId,
                                    referencedTable: $$DeeplinksTableReferences
                                        ._projectIdTable(db),
                                    referencedColumn: $$DeeplinksTableReferences
                                        ._projectIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (environmentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.environmentId,
                                    referencedTable: $$DeeplinksTableReferences
                                        ._environmentIdTable(db),
                                    referencedColumn: $$DeeplinksTableReferences
                                        ._environmentIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (deeplinkVariantsRefs)
                        await $_getPrefetchedData<
                          Deeplink,
                          $DeeplinksTable,
                          DeeplinkVariant
                        >(
                          currentTable: table,
                          referencedTable: $$DeeplinksTableReferences
                              ._deeplinkVariantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DeeplinksTableReferences(
                                db,
                                table,
                                p0,
                              ).deeplinkVariantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.deeplinkId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DeeplinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeeplinksTable,
      Deeplink,
      $$DeeplinksTableFilterComposer,
      $$DeeplinksTableOrderingComposer,
      $$DeeplinksTableAnnotationComposer,
      $$DeeplinksTableCreateCompanionBuilder,
      $$DeeplinksTableUpdateCompanionBuilder,
      (Deeplink, $$DeeplinksTableReferences),
      Deeplink,
      PrefetchHooks Function({
        bool projectId,
        bool environmentId,
        bool deeplinkVariantsRefs,
      })
    >;
typedef $$DeeplinkHistoriesTableCreateCompanionBuilder =
    DeeplinkHistoriesCompanion Function({
      Value<int> id,
      Value<int?> deeplinkId,
      required String name,
      required String url,
      required bool isSuccess,
      Value<String?> errorMessage,
      required DateTime openedAt,
    });
typedef $$DeeplinkHistoriesTableUpdateCompanionBuilder =
    DeeplinkHistoriesCompanion Function({
      Value<int> id,
      Value<int?> deeplinkId,
      Value<String> name,
      Value<String> url,
      Value<bool> isSuccess,
      Value<String?> errorMessage,
      Value<DateTime> openedAt,
    });

class $$DeeplinkHistoriesTableFilterComposer
    extends Composer<_$AppDatabase, $DeeplinkHistoriesTable> {
  $$DeeplinkHistoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deeplinkId => $composableBuilder(
    column: $table.deeplinkId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSuccess => $composableBuilder(
    column: $table.isSuccess,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeeplinkHistoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeeplinkHistoriesTable> {
  $$DeeplinkHistoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deeplinkId => $composableBuilder(
    column: $table.deeplinkId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSuccess => $composableBuilder(
    column: $table.isSuccess,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeeplinkHistoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeeplinkHistoriesTable> {
  $$DeeplinkHistoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get deeplinkId => $composableBuilder(
    column: $table.deeplinkId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<bool> get isSuccess =>
      $composableBuilder(column: $table.isSuccess, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);
}

class $$DeeplinkHistoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeeplinkHistoriesTable,
          DeeplinkHistory,
          $$DeeplinkHistoriesTableFilterComposer,
          $$DeeplinkHistoriesTableOrderingComposer,
          $$DeeplinkHistoriesTableAnnotationComposer,
          $$DeeplinkHistoriesTableCreateCompanionBuilder,
          $$DeeplinkHistoriesTableUpdateCompanionBuilder,
          (
            DeeplinkHistory,
            BaseReferences<
              _$AppDatabase,
              $DeeplinkHistoriesTable,
              DeeplinkHistory
            >,
          ),
          DeeplinkHistory,
          PrefetchHooks Function()
        > {
  $$DeeplinkHistoriesTableTableManager(
    _$AppDatabase db,
    $DeeplinkHistoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeeplinkHistoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeeplinkHistoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeeplinkHistoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deeplinkId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<bool> isSuccess = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
              }) => DeeplinkHistoriesCompanion(
                id: id,
                deeplinkId: deeplinkId,
                name: name,
                url: url,
                isSuccess: isSuccess,
                errorMessage: errorMessage,
                openedAt: openedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> deeplinkId = const Value.absent(),
                required String name,
                required String url,
                required bool isSuccess,
                Value<String?> errorMessage = const Value.absent(),
                required DateTime openedAt,
              }) => DeeplinkHistoriesCompanion.insert(
                id: id,
                deeplinkId: deeplinkId,
                name: name,
                url: url,
                isSuccess: isSuccess,
                errorMessage: errorMessage,
                openedAt: openedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeeplinkHistoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeeplinkHistoriesTable,
      DeeplinkHistory,
      $$DeeplinkHistoriesTableFilterComposer,
      $$DeeplinkHistoriesTableOrderingComposer,
      $$DeeplinkHistoriesTableAnnotationComposer,
      $$DeeplinkHistoriesTableCreateCompanionBuilder,
      $$DeeplinkHistoriesTableUpdateCompanionBuilder,
      (
        DeeplinkHistory,
        BaseReferences<_$AppDatabase, $DeeplinkHistoriesTable, DeeplinkHistory>,
      ),
      DeeplinkHistory,
      PrefetchHooks Function()
    >;
typedef $$DeeplinkVariantsTableCreateCompanionBuilder =
    DeeplinkVariantsCompanion Function({
      Value<int> id,
      required int deeplinkId,
      required String name,
      Value<String> overridesJson,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$DeeplinkVariantsTableUpdateCompanionBuilder =
    DeeplinkVariantsCompanion Function({
      Value<int> id,
      Value<int> deeplinkId,
      Value<String> name,
      Value<String> overridesJson,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$DeeplinkVariantsTableReferences
    extends
        BaseReferences<_$AppDatabase, $DeeplinkVariantsTable, DeeplinkVariant> {
  $$DeeplinkVariantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DeeplinksTable _deeplinkIdTable(_$AppDatabase db) =>
      db.deeplinks.createAlias('deeplink_variants__deeplink_id__deeplinks__id');

  $$DeeplinksTableProcessedTableManager get deeplinkId {
    final $_column = $_itemColumn<int>('deeplink_id')!;

    final manager = $$DeeplinksTableTableManager(
      $_db,
      $_db.deeplinks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deeplinkIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeeplinkVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $DeeplinkVariantsTable> {
  $$DeeplinkVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DeeplinksTableFilterComposer get deeplinkId {
    final $$DeeplinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deeplinkId,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableFilterComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeeplinkVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $DeeplinkVariantsTable> {
  $$DeeplinkVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DeeplinksTableOrderingComposer get deeplinkId {
    final $$DeeplinksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deeplinkId,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableOrderingComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeeplinkVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeeplinkVariantsTable> {
  $$DeeplinkVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get overridesJson => $composableBuilder(
    column: $table.overridesJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$DeeplinksTableAnnotationComposer get deeplinkId {
    final $$DeeplinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deeplinkId,
      referencedTable: $db.deeplinks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeeplinksTableAnnotationComposer(
            $db: $db,
            $table: $db.deeplinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeeplinkVariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeeplinkVariantsTable,
          DeeplinkVariant,
          $$DeeplinkVariantsTableFilterComposer,
          $$DeeplinkVariantsTableOrderingComposer,
          $$DeeplinkVariantsTableAnnotationComposer,
          $$DeeplinkVariantsTableCreateCompanionBuilder,
          $$DeeplinkVariantsTableUpdateCompanionBuilder,
          (DeeplinkVariant, $$DeeplinkVariantsTableReferences),
          DeeplinkVariant,
          PrefetchHooks Function({bool deeplinkId})
        > {
  $$DeeplinkVariantsTableTableManager(
    _$AppDatabase db,
    $DeeplinkVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeeplinkVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeeplinkVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeeplinkVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> deeplinkId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> overridesJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => DeeplinkVariantsCompanion(
                id: id,
                deeplinkId: deeplinkId,
                name: name,
                overridesJson: overridesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int deeplinkId,
                required String name,
                Value<String> overridesJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => DeeplinkVariantsCompanion.insert(
                id: id,
                deeplinkId: deeplinkId,
                name: name,
                overridesJson: overridesJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeeplinkVariantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deeplinkId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deeplinkId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deeplinkId,
                                referencedTable:
                                    $$DeeplinkVariantsTableReferences
                                        ._deeplinkIdTable(db),
                                referencedColumn:
                                    $$DeeplinkVariantsTableReferences
                                        ._deeplinkIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeeplinkVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeeplinkVariantsTable,
      DeeplinkVariant,
      $$DeeplinkVariantsTableFilterComposer,
      $$DeeplinkVariantsTableOrderingComposer,
      $$DeeplinkVariantsTableAnnotationComposer,
      $$DeeplinkVariantsTableCreateCompanionBuilder,
      $$DeeplinkVariantsTableUpdateCompanionBuilder,
      (DeeplinkVariant, $$DeeplinkVariantsTableReferences),
      DeeplinkVariant,
      PrefetchHooks Function({bool deeplinkId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$EnvironmentsTableTableManager get environments =>
      $$EnvironmentsTableTableManager(_db, _db.environments);
  $$DeeplinksTableTableManager get deeplinks =>
      $$DeeplinksTableTableManager(_db, _db.deeplinks);
  $$DeeplinkHistoriesTableTableManager get deeplinkHistories =>
      $$DeeplinkHistoriesTableTableManager(_db, _db.deeplinkHistories);
  $$DeeplinkVariantsTableTableManager get deeplinkVariants =>
      $$DeeplinkVariantsTableTableManager(_db, _db.deeplinkVariants);
}
