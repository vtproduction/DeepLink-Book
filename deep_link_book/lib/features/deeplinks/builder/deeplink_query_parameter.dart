class DeeplinkQueryParameter {
  const DeeplinkQueryParameter({required this.key, required this.value});

  final String key;
  final String value;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DeeplinkQueryParameter &&
            other.key == key &&
            other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}
