import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_radius.dart';
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
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
    this.projectField,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController descriptionController;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;
  final Widget? projectField;

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

  void _handleBuilderChanged(String url, ParsedDeeplink? parsedDeeplink) {
    if (widget.urlController.text != url) {
      try {
        _isUpdatingRawProgrammatically = true;
        widget.urlController.text = url;
      } finally {
        _isUpdatingRawProgrammatically = false;
      }
    }

    setState(() {
      _lastValidParsedDeeplink = parsedDeeplink;
      _rawCannotSyncToBuilder = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EditorSurface(
                    title: 'Basic Info',
                    child: _BasicInfoFields(
                      nameController: widget.nameController,
                      descriptionController: widget.descriptionController,
                      projectField: widget.projectField,
                      enabled: !widget.isSaving,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      child: SegmentedButton<_DeeplinkEditorMode>(
                        segments: const [
                          ButtonSegment(
                            value: _DeeplinkEditorMode.raw,
                            label: Text('Raw String'),
                          ),
                          ButtonSegment(
                            value: _DeeplinkEditorMode.builder,
                            label: Text('Builder Mode'),
                          ),
                        ],
                        selected: {_mode},
                        selectedIcon: const Icon(Icons.check, size: 16),
                        showSelectedIcon: true,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          selectedBackgroundColor: Colors.white,
                          selectedForegroundColor: const Color(0xFF0F172A),
                          backgroundColor: Colors.transparent,
                          foregroundColor: const Color(0xFF475569),
                          side: BorderSide.none,
                        ),
                        onSelectionChanged: widget.isSaving
                            ? null
                            : (selection) {
                                setState(() {
                                  _mode = selection.single;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _CurrentUrlPreview(urlController: widget.urlController),
                  const SizedBox(height: AppSpacing.lg),
                  if (_mode == _DeeplinkEditorMode.raw)
                    _EditorSurface(
                      title: 'Raw Deeplink',
                      child: _RawUrlField(
                        urlController: widget.urlController,
                        enabled: !widget.isSaving,
                        rawCannotSyncToBuilder: _rawCannotSyncToBuilder,
                      ),
                    )
                  else ...[
                    DeeplinkBuilderEditor(
                      parsedDeeplink: _lastValidParsedDeeplink,
                      parsedDeeplinkVersion: _builderSyncVersion,
                      rawCannotSyncToBuilder: _rawCannotSyncToBuilder,
                      onBuilderChanged: _handleBuilderChanged,
                      enabled: !widget.isSaving,
                    ),
                    _BuilderUrlValidationField(
                      urlController: widget.urlController,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          _EditorActionBar(
            isSaving: widget.isSaving,
            onCancel: widget.onCancel,
            onSubmit: widget.onSubmit,
            submitLabel: widget.submitLabel,
          ),
        ],
      ),
    );
  }
}

class _BasicInfoFields extends StatelessWidget {
  const _BasicInfoFields({
    required this.nameController,
    required this.descriptionController,
    required this.projectField,
    required this.enabled,
  });

  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final Widget? projectField;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final nameField = TextFormField(
      controller: nameController,
      decoration: const InputDecoration(
        labelText: 'Name',
        hintText: 'Transfer Out',
      ),
      textInputAction: TextInputAction.next,
      validator: DeeplinkValidator.validateName,
      enabled: enabled,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final projectField = this.projectField;

            if (projectField != null && constraints.maxWidth >= 300) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: nameField),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 2, child: projectField),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                nameField,
                if (projectField != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  projectField,
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Optional notes, intent, or ticket reference',
          ),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          maxLines: 3,
          enabled: enabled,
        ),
      ],
    );
  }
}

class _EditorSurface extends StatelessWidget {
  const _EditorSurface({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
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
            Row(
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w800,
                  ),
                ),
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

class _EditorActionBar extends StatelessWidget {
  const _EditorActionBar({
    required this.isSaving,
    required this.onCancel,
    required this.onSubmit,
    required this.submitLabel,
  });

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isSaving ? null : onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1329),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle, color: Color(0xFF22D3EE)),
                label: Text(submitLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentUrlPreview extends StatefulWidget {
  const _CurrentUrlPreview({required this.urlController});

  final TextEditingController urlController;

  @override
  State<_CurrentUrlPreview> createState() => _CurrentUrlPreviewState();
}

class _CurrentUrlPreviewState extends State<_CurrentUrlPreview> {
  @override
  void initState() {
    super.initState();
    widget.urlController.addListener(_handleUrlChanged);
  }

  @override
  void didUpdateWidget(covariant _CurrentUrlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.urlController != oldWidget.urlController) {
      oldWidget.urlController.removeListener(_handleUrlChanged);
      widget.urlController.addListener(_handleUrlChanged);
    }
  }

  @override
  void dispose() {
    widget.urlController.removeListener(_handleUrlChanged);
    super.dispose();
  }

  void _handleUrlChanged() {
    setState(() {});
  }

  Future<void> _copyUrl() async {
    final url = widget.urlController.text.trim();

    if (url.isEmpty) {
      return;
    }

    try {
      await Clipboard.setData(ClipboardData(text: url));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Current URL copied.')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to copy current URL.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final url = widget.urlController.text.trim();
    final hasUrl = url.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0B1329),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Current URL'.toUpperCase(),
                    style: textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF67E8F9),
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy current URL',
                  onPressed: hasUrl ? _copyUrl : null,
                  color: const Color(0xFFCBD5E1),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                  ),
                  icon: const Icon(Icons.content_copy, size: 19),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              hasUrl ? url : 'Current URL will appear here.',
              style: textTheme.bodyMedium?.copyWith(
                color: hasUrl
                    ? const Color(0xFF67E8F9)
                    : const Color(0xFF64748B),
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ],
        ),
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
