import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../providers/deeplink_providers.dart';
import '../widgets/deeplink_list_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deeplinks = ref.watch(deeplinksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: deeplinks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: AppEmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load deeplinks',
            description: 'Please try again later.',
          ),
        ),
        data: (deeplinks) {
          if (deeplinks.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.link_off,
                title: 'No deeplinks yet',
                description: 'Create your first deeplink to get started.',
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: deeplinks.length,
            itemBuilder: (context, index) {
              final deeplink = deeplinks[index];

              return DeeplinkListItem(
                deeplink: deeplink,
                onTap: () {
                  context.pushNamed(
                    AppRoute.editDeeplink.name,
                    pathParameters: {'id': deeplink.id.toString()},
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const Divider(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Deeplink',
        onPressed: () => context.pushNamed(AppRoute.addDeeplink.name),
        child: const Icon(Icons.add),
      ),
    );
  }
}
