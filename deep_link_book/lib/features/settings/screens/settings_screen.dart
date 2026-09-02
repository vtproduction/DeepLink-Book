import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../environments/providers/environment_providers.dart';
import '../../history/data/history_repository.dart';
import '../../import_export/import_export_file_service.dart';
import '../../import_export/project_importer.dart';
import '../../import_export/widgets/import_project_preview_dialog.dart';
import '../../projects/providers/project_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  var _isImportingProject = false;
  var _isClearingHistory = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _SettingsSectionTitle('Data'),
            _SettingsActionTile(
              icon: Icons.upload_file,
              title: 'Import Project',
              subtitle: 'Import a Deeplink Manager JSON file.',
              isBusy: _isImportingProject,
              onTap: _isImportingProject ? null : _importProject,
            ),
            _SettingsActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Clear History',
              subtitle: 'Remove every saved open-history entry.',
              isBusy: _isClearingHistory,
              onTap: _isClearingHistory ? null : _confirmAndClearHistory,
              isDestructive: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionTitle('Appearance'),
            const _SettingsInfoTile(
              icon: Icons.brightness_auto_outlined,
              title: 'Theme',
              value: 'Uses system setting',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSectionTitle('About'),
            const _SettingsInfoTile(
              icon: Icons.info_outline,
              title: 'Deep Link Book',
              value: 'Local deeplink manager',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importProject() async {
    setState(() {
      _isImportingProject = true;
    });

    try {
      final content = await ref
          .read(importExportFileServiceProvider)
          .pickImportFileContent();

      if (content == null || !mounted) {
        return;
      }

      final importer = ref.read(projectImporterProvider);
      final preview = importer.previewImport(content);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => ImportProjectPreviewDialog(preview: preview),
      );

      if (confirmed != true || !mounted) {
        return;
      }

      final result = await importer.importProject(content);

      if (!mounted) {
        return;
      }

      ref.read(currentProjectIdProvider.notifier).select(result.projectId);
      ref.read(currentEnvironmentIdProvider.notifier).select(null);
      _showSnackBar('Imported "${result.projectName}".');
    } on ProjectImportException catch (error) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Import failed: ${error.message}');
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to import project.');
    } finally {
      if (mounted) {
        setState(() {
          _isImportingProject = false;
        });
      }
    }
  }

  Future<void> _confirmAndClearHistory() async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Clear history?',
      message: 'This will permanently remove all history entries.',
      confirmLabel: 'Clear',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _isClearingHistory = true;
    });

    try {
      final deletedCount = await ref
          .read(historyRepositoryProvider)
          .clearHistory();

      if (!mounted) {
        return;
      }

      _showSnackBar(
        deletedCount == 1
            ? 'Cleared 1 history entry.'
            : 'Cleared $deletedCount history entries.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showSnackBar('Unable to clear history.');
    } finally {
      if (mounted) {
        setState(() {
          _isClearingHistory = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isBusy;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isBusy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title),
      subtitle: Text(value),
    );
  }
}
