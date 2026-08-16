import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../providers/history_providers.dart';
import '../widgets/history_list_item.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load history.',
            description: 'Please try again later.',
          ),
        ),
        data: (historyItems) {
          if (historyItems.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.history,
                title: 'No history yet',
                description: 'Opened deeplinks will appear here.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              return HistoryListItem(history: historyItems[index]);
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
    );
  }
}
