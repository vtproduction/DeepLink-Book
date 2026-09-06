import 'package:flutter/material.dart';

import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

class QuickLinkCard extends StatelessWidget {
  const QuickLinkCard({
    super.key,
    required this.url,
    required this.onOpen,
    required this.onSaveEdit,
    this.isOpening = false,
  });

  final String url;
  final VoidCallback onOpen;
  final VoidCallback onSaveEdit;
  final bool isOpening;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1120), Color(0xFF111827), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const _ClipboardPulse(),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Clipboard Link Detected'.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF67E8F9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Target URL',
              style: textTheme.labelMedium?.copyWith(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB30F172A),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  url,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA5F3FC),
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: const Color(0xFF020617),
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    icon: isOpening
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: const Text('Open in App'),
                    onPressed: isOpening ? null : onOpen,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Tooltip(
                  message: 'Save clipboard deeplink',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE2E8F0),
                      side: const BorderSide(color: Color(0xFF334155)),
                      minimumSize: const Size(112, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onPressed: onSaveEdit,
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClipboardPulse extends StatelessWidget {
  const _ClipboardPulse();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF22D3EE),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Color(0x9922D3EE), blurRadius: 10)],
      ),
      child: const SizedBox.square(dimension: 10),
    );
  }
}
