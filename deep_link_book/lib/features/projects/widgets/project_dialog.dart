import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/database/app_database.dart';
import '../data/project_repository.dart';

Future<bool> showProjectDialog({
  required BuildContext context,
  Project? project,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xB3070E1E),
    builder: (context) => _ProjectDialog(project: project),
  );

  return saved == true;
}

class _ProjectDialog extends ConsumerStatefulWidget {
  const _ProjectDialog({this.project});

  final Project? project;

  @override
  ConsumerState<_ProjectDialog> createState() => _ProjectDialogState();
}

class _ProjectDialogState extends ConsumerState<_ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  var _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.project?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: const Color(0xFF0C1425),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      elevation: 24,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0x6600D4FF)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 370),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF102942),
                        border: Border.all(color: const Color(0x6600D4FF)),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: const [
                          BoxShadow(color: Color(0x3300D4FF), blurRadius: 14),
                        ],
                      ),
                      child: const SizedBox.square(
                        dimension: 48,
                        child: Icon(
                          Icons.folder_open_outlined,
                          color: Color(0xFF22D3EE),
                          size: 25,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                isEditing ? 'Edit Project' : 'New Project',
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF083344),
                                  border: Border.all(
                                    color: const Color(0x6600D4FF),
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    'SUITE',
                                    style: textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF67E8F9),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            isEditing
                                ? 'Manage workspace details'
                                : 'Create a workspace for related deeplinks',
                            style: textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _isSaving ? null : () => context.pop(false),
                      color: const Color(0xFF94A3B8),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF17233A),
                      ),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: Color(0xFF1E293B)),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Project Name',
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Text(
                      '*',
                      style: TextStyle(
                        color: Color(0xFF22D3EE),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Required',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  cursorColor: const Color(0xFF22D3EE),
                  decoration: _fieldDecoration(
                    hintText: 'Enter workspace name',
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !_isSaving,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a project name.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Text(
                      'Description',
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFFCBD5E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Optional',
                      style: textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Color(0xFFE2E8F0)),
                  cursorColor: const Color(0xFF22D3EE),
                  decoration: _fieldDecoration(
                    hintText: 'Brief context for this workspace',
                  ),
                  minLines: 3,
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  enabled: !_isSaving,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => context.pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE2E8F0),
                          backgroundColor: const Color(0xFF17233A),
                          side: const BorderSide(color: Color(0xFF334155)),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: FilledButton(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          foregroundColor: const Color(0xFF07111F),
                          backgroundColor: const Color(0xFF5EEAD4),
                          disabledBackgroundColor: const Color(0xFF334155),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF07111F),
                                ),
                              )
                            : FittedBox(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, size: 20),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      isEditing
                                          ? 'Save Changes'
                                          : 'Add Project',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hintText}) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide: BorderSide(color: Color(0xFF334155)),
    );

    return const InputDecoration(
      filled: true,
      fillColor: Color(0xFF131D34),
      hintStyle: TextStyle(color: Color(0xFF64748B)),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFF22D3EE), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFFFB7185)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
        borderSide: BorderSide(color: Color(0xFFFB7185), width: 1.5),
      ),
      errorStyle: TextStyle(color: Color(0xFFFDA4AF)),
    ).copyWith(hintText: hintText);
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
    final description = _descriptionController.text.trim();
    final repository = ref.read(projectRepositoryProvider);

    try {
      final project = widget.project;

      if (project == null) {
        await repository.createProject(
          name: name,
          description: description.isEmpty ? null : description,
        );
      } else {
        await repository.updateProject(
          id: project.id,
          name: name,
          description: description.isEmpty ? null : description,
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to save project.')));
    }
  }
}
