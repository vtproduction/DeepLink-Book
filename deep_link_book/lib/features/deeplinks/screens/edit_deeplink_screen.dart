import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/deeplink_repository.dart';
import '../providers/deeplink_providers.dart';
import '../widgets/deeplink_form.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deeplink.name);
    _urlController = TextEditingController(text: widget.deeplink.url);
    _descriptionController = TextEditingController(
      text: widget.deeplink.description ?? '',
    );
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
            onSubmit: _updateDeeplink,
            submitLabel: 'Save',
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

    try {
      final wasUpdated = await ref
          .read(deeplinkRepositoryProvider)
          .updateDeeplink(
            id: widget.deeplink.id,
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
