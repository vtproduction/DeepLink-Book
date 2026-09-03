import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import 'deeplink_command_builder.dart';

Future<void> showDeveloperToolsSheet({
  required BuildContext context,
  required String url,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return DeveloperToolsView(url: url);
    },
  );
}

class DeveloperToolsView extends StatelessWidget {
  const DeveloperToolsView({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final adbCommand = buildAdbCommand(url);
    final simctlCommand = buildSimctlCommand(url);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Developer Tools',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            _ToolSection(
              title: 'URL',
              value: url,
              copyLabel: 'Copy URL',
              onCopy: () => _copyText(context, url, 'URL copied.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('QR Code', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: QrImageView(
                    data: url,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ToolSection(
              title: 'Android ADB',
              value: adbCommand,
              copyLabel: 'Copy ADB command',
              onCopy: () =>
                  _copyText(context, adbCommand, 'ADB command copied.'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ToolSection(
              title: 'iOS Simulator',
              value: simctlCommand,
              copyLabel: 'Copy simctl command',
              onCopy: () =>
                  _copyText(context, simctlCommand, 'simctl command copied.'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String successMessage,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to copy to clipboard.')),
        );
    }
  }
}

class _ToolSection extends StatelessWidget {
  const _ToolSection({
    required this.title,
    required this.value,
    required this.copyLabel,
    required this.onCopy,
  });

  final String title;
  final String value;
  final String copyLabel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: copyLabel,
              onPressed: onCopy,
              icon: const Icon(Icons.content_copy),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SelectableText(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
