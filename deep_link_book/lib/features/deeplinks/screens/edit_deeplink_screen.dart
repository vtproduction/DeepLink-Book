import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/deeplink_repository.dart';
import '../builder/deeplink_parser.dart';
import '../builder/parsed_deeplink.dart';
import '../providers/deeplink_providers.dart';
import '../variants/deeplink_variant_overrides.dart';
import '../variants/deeplink_variant_repository.dart';
import '../widgets/deeplink_organization_fields.dart';
import '../widgets/deeplink_form.dart';
import '../../environments/providers/environment_providers.dart';
import '../../projects/providers/project_providers.dart';

class EditDeeplinkScreen extends ConsumerWidget {
  const EditDeeplinkScreen({super.key, required this.deeplinkId});

  final int? deeplinkId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = deeplinkId;

    if (id == null) {
      return const _EditDeeplinkStateScaffold(
        icon: Icons.link_off,
        title: 'Deeplink not found',
        description: 'The deeplink ID is invalid.',
      );
    }

    final deeplink = ref.watch(deeplinkByIdProvider(id));

    return deeplink.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Edit Deeplink')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const _EditDeeplinkStateScaffold(
        icon: Icons.error_outline,
        title: 'Unable to load deeplink',
        description: 'Please try again later.',
      ),
      data: (deeplink) {
        if (deeplink == null) {
          return const _EditDeeplinkStateScaffold(
            icon: Icons.link_off,
            title: 'Deeplink not found',
            description: 'It may have been deleted.',
          );
        }

        return _EditDeeplinkFormContent(
          key: ValueKey(deeplink.id),
          deeplink: deeplink,
        );
      },
    );
  }
}

class _EditDeeplinkFormContent extends ConsumerStatefulWidget {
  const _EditDeeplinkFormContent({super.key, required this.deeplink});

  final Deeplink deeplink;

  @override
  ConsumerState<_EditDeeplinkFormContent> createState() {
    return _EditDeeplinkFormContentState();
  }
}

class _EditDeeplinkFormContentState
    extends ConsumerState<_EditDeeplinkFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _descriptionController;

  var _isSaving = false;
  late int? _selectedProjectId;
  late int? _selectedEnvironmentId;
  int? _selectedVariantId;
  DeeplinkVariant? _selectedVariantCache;
  ParsedDeeplink? _currentParsedDeeplink;
  ParsedDeeplink? _parsedDeeplinkOverride;
  var _parsedDeeplinkOverrideVersion = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deeplink.name);
    _urlController = TextEditingController(text: widget.deeplink.url);
    _descriptionController = TextEditingController(
      text: widget.deeplink.description ?? '',
    );
    _selectedProjectId = widget.deeplink.projectId;
    _selectedEnvironmentId = widget.deeplink.environmentId;
    _currentParsedDeeplink = DeeplinkParser.tryParse(widget.deeplink.url);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final environments = _selectedProjectId == null
        ? const AsyncValue<List<Environment>>.data([])
        : ref.watch(environmentsForProjectProvider(_selectedProjectId!));
    final variants = ref.watch(deeplinkVariantsProvider(widget.deeplink.id));

    _syncProjectSelection(projects);
    _syncEnvironmentSelection(environments);
    _syncVariantSelection(variants);
    final environmentScheme = _selectedEnvironmentScheme(environments);
    final isEditingVariant = _selectedVariantId != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deeplink')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _VariantSection(
                variants: variants,
                selectedVariantId: _selectedVariantId,
                onVariantChanged: _selectVariantById,
                onManageVariants: _openVariantManager,
              ),
              const SizedBox(height: AppSpacing.md),
              DeeplinkForm(
                formKey: _formKey,
                nameController: _nameController,
                urlController: _urlController,
                descriptionController: _descriptionController,
                isSaving: _isSaving,
                onSubmit: _updateDeeplink,
                submitLabel: isEditingVariant ? 'Save Variant' : 'Save',
                environmentScheme: environmentScheme,
                baseFieldsEnabled: !isEditingVariant,
                parsedDeeplinkOverride: _parsedDeeplinkOverride,
                parsedDeeplinkOverrideVersion: _parsedDeeplinkOverrideVersion,
                onParsedDeeplinkChanged: (parsedDeeplink) {
                  _currentParsedDeeplink = parsedDeeplink;
                },
                organizationFields: DeeplinkOrganizationFields(
                  projects: projects,
                  environments: environments,
                  selectedProjectId: _selectedProjectId,
                  selectedEnvironmentId: _selectedEnvironmentId,
                  enabled: !_isSaving && !isEditingVariant,
                  onProjectChanged: (projectId) {
                    setState(() {
                      _selectedProjectId = projectId;
                      _selectedEnvironmentId = null;
                    });
                  },
                  onEnvironmentChanged: (environmentId) {
                    setState(() {
                      _selectedEnvironmentId = environmentId;
                    });
                  },
                ),
              ),
              if (isEditingVariant) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Saving now updates only the selected variant. Select Default to edit the base deeplink.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateDeeplink() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    final selectedVariant =
        _selectedVariant(
          ref.read(deeplinkVariantsProvider(widget.deeplink.id)),
        ) ??
        _selectedVariantCache;

    if (selectedVariant != null) {
      await _updateVariant(selectedVariant);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final description = _descriptionController.text.trim();
    final projectId = _selectedProjectId;

    if (projectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a project.')));
      return;
    }

    try {
      final wasUpdated = await ref
          .read(deeplinkRepositoryProvider)
          .updateDeeplink(
            id: widget.deeplink.id,
            projectId: projectId,
            environmentId: Value(_selectedEnvironmentId),
            name: name,
            url: url,
            description: description.isEmpty ? null : description,
          );

      if (!mounted) {
        return;
      }

      if (wasUpdated) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This deeplink no longer exists.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update deeplink.')),
      );
    }
  }

  Future<void> _updateVariant(DeeplinkVariant variant) async {
    final base = DeeplinkParser.tryParse(widget.deeplink.url);
    final effective =
        _currentParsedDeeplink ?? DeeplinkParser.tryParse(_urlController.text);

    if (base == null || effective == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save variant overrides.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final overrides = DeeplinkVariantOverrides.fromDifference(
      base: base,
      effective: effective,
    );

    try {
      final wasUpdated = await ref
          .read(deeplinkVariantRepositoryProvider)
          .updateVariant(
            id: variant.id,
            name: variant.name,
            overridesJson: overrides.toJsonString(),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasUpdated ? 'Variant saved.' : 'This variant no longer exists.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save variant.')));
    }
  }

  DeeplinkVariant? _selectedVariant(
    AsyncValue<List<DeeplinkVariant>> variants,
  ) {
    final selectedVariantId = _selectedVariantId;

    if (selectedVariantId == null) {
      return null;
    }

    for (final variant in variants.value ?? const []) {
      if (variant.id == selectedVariantId) {
        return variant;
      }
    }

    return null;
  }

  void _syncVariantSelection(AsyncValue<List<DeeplinkVariant>> variants) {
    final selectedVariantId = _selectedVariantId;

    if (selectedVariantId == null) {
      return;
    }

    variants.whenData((variants) {
      final matchingVariants = variants.where(
        (variant) => variant.id == selectedVariantId,
      );
      final exists = matchingVariants.isNotEmpty;

      if (exists) {
        _selectedVariantCache = matchingVariants.first;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedVariantId != selectedVariantId) {
          return;
        }

        _selectDefaultVariant();
      });
    });
  }

  void _selectVariantById(int? variantId) {
    final variants = ref.read(deeplinkVariantsProvider(widget.deeplink.id));

    if (variantId == null) {
      _selectDefaultVariant();
      return;
    }

    final variant = variants.value
        ?.where((variant) => variant.id == variantId)
        .firstOrNull;

    if (variant == null) {
      return;
    }

    _selectVariant(variant);
  }

  void _selectDefaultVariant() {
    final parsed = DeeplinkParser.tryParse(widget.deeplink.url);

    setState(() {
      _selectedVariantId = null;
      _selectedVariantCache = null;
      _parsedDeeplinkOverride = parsed;
      _parsedDeeplinkOverrideVersion++;
      _currentParsedDeeplink = parsed;
      _urlController.text = widget.deeplink.url;
    });
  }

  void _selectVariant(DeeplinkVariant variant) {
    final base = DeeplinkParser.tryParse(widget.deeplink.url);

    if (base == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to apply variant.')));
      return;
    }

    final overrides = DeeplinkVariantOverrides.fromJsonString(
      variant.overridesJson,
    );
    final effective = overrides.applyTo(base);

    setState(() {
      _selectedVariantId = variant.id;
      _selectedVariantCache = variant;
      _parsedDeeplinkOverride = effective;
      _parsedDeeplinkOverrideVersion++;
      _urlController.text = _buildEffectiveUrl(effective);
      _currentParsedDeeplink = effective;
    });
  }

  String _buildEffectiveUrl(ParsedDeeplink parsedDeeplink) {
    final enabledDeeplink = parsedDeeplink.copyWith(
      queryParameters: parsedDeeplink.queryParameters
          .where((parameter) => parameter.enabled)
          .toList(),
    );

    return DeeplinkParser.build(enabledDeeplink);
  }

  Future<void> _openVariantManager() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return _VariantManagerSheet(
          deeplinkId: widget.deeplink.id,
          selectedVariantId: _selectedVariantId,
          onSelectDefault: () {
            Navigator.of(context).pop();
            _selectDefaultVariant();
          },
          onSelectVariant: (variant) {
            Navigator.of(context).pop();
            _selectVariant(variant);
          },
        );
      },
    );
  }

  void _syncProjectSelection(AsyncValue<List<Project>> projects) {
    if (_selectedProjectId != null) {
      return;
    }

    projects.whenData((projects) {
      if (projects.isEmpty) {
        return;
      }

      final defaultProjects = projects.where(
        (project) => project.name == AppDatabase.defaultProjectName,
      );
      final nextProject = defaultProjects.isNotEmpty
          ? defaultProjects.first
          : projects.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedProjectId != null) {
          return;
        }

        setState(() {
          _selectedProjectId = nextProject.id;
        });
      });
    });
  }

  void _syncEnvironmentSelection(AsyncValue<List<Environment>> environments) {
    final selectedEnvironmentId = _selectedEnvironmentId;

    if (selectedEnvironmentId == null) {
      return;
    }

    environments.whenData((environments) {
      final isValid = environments.any(
        (environment) => environment.id == selectedEnvironmentId,
      );

      if (isValid) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _selectedEnvironmentId != selectedEnvironmentId) {
          return;
        }

        setState(() {
          _selectedEnvironmentId = null;
        });
      });
    });
  }

  String? _selectedEnvironmentScheme(
    AsyncValue<List<Environment>> environments,
  ) {
    final selectedEnvironmentId = _selectedEnvironmentId;

    if (selectedEnvironmentId == null) {
      return null;
    }

    for (final environment in environments.value ?? const []) {
      if (environment.id == selectedEnvironmentId) {
        return environment.scheme;
      }
    }

    return null;
  }
}

class _VariantSection extends StatelessWidget {
  const _VariantSection({
    required this.variants,
    required this.selectedVariantId,
    required this.onVariantChanged,
    required this.onManageVariants,
  });

  final AsyncValue<List<DeeplinkVariant>> variants;
  final int? selectedVariantId;
  final ValueChanged<int?> onVariantChanged;
  final VoidCallback onManageVariants;

  @override
  Widget build(BuildContext context) {
    final values = variants.value ?? const <DeeplinkVariant>[];
    final hasSelectedVariant = values.any(
      (variant) => variant.id == selectedVariantId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Variant', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: hasSelectedVariant ? selectedVariantId : 0,
                decoration: const InputDecoration(
                  labelText: 'Selected variant',
                ),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('Default')),
                  for (final variant in values)
                    DropdownMenuItem(
                      value: variant.id,
                      child: Text(variant.name),
                    ),
                ],
                onChanged: variants.isLoading
                    ? null
                    : (value) {
                        onVariantChanged(value == 0 ? null : value);
                      },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: OutlinedButton.icon(
                onPressed: onManageVariants,
                icon: const Icon(Icons.tune),
                label: const Text('Manage'),
              ),
            ),
          ],
        ),
        if (variants.hasError) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load variants.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _VariantManagerSheet extends ConsumerWidget {
  const _VariantManagerSheet({
    required this.deeplinkId,
    required this.selectedVariantId,
    required this.onSelectDefault,
    required this.onSelectVariant,
  });

  final int deeplinkId;
  final int? selectedVariantId;
  final VoidCallback onSelectDefault;
  final ValueChanged<DeeplinkVariant> onSelectVariant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variants = ref.watch(deeplinkVariantsProvider(deeplinkId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Variants',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Add variant',
                  onPressed: () => _createVariant(context, ref),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.layers_outlined),
              title: const Text('Default'),
              subtitle: const Text('Base deeplink'),
              selected: selectedVariantId == null,
              onTap: onSelectDefault,
            ),
            variants.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'Unable to load variants.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              data: (variants) {
                if (variants.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'No saved variants yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: variants.length,
                    itemBuilder: (context, index) {
                      final variant = variants[index];

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.layers),
                        title: Text(variant.name),
                        subtitle: const Text('Select to edit overrides'),
                        selected: selectedVariantId == variant.id,
                        onTap: () => onSelectVariant(variant),
                        trailing: Wrap(
                          spacing: AppSpacing.xs,
                          children: [
                            IconButton(
                              tooltip: 'Rename variant',
                              onPressed: () =>
                                  _renameVariant(context, ref, variant),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              tooltip: 'Delete variant',
                              onPressed: () =>
                                  _deleteVariant(context, ref, variant),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createVariant(BuildContext context, WidgetRef ref) async {
    final name = await _askForVariantName(context, title: 'Add Variant');

    if (name == null || !context.mounted) {
      return;
    }

    try {
      final repository = ref.read(deeplinkVariantRepositoryProvider);
      final id = await repository.createVariant(
        deeplinkId: deeplinkId,
        name: name,
      );
      final createdVariant = await repository.getVariantById(id);

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Variant created.');

      if (createdVariant != null) {
        onSelectVariant(createdVariant);
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Unable to create variant.');
    }
  }

  Future<void> _renameVariant(
    BuildContext context,
    WidgetRef ref,
    DeeplinkVariant variant,
  ) async {
    final name = await _askForVariantName(
      context,
      title: 'Rename Variant',
      initialName: variant.name,
    );

    if (name == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(deeplinkVariantRepositoryProvider)
          .updateVariant(
            id: variant.id,
            name: name,
            overridesJson: variant.overridesJson,
          );

      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Variant renamed.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Unable to rename variant.');
    }
  }

  Future<void> _deleteVariant(
    BuildContext context,
    WidgetRef ref,
    DeeplinkVariant variant,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete Variant?',
      message: 'This only deletes the variant. The base deeplink stays saved.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(deeplinkVariantRepositoryProvider)
          .deleteVariant(variant.id);

      if (!context.mounted) {
        return;
      }

      if (selectedVariantId == variant.id) {
        _showMessage(context, 'Variant deleted.');
        onSelectDefault();
        return;
      }

      _showMessage(context, 'Variant deleted.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      _showMessage(context, 'Unable to delete variant.');
    }
  }

  Future<String?> _askForVariantName(
    BuildContext context, {
    required String title,
    String initialName = '',
  }) async {
    final controller = TextEditingController(text: initialName);

    try {
      final name = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Variant name'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitVariantName(context, controller),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _submitVariantName(context, controller),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      return name;
    } finally {
      controller.dispose();
    }
  }

  void _submitVariantName(
    BuildContext context,
    TextEditingController controller,
  ) {
    final name = controller.text.trim();

    if (name.isEmpty) {
      return;
    }

    Navigator.of(context).pop(name);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EditDeeplinkStateScaffold extends StatelessWidget {
  const _EditDeeplinkStateScaffold({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deeplink')),
      body: Center(
        child: AppEmptyState(
          icon: icon,
          title: title,
          description: description,
          action: TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/');
              }
            },
            child: const Text('Back'),
          ),
        ),
      ),
    );
  }
}
