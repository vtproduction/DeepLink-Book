import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

class AddDeeplinkScreen extends StatelessWidget {
  const AddDeeplinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Add Deeplink')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Text(
            'Add deeplink screen placeholder',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
