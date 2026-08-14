import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../validation/deeplink_validator.dart';

class DeeplinkForm extends StatelessWidget {
  const DeeplinkForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.urlController,
    required this.descriptionController,
    required this.isSaving,
    required this.onSubmit,
    required this.submitLabel,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController descriptionController;
  final bool isSaving;
  final VoidCallback onSubmit;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Transfer Out',
            ),
            textInputAction: TextInputAction.next,
            validator: DeeplinkValidator.validateName,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),
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
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            maxLines: 3,
            enabled: !isSaving,
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: isSaving ? null : onSubmit,
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}
