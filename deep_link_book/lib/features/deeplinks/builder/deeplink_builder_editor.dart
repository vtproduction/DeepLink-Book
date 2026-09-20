import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import 'deeplink_parser.dart';
import 'deeplink_query_parameter.dart';
import 'parsed_deeplink.dart';

class DeeplinkBuilderEditor extends StatefulWidget {
  const DeeplinkBuilderEditor({
    super.key,
    required this.parsedDeeplink,
    required this.parsedDeeplinkVersion,
    required this.rawCannotSyncToBuilder,
    required this.onBuilderChanged,
    required this.enabled,
  });

  final ParsedDeeplink? parsedDeeplink;
  final int parsedDeeplinkVersion;
  final bool rawCannotSyncToBuilder;
  final void Function(String url, ParsedDeeplink? parsedDeeplink)
  onBuilderChanged;
  final bool enabled;

  @override
  State<DeeplinkBuilderEditor> createState() => _DeeplinkBuilderEditorState();
}

class _DeeplinkBuilderEditorState extends State<DeeplinkBuilderEditor> {
  late final TextEditingController _schemeController;
  late final TextEditingController _hostController;
  late final TextEditingController _pathController;
  final _parameters = <_QueryParameterControllers>[];
  var _isApplyingParsedDeeplink = false;

  @override
  void initState() {
    super.initState();

    _schemeController = TextEditingController(
      text: widget.parsedDeeplink?.scheme ?? '',
    );
    _hostController = TextEditingController(
      text: widget.parsedDeeplink?.host ?? '',
    );
    _pathController = TextEditingController(
      text: widget.parsedDeeplink?.path ?? '',
    );

    _replaceParameters(widget.parsedDeeplink?.queryParameters ?? const []);

    _schemeController.addListener(_handleBuilderChanged);
    _hostController.addListener(_handleBuilderChanged);
    _pathController.addListener(_handleBuilderChanged);

    _updatePreview();
  }

  @override
  void didUpdateWidget(covariant DeeplinkBuilderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.parsedDeeplink != null &&
        widget.parsedDeeplinkVersion != oldWidget.parsedDeeplinkVersion) {
      _applyParsedDeeplink(widget.parsedDeeplink!);
    }
  }

  @override
  void dispose() {
    _schemeController.dispose();
    _hostController.dispose();
    _pathController.dispose();

    for (final parameter in _parameters) {
      parameter.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final activeParameterCount = _parameters
        .where((parameter) => parameter.enabled && !parameter.isEmpty)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.rawCannotSyncToBuilder) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Raw URL is currently invalid. Fix it before synchronizing with Builder.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _BuilderSurface(
          title: 'URL Structure',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final schemeField = _StructureTextField(
                controller: _schemeController,
                label: 'Scheme',
                hintText: 'myapp',
                enabled: widget.enabled,
              );
              final hostField = _StructureTextField(
                controller: _hostController,
                label: 'Host',
                hintText: 'detail',
                enabled: widget.enabled,
              );
              final pathField = _StructureTextField(
                controller: _pathController,
                label: 'Path',
                hintText: '/page',
                enabled: widget.enabled,
              );

              if (constraints.maxWidth >= 300) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: schemeField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 4, child: hostField),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(flex: 3, child: pathField),
                  ],
                );
              }

              return Column(
                children: [
                  schemeField,
                  const SizedBox(height: AppSpacing.sm),
                  hostField,
                  const SizedBox(height: AppSpacing.sm),
                  pathField,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _BuilderSurface(
          title: 'Query Parameters',
          badgeLabel: '$activeParameterCount active',
          action: OutlinedButton.icon(
            onPressed: widget.enabled ? _addParameter : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF155E75),
              backgroundColor: const Color(0xFFCFFAFE),
              side: const BorderSide(color: Color(0xFF67E8F9)),
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Param'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_parameters.isEmpty) const _EmptyParametersHint(),
              for (var index = 0; index < _parameters.length; index++) ...[
                _QueryParameterRow(
                  parameter: _parameters[index],
                  enabled: widget.enabled,
                  onDelete: () => _deleteParameter(index),
                  onChanged: _handleBuilderChanged,
                ),
                if (index < _parameters.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _addParameter() {
    setState(() {
      _parameters.add(
        _QueryParameterControllers()..addListener(_handleBuilderChanged),
      );
    });

    _handleBuilderChanged();
  }

  void _deleteParameter(int index) {
    final removed = _parameters.removeAt(index);
    removed.dispose();

    _handleBuilderChanged();
  }

  void _handleBuilderChanged() {
    if (_isApplyingParsedDeeplink) {
      return;
    }

    final parsed = _buildParsedDeeplink();
    final nextPreview = _updatePreview(parsed: parsed);
    widget.onBuilderChanged(nextPreview, parsed);
  }

  String _updatePreview({ParsedDeeplink? parsed}) {
    final deeplink = parsed ?? _buildParsedDeeplink();
    return deeplink == null ? '' : _tryBuildPreview(deeplink);
  }

  ParsedDeeplink? _buildParsedDeeplink() {
    final scheme = _schemeController.text.trim();
    final host = _hostController.text.trim();
    final path = _pathController.text.trim();

    if (scheme.isEmpty || (host.isEmpty && path.isEmpty)) {
      return null;
    }

    return ParsedDeeplink(
      scheme: scheme,
      host: host,
      path: path,
      queryParameters: _parameters
          .where((parameter) => !parameter.isEmpty)
          .map(
            (parameter) => DeeplinkQueryParameter(
              key: parameter.keyController.text.trim(),
              value: parameter.valueController.text,
              enabled: parameter.enabled,
              type: parameter.type,
            ),
          )
          .toList(),
    );
  }

  String _tryBuildPreview(ParsedDeeplink parsed) {
    try {
      final enabledDeeplink = parsed.copyWith(
        queryParameters: parsed.queryParameters
            .where((parameter) => parameter.enabled)
            .toList(),
      );

      return DeeplinkParser.build(enabledDeeplink);
    } catch (_) {
      return '';
    }
  }

  void _applyParsedDeeplink(ParsedDeeplink parsedDeeplink) {
    _isApplyingParsedDeeplink = true;
    _schemeController.text = parsedDeeplink.scheme;
    _hostController.text = parsedDeeplink.host;
    _pathController.text = parsedDeeplink.path;
    _replaceParameters(parsedDeeplink.queryParameters);
    _isApplyingParsedDeeplink = false;

    _updatePreview();
  }

  void _replaceParameters(List<DeeplinkQueryParameter> queryParameters) {
    for (final parameter in _parameters) {
      parameter.dispose();
    }

    _parameters
      ..clear()
      ..addAll(
        queryParameters.map(
          (parameter) => _QueryParameterControllers(
            keyText: parameter.key,
            valueText: parameter.value,
            enabled: parameter.enabled,
            type: parameter.type,
          )..addListener(_handleBuilderChanged),
        ),
      );
  }
}

class _QueryParameterRow extends StatelessWidget {
  const _QueryParameterRow({
    required this.parameter,
    required this.enabled,
    required this.onDelete,
    required this.onChanged,
  });

  final _QueryParameterControllers parameter;
  final bool enabled;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final parameterName = parameter.keyController.text.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: parameter.enabled
            ? const Color(0xFFF8FAFC)
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: parameter.enabled
              ? const Color(0xFFE2E8F0)
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Tooltip(
                  message: parameter.enabled
                      ? 'Included in generated URL'
                      : 'Excluded from generated URL',
                  child: Checkbox(
                    value: parameter.enabled,
                    visualDensity: VisualDensity.compact,
                    onChanged: enabled
                        ? (value) {
                            parameter.enabled = value ?? true;
                            onChanged();
                          }
                        : null,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parameterName.isEmpty ? 'New parameter' : parameterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge?.copyWith(
                          color: parameter.enabled
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF64748B),
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          decoration: parameter.enabled
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        parameter.enabled ? 'Included' : 'Excluded',
                        style: textTheme.labelSmall?.copyWith(
                          color: parameter.enabled
                              ? const Color(0xFF059669)
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 96,
                  child: DropdownButtonFormField<DeeplinkParameterType>(
                    initialValue: parameter.type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.sm,
                      ),
                    ),
                    items: DeeplinkParameterType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      );
                    }).toList(),
                    onChanged: enabled
                        ? (type) {
                            if (type == null) {
                              return;
                            }

                            parameter.setType(type);
                            onChanged();
                          }
                        : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete parameter',
                  onPressed: enabled ? onDelete : null,
                  visualDensity: VisualDensity.compact,
                  color: const Color(0xFF94A3B8),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final keyField = TextFormField(
                  controller: parameter.keyController,
                  decoration: const InputDecoration(
                    labelText: 'Key',
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enabled: enabled,
                );
                final valueField = _ParameterValueInput(
                  parameter: parameter,
                  enabled: enabled,
                  onChanged: onChanged,
                );

                if (constraints.maxWidth >= 280) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: keyField),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(flex: 7, child: valueField),
                    ],
                  );
                }

                return Column(
                  children: [
                    keyField,
                    const SizedBox(height: AppSpacing.sm),
                    valueField,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BuilderSurface extends StatelessWidget {
  const _BuilderSurface({
    required this.title,
    required this.child,
    this.badgeLabel,
    this.action,
  });

  final String title;
  final Widget child;
  final String? badgeLabel;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF06B6D4),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox.square(dimension: 8),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title.toUpperCase(),
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (badgeLabel != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFEFF),
                          border: Border.all(color: const Color(0xFF67E8F9)),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          child: Text(
                            badgeLabel!,
                            style: textTheme.labelSmall?.copyWith(
                              color: const Color(0xFF0E7490),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                ?action,
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _StructureTextField extends StatelessWidget {
  const _StructureTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.enabled,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
      ),
      style: const TextStyle(fontFamily: 'monospace'),
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enabled: enabled,
    );
  }
}

class _EmptyParametersHint extends StatelessWidget {
  const _EmptyParametersHint();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        'Add a parameter when this deeplink needs query values.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _ParameterValueInput extends StatelessWidget {
  const _ParameterValueInput({
    required this.parameter,
    required this.enabled,
    required this.onChanged,
  });

  final _QueryParameterControllers parameter;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    if (parameter.type == DeeplinkParameterType.boolean) {
      return DropdownButtonFormField<String>(
        initialValue: parameter.normalizedBooleanValue,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Value', isDense: true),
        items: const [
          DropdownMenuItem(value: 'true', child: Text('true')),
          DropdownMenuItem(value: 'false', child: Text('false')),
        ],
        onChanged: enabled
            ? (value) {
                if (value == null) {
                  return;
                }

                parameter.valueController.text = value;
                onChanged();
              }
            : null,
      );
    }

    return TextFormField(
      controller: parameter.valueController,
      decoration: const InputDecoration(labelText: 'Value', isDense: true),
      style: const TextStyle(fontFamily: 'monospace'),
      keyboardType: parameter.type == DeeplinkParameterType.number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      inputFormatters: parameter.type == DeeplinkParameterType.number
          ? const [_NumberTextInputFormatter()]
          : null,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enabled: enabled,
    );
  }
}

class _NumberTextInputFormatter extends TextInputFormatter {
  const _NumberTextInputFormatter();

  static final _partialNumberPattern = RegExp(r'^-?\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_partialNumberPattern.hasMatch(newValue.text)) {
      return newValue;
    }

    return oldValue;
  }
}

extension on _QueryParameterControllers {
  String get normalizedBooleanValue {
    if (valueController.text == 'false') {
      return 'false';
    }

    return 'true';
  }

  void setType(DeeplinkParameterType nextType) {
    type = nextType;

    switch (nextType) {
      case DeeplinkParameterType.boolean:
        valueController.text = normalizedBooleanValue;
        return;
      case DeeplinkParameterType.number:
        if (!_NumberTextInputFormatter._partialNumberPattern.hasMatch(
          valueController.text,
        )) {
          valueController.clear();
        }
        return;
      case DeeplinkParameterType.string:
      case DeeplinkParameterType.json:
        return;
    }
  }
}

class _QueryParameterControllers {
  _QueryParameterControllers({
    String keyText = '',
    String valueText = '',
    this.enabled = true,
    this.type = DeeplinkParameterType.string,
  }) : keyController = TextEditingController(text: keyText),
       valueController = TextEditingController(text: valueText) {
    if (type == DeeplinkParameterType.boolean) {
      valueController.text = normalizedBooleanValue;
    } else if (type == DeeplinkParameterType.number &&
        !_NumberTextInputFormatter._partialNumberPattern.hasMatch(valueText)) {
      valueController.clear();
    }
  }

  final TextEditingController keyController;
  final TextEditingController valueController;
  bool enabled;
  DeeplinkParameterType type;

  bool get isEmpty =>
      keyController.text.trim().isEmpty && valueController.text.isEmpty;

  void addListener(VoidCallback listener) {
    keyController.addListener(listener);
    valueController.addListener(listener);
  }

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}
