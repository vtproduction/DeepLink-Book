import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_spacing.dart';
import '../data/deeplink_repository.dart';
import '../widgets/deeplink_form.dart';

class AddDeeplinkScreen extends ConsumerStatefulWidget {
  const AddDeeplinkScreen({super.key});

  @override
  ConsumerState<AddDeeplinkScreen> createState() => _AddDeeplinkScreenState();
}

class _AddDeeplinkScreenState extends ConsumerState<AddDeeplinkScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _descriptionController = TextEditingController();

  var _isSaving = false;

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

    try {
      await ref
          .read(deeplinkRepositoryProvider)
          .createDeeplink(
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
}
