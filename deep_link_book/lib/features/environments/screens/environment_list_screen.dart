import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/environment_repository.dart';
import '../providers/environment_providers.dart';
import '../../projects/providers/project_providers.dart';

class EnvironmentListScreen extends ConsumerWidget {
  const EnvironmentListScreen({super.key, required this.projectId});

  final int? projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = projectId;

    if (id == null) {
      return const _EnvironmentStateScaffold(
        title: 'Project not found',
        description: 'The project ID is invalid.',
      );
    }

    final project = ref.watch(projectByIdProvider(id));
    final environments = ref.watch(environmentsForProjectProvider(id));

    return project.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => const _EnvironmentStateScaffold(
        title: 'Unable to load project',
        description: 'Please try again later.',
      ),
      data: (project) {
        if (project == null) {
          return const _EnvironmentStateScaffold(
            title: 'Project not found',
            description: 'The selected project no longer exists.',
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text('Environments - ${project.name}')),
          body: environments.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const Center(
              child: AppEmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load environments',
                description: 'Please try again later.',
              ),
            ),
            data: (environments) {
              if (environments.isEmpty) {
                return const Center(
                  child: AppEmptyState(
                    icon: Icons.tune,
                    title: 'No environments',
                    description:
                        'Add QA, UAT, Production, or another environment.',
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: environments.length,
                itemBuilder: (context, index) {
                  final environment = environments[index];

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(environment.name),
                    subtitle: Text(
                      environment.scheme == null
                          ? 'No scheme'
                          : 'scheme: ${environment.scheme}',
                    ),
                    trailing: PopupMenuButton<_EnvironmentAction>(
                      tooltip: 'Environment actions for ${environment.name}',
                      onSelected: (action) async {
                        switch (action) {
                          case _EnvironmentAction.edit:
                            await _showEnvironmentDialog(
                              context,
                              ref,
                              id,
                              environment,
                            );
                          case _EnvironmentAction.delete:
                            await _deleteEnvironment(context, ref, environment);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _EnvironmentAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem(
                          value: _EnvironmentAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
                separatorBuilder: (context, index) => const Divider(),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add environment',
            onPressed: () => _showEnvironmentDialog(context, ref, id),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _showEnvironmentDialog(
    BuildContext context,
    WidgetRef ref,
    int projectId, [
    Environment? environment,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) =>
          _EnvironmentDialog(projectId: projectId, environment: environment),
    );

    if (saved != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          environment == null ? 'Environment created.' : 'Environment saved.',
        ),
      ),
    );
  }

  Future<void> _deleteEnvironment(
    BuildContext context,
    WidgetRef ref,
    Environment environment,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete environment?',
      message:
          'Deeplinks using this environment will stay saved under All environments.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!context.mounted || !confirmed) {
      return;
    }

    final deleted = await ref
        .read(environmentRepositoryProvider)
        .deleteEnvironment(environment.id);

    if (!context.mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This environment no longer exists.')),
      );
      return;
    }

    if (ref.read(currentEnvironmentIdProvider) == environment.id) {
      ref.read(currentEnvironmentIdProvider.notifier).select(null);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Environment deleted.')));
  }
}

class _EnvironmentDialog extends ConsumerStatefulWidget {
  const _EnvironmentDialog({required this.projectId, this.environment});

  final int projectId;
  final Environment? environment;

  @override
  ConsumerState<_EnvironmentDialog> createState() => _EnvironmentDialogState();
}

class _EnvironmentDialogState extends ConsumerState<_EnvironmentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _schemeController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.environment?.name ?? '',
    );
    _schemeController = TextEditingController(
      text: widget.environment?.scheme ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schemeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.environment == null ? 'Add Environment' : 'Edit Environment',
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              textInputAction: TextInputAction.next,
              enabled: !_isSaving,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an environment name.';
                }

                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _schemeController,
              decoration: const InputDecoration(
                labelText: 'Scheme',
                hintText: 'Optional',
              ),
              enabled: !_isSaving,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => context.pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(widget.environment == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final scheme = _schemeController.text.trim();
    final repository = ref.read(environmentRepositoryProvider);

    try {
      final environment = widget.environment;

      if (environment == null) {
        await repository.createEnvironment(
          projectId: widget.projectId,
          name: name,
          scheme: scheme.isEmpty ? null : scheme,
        );
      } else {
        await repository.updateEnvironment(
          id: environment.id,
          name: name,
          scheme: scheme.isEmpty ? null : scheme,
        );
      }

      if (mounted) {
        context.pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to save environment.')),
      );
    }
  }
}

class _EnvironmentStateScaffold extends StatelessWidget {
  const _EnvironmentStateScaffold({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Environments')),
      body: Center(
        child: AppEmptyState(
          icon: Icons.tune,
          title: title,
          description: description,
          action: TextButton(
            onPressed: () => context.pop(),
            child: const Text('Back'),
          ),
        ),
      ),
    );
  }
}

enum _EnvironmentAction { edit, delete }
