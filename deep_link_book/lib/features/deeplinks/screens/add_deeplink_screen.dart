import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../data/deeplink_repository.dart';
import '../widgets/deeplink_organization_fields.dart';
import '../widgets/deeplink_form.dart';
import '../../environments/providers/environment_providers.dart';
import '../../projects/providers/project_providers.dart';

class AddDeeplinkScreen extends ConsumerStatefulWidget {
  const AddDeeplinkScreen({super.key, this.initialUrl});

  final String? initialUrl;

  @override
  ConsumerState<AddDeeplinkScreen> createState() => _AddDeeplinkScreenState();
}

class _AddDeeplinkScreenState extends ConsumerState<AddDeeplinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

  var _isSaving = false;
  int? _selectedProjectId;
  int? _selectedEnvironmentId;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl ?? '';
    _selectedProjectId = ref.read(currentProjectIdProvider);
    _selectedEnvironmentId = ref.read(currentEnvironmentIdProvider);
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

    _syncProjectSelection(projects);
    _syncEnvironmentSelection(environments);
    final environmentScheme = _selectedEnvironmentScheme(environments);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Deeplink')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: DeeplinkForm(
            formKey: _formKey,
            nameController: _nameController,
            urlController: _urlController,
            descriptionController: _descriptionController,
            isSaving: _isSaving,
            onSubmit: _saveDeeplink,
            submitLabel: 'Save',
            environmentScheme: environmentScheme,
            organizationFields: DeeplinkOrganizationFields(
              projects: projects,
              environments: environments,
              selectedProjectId: _selectedProjectId,
              selectedEnvironmentId: _selectedEnvironmentId,
              enabled: !_isSaving,
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
        ),
      ),
    );
  }

  Future<void> _saveDeeplink() async {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a project.')));
      return;
    }

    try {
      await ref
          .read(deeplinkRepositoryProvider)
          .createDeeplink(
            projectId: projectId,
            environmentId: _selectedEnvironmentId,
            name: name,
            url: url,
            description: description.isEmpty ? null : description,
          );

      if (!mounted) {
        return;
      }

      context.pop();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save deeplink.')));
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
