import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_radius.dart';
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
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _SettingsSection(
              title: 'Data & Storage',
              metadata: 'LOCAL JSON',
              children: [
                _SettingsActionTile(
                  icon: Icons.file_upload_outlined,
                  iconColor: const Color(0xFF0D9488),
                  iconBackground: const Color(0xFFF0FDFA),
                  title: 'Import Project',
                  subtitle: 'Import a Deeplink Manager JSON file',
                  isBusy: _isImportingProject,
                  onTap: _isImportingProject ? null : _importProject,
                ),
                _SettingsActionTile(
                  icon: Icons.delete_outline,
                  iconColor: const Color(0xFFF43F5E),
                  iconBackground: const Color(0xFFFFF1F2),
                  title: 'Clear History',
                  subtitle: 'Remove every saved open-history entry',
                  isBusy: _isClearingHistory,
                  onTap: _isClearingHistory ? null : _confirmAndClearHistory,
                  isDestructive: true,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSection(
              title: 'Appearance & Runtime',
              metadata: 'UI CONTROLS',
              children: [
                _SettingsInfoTile(
                  icon: Icons.brightness_auto_outlined,
                  iconColor: Color(0xFFD97706),
                  iconBackground: Color(0xFFFFFBEB),
                  title: 'Theme Mode',
                  subtitle: 'Adaptive appearance preference',
                  value: 'System',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const _SettingsSection(
              title: 'Dev Suite Info',
              metadata: 'APP INFO',
              children: [
                _SettingsInfoTile(
                  icon: Icons.link,
                  iconColor: Colors.white,
                  iconBackground: Color(0xFF0891B2),
                  title: 'Deep Link Book',
                  subtitle: 'Local deeplink manager and testing suite',
                  badge: 'ACTIVE',
                ),
              ],
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.metadata,
    required this.children,
  });

  final String title;
  final String metadata;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '// ${title.toUpperCase()}',
                  style: textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF0F766E),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                metadata,
                style: textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD9E7E8)),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Column(
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  children[index],
                  if (index < children.length - 1)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFF1F5F9),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.isBusy,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool isBusy;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      minTileHeight: 76,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: _SettingsIcon(
        icon: icon,
        color: iconColor,
        background: iconBackground,
      ),
      title: Text(
        title,
        style: textTheme.titleMedium?.copyWith(
          color: isDestructive
              ? const Color(0xFFE11D48)
              : const Color(0xFF0F172A),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
      ),
      trailing: isBusy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      enabled: onTap != null,
      onTap: onTap,
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.value,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final String? value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      minTileHeight: 76,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: _SettingsIcon(
        icon: icon,
        color: iconColor,
        background: iconBackground,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                border: Border.all(color: const Color(0xFFA7F3D0)),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                child: Text(
                  badge!,
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF047857),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
      ),
      trailing: value == null
          ? null
          : Text(
              value!,
              style: textTheme.bodySmall?.copyWith(
                color: const Color(0xFF94A3B8),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: 44,
        child: Icon(icon, color: color, size: 23),
      ),
    );
  }
}
