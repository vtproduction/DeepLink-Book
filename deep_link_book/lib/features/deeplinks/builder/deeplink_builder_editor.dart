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
    this.environmentScheme,
  });

  final ParsedDeeplink? parsedDeeplink;
  final int parsedDeeplinkVersion;
  final bool rawCannotSyncToBuilder;
  final void Function(String url, ParsedDeeplink? parsedDeeplink)
  onBuilderChanged;
  final bool enabled;
  final String? environmentScheme;

  @override
  State<DeeplinkBuilderEditor> createState() => _DeeplinkBuilderEditorState();
}

class _DeeplinkBuilderEditorState extends State<DeeplinkBuilderEditor> {
  late final TextEditingController _schemeController;
  late final TextEditingController _hostController;
  late final TextEditingController _pathController;
  final _parameters = <_QueryParameterControllers>[];
  var _previewUrl = '';
  var _hasUserEditedScheme = false;
  var _isApplyingParsedDeeplink = false;

  @override
  void initState() {
    super.initState();

    _schemeController = TextEditingController(
      text: widget.parsedDeeplink?.scheme ?? widget.environmentScheme ?? '',
    );
    _hostController = TextEditingController(
      text: widget.parsedDeeplink?.host ?? '',
    );
    _pathController = TextEditingController(
      text: widget.parsedDeeplink?.path ?? '',
    );

    _replaceParameters(widget.parsedDeeplink?.queryParameters ?? const []);

    _schemeController.addListener(() {
      if (!_isApplyingParsedDeeplink) {
        _hasUserEditedScheme = true;
      }

      _handleBuilderChanged();
    });
    _hostController.addListener(_handleBuilderChanged);
    _pathController.addListener(_handleBuilderChanged);

    _updatePreview(notify: false);
  }

  @override
  void didUpdateWidget(covariant DeeplinkBuilderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.environmentScheme != oldWidget.environmentScheme) {
      _applyEnvironmentSchemeIfUseful();
    }

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

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Builder', style: textTheme.titleMedium),
            if (widget.rawCannotSyncToBuilder) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Raw URL is currently invalid. Fix it before synchronizing with Builder.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _schemeController,
              decoration: InputDecoration(
                labelText: 'Scheme',
                suffixIcon: _canUseEnvironmentScheme
                    ? IconButton(
                        tooltip: 'Use environment scheme',
                        onPressed: widget.enabled
                            ? _useEnvironmentScheme
                            : null,
                        icon: const Icon(Icons.auto_fix_high),
                      )
                    : null,
              ),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: widget.enabled,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(labelText: 'Host'),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: widget.enabled,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _pathController,
              decoration: const InputDecoration(labelText: 'Path'),
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enabled: widget.enabled,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Query Parameters', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.enabled ? _addParameter : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Parameter'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Preview', style: textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              _previewUrl.isEmpty ? 'Preview will appear here.' : _previewUrl,
              style: textTheme.bodyMedium?.copyWith(
                color: _previewUrl.isEmpty
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canUseEnvironmentScheme {
    final environmentScheme = widget.environmentScheme;

    return environmentScheme != null &&
        environmentScheme.isNotEmpty &&
        _schemeController.text != environmentScheme;
  }

  void _applyEnvironmentSchemeIfUseful() {
    final environmentScheme = widget.environmentScheme;

    if (environmentScheme == null ||
        environmentScheme.isEmpty ||
        _hasUserEditedScheme ||
        _schemeController.text.isNotEmpty) {
      return;
    }

    _schemeController.text = environmentScheme;
  }

  void _useEnvironmentScheme() {
    final environmentScheme = widget.environmentScheme;

    if (environmentScheme == null || environmentScheme.isEmpty) {
      return;
    }

    _schemeController.text = environmentScheme;
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

  String _updatePreview({ParsedDeeplink? parsed, bool notify = true}) {
    final deeplink = parsed ?? _buildParsedDeeplink();
    final nextPreview = deeplink == null ? '' : _tryBuildPreview(deeplink);

    if (mounted && notify) {
      setState(() {
        _previewUrl = nextPreview;
      });
    } else {
      _previewUrl = nextPreview;
    }

    return nextPreview;
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: parameter.enabled
            ? colorScheme.surface
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: parameter.enabled
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Tooltip(
                    message: parameter.enabled
                        ? 'Included in generated URL'
                        : 'Excluded from generated URL',
                    child: Checkbox(
                      value: parameter.enabled,
                      onChanged: enabled
                          ? (value) {
                              parameter.enabled = value ?? true;
                              onChanged();
                            }
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: TextFormField(
                    controller: parameter.keyController,
                    decoration: const InputDecoration(
                      hintText: 'Key',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enabled: enabled,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: 'Delete parameter',
                  onPressed: enabled ? onDelete : null,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ParameterValueInput(
                      parameter: parameter,
                      enabled: enabled,
                      onChanged: onChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 128,
                    child: DropdownButtonFormField<DeeplinkParameterType>(
                      initialValue: parameter.type,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Type',
                        isDense: true,
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
                ],
              ),
            ),
          ],
        ),
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
        decoration: const InputDecoration(hintText: 'Value', isDense: true),
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
      decoration: const InputDecoration(hintText: 'Value', isDense: true),
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
