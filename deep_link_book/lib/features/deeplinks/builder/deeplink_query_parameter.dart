enum DeeplinkParameterType {
  string(label: 'String'),
  number(label: 'Number'),
  boolean(label: 'Boolean'),
  json(label: 'JSON');

  const DeeplinkParameterType({required this.label});

  final String label;
}

class DeeplinkQueryParameter {
  const DeeplinkQueryParameter({
    required this.key,
    required this.value,
    this.enabled = true,
    this.type = DeeplinkParameterType.string,
  });

  final String key;
  final String value;
  final bool enabled;
  final DeeplinkParameterType type;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeeplinkQueryParameter &&
            other.key == key &&
            other.value == value &&
            other.enabled == enabled &&
            other.type == type;
  }

  @override
  int get hashCode => Object.hash(key, value, enabled, type);
}
