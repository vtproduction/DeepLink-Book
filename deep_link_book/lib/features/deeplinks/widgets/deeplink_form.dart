import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../builder/deeplink_builder_editor.dart';
import '../builder/deeplink_parser.dart';
import '../builder/parsed_deeplink.dart';
import '../validation/deeplink_validator.dart';

enum _DeeplinkEditorMode { raw, builder }

class DeeplinkForm extends StatefulWidget {
  const DeeplinkForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.urlController,
    required this.descriptionController,
    required this.isSaving,
    required this.onSubmit,
    required this.submitLabel,
    this.organizationFields,
    this.environmentScheme,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController descriptionController;
  final bool isSaving;
  final VoidCallback onSubmit;
  final String submitLabel;
  final Widget? organizationFields;
  final String? environmentScheme;

  @override
  State<DeeplinkForm> createState() => _DeeplinkFormState();
}

class _DeeplinkFormState extends State<DeeplinkForm> {
  var _mode = _DeeplinkEditorMode.raw;
  var _isUpdatingRawProgrammatically = false;
  var _rawCannotSyncToBuilder = false;
  var _builderSyncVersion = 0;
  ParsedDeeplink? _lastValidParsedDeeplink;

  @override
  void initState() {
    super.initState();
    _syncBuilderFromRawUrl();
    widget.urlController.addListener(_handleRawUrlChanged);
  }

  @override
  void didUpdateWidget(covariant DeeplinkForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.urlController != oldWidget.urlController) {
      oldWidget.urlController.removeListener(_handleRawUrlChanged);
      _syncBuilderFromRawUrl();
      widget.urlController.addListener(_handleRawUrlChanged);
    }
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_handleRawUrlChanged);
    super.dispose();
  }

  void _handleRawUrlChanged() {
    if (_isUpdatingRawProgrammatically) {
      return;
    }

    setState(_syncBuilderFromRawUrl);
  }

  void _syncBuilderFromRawUrl() {
    final rawUrl = widget.urlController.text.trim();
    final parsed = DeeplinkParser.tryParse(rawUrl);

    if (parsed == null) {
      _rawCannotSyncToBuilder = rawUrl.isNotEmpty;
      return;
    }

    if (_lastValidParsedDeeplink != parsed) {
      _lastValidParsedDeeplink = parsed;
      _builderSyncVersion++;
    }
    _rawCannotSyncToBuilder = false;
  }

  void _handleBuilderUrlChanged(String url) {
    if (widget.urlController.text != url) {
      try {
        _isUpdatingRawProgrammatically = true;
        widget.urlController.text = url;
      } finally {
        _isUpdatingRawProgrammatically = false;
      }
    }

    setState(() {
      _lastValidParsedDeeplink = DeeplinkParser.tryParse(url);
      _rawCannotSyncToBuilder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?widget.organizationFields,
          TextFormField(
            controller: widget.nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Transfer Out',
            ),
            textInputAction: TextInputAction.next,
            validator: DeeplinkValidator.validateName,
            enabled: !widget.isSaving,
          ),
          const SizedBox(height: AppSpacing.md),
          SegmentedButton<_DeeplinkEditorMode>(
            segments: const [
              ButtonSegment(value: _DeeplinkEditorMode.raw, label: Text('Raw')),
              ButtonSegment(
                value: _DeeplinkEditorMode.builder,
                label: Text('Builder'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: widget.isSaving
                ? null
                : (selection) {
                    setState(() {
                      _mode = selection.single;
                    });
                  },
          ),
          const SizedBox(height: AppSpacing.md),
          if (_mode == _DeeplinkEditorMode.raw)
            _RawUrlField(
              urlController: widget.urlController,
              enabled: !widget.isSaving,
              rawCannotSyncToBuilder: _rawCannotSyncToBuilder,
            )
          else ...[
            DeeplinkBuilderEditor(
              parsedDeeplink: _lastValidParsedDeeplink,
              parsedDeeplinkVersion: _builderSyncVersion,
              rawCannotSyncToBuilder: _rawCannotSyncToBuilder,
              onUrlChanged: _handleBuilderUrlChanged,
              enabled: !widget.isSaving,
              environmentScheme: widget.environmentScheme,
            ),
            _BuilderUrlValidationField(urlController: widget.urlController),
          ],
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: widget.descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
            enabled: !widget.isSaving,
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: widget.isSaving ? null : widget.onSubmit,
              child: widget.isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuilderUrlValidationField extends StatelessWidget {
  const _BuilderUrlValidationField({required this.urlController});

  final TextEditingController urlController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FormField<String>(
      validator: (_) => DeeplinkValidator.validateUrl(urlController.text),
      builder: (field) {
        if (!field.hasError) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            field.errorText!,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        );
      },
    );
  }
}

class _RawUrlField extends StatelessWidget {
  const _RawUrlField({
    required this.urlController,
    required this.enabled,
    required this.rawCannotSyncToBuilder,
  });

  final TextEditingController urlController;
  final bool enabled;
  final bool rawCannotSyncToBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Deeplink URL',
            hintText: 'ascendbank-qa://transfer_out',
          ),
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          validator: DeeplinkValidator.validateUrl,
          enabled: enabled,
        ),
        if (rawCannotSyncToBuilder) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Raw URL is not currently valid for Builder.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
