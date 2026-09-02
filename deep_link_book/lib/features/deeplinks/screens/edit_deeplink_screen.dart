import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/deeplink_repository.dart';
import '../providers/deeplink_providers.dart';
import '../widgets/deeplink_organization_fields.dart';
import '../widgets/deeplink_form.dart';
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

    _syncProjectSelection(projects);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Deeplink')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DeeplinkForm(
            formKey: _formKey,
            nameController: _nameController,
            urlController: _urlController,
            descriptionController: _descriptionController,
            isSaving: _isSaving,
            onCancel: _closeScreen,
            onSubmit: _updateDeeplink,
            submitLabel: 'Save',
            projectField: DeeplinkOrganizationFields(
              projects: projects,
              selectedProjectId: _selectedProjectId,
              enabled: !_isSaving,
              onProjectChanged: (projectId) {
                setState(() {
                  _selectedProjectId = projectId;
                  _selectedEnvironmentId =
                      projectId == widget.deeplink.projectId
                      ? widget.deeplink.environmentId
                      : null;
                });
              },
            ),
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

    setState(() {
      _isSaving = true;
    });

    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final description = _descriptionController.text.trim();
    final projectId = _selectedProjectId;

    if (projectId == null) {
      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a project.')));
      return;
    }

    try {
      final projectChanged = projectId != widget.deeplink.projectId;
      final wasUpdated = await ref
          .read(deeplinkRepositoryProvider)
          .updateDeeplink(
            id: widget.deeplink.id,
            projectId: projectChanged ? projectId : null,
            environmentId: projectChanged
                ? Value(_selectedEnvironmentId)
                : const Value.absent(),
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

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
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
