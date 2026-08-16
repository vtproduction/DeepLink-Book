import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/deeplink/deeplink_launcher.dart';
import '../../../core/database/app_database.dart';
import '../../../core/widgets/app_confirm_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../data/deeplink_repository.dart';
import '../providers/deeplink_providers.dart';
import '../validation/deeplink_validator.dart';
import '../widgets/deeplink_list_item.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int? _processingDeeplinkId;
  final _processingFavoriteIds = <int>{};
  final _openingDeeplinkIds = <int>{};

  @override
  Widget build(BuildContext context) {
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
                isProcessing: _processingDeeplinkId == deeplink.id,
                isFavoriteProcessing: _processingFavoriteIds.contains(
                  deeplink.id,
                ),
                isOpening: _openingDeeplinkIds.contains(deeplink.id),
                onTap: () => _openEditScreen(deeplink),
                onOpen: () => _openDeeplink(deeplink),
                onFavoriteTap: () => _toggleFavorite(deeplink),
                onEdit: () => _openEditScreen(deeplink),
                onDuplicate: () => _duplicateDeeplink(deeplink),
                onDelete: () => _confirmAndDeleteDeeplink(deeplink),
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

  void _openEditScreen(Deeplink deeplink) {
    context.pushNamed(
      AppRoute.editDeeplink.name,
      pathParameters: {'id': deeplink.id.toString()},
    );
  }

  Future<void> _openDeeplink(Deeplink deeplink) async {
    if (_openingDeeplinkIds.contains(deeplink.id)) {
      return;
    }

    final trimmedUrl = deeplink.url.trim();
    final validationError = DeeplinkValidator.validateUrl(trimmedUrl);

    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    setState(() {
      _openingDeeplinkIds.add(deeplink.id);
    });

    try {
      final launcher = ref.read(deeplinkLauncherProvider);
      final repository = ref.read(deeplinkRepositoryProvider);
      final launched = await launcher.open(Uri.parse(trimmedUrl));

      if (!mounted) {
        return;
      }

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No app can open this deeplink.')),
        );
        return;
      }

      await _recordSuccessfulOpen(repository, deeplink.id);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open deeplink.')));
    } finally {
      if (mounted) {
        setState(() {
          _openingDeeplinkIds.remove(deeplink.id);
        });
      }
    }
  }

  Future<void> _recordSuccessfulOpen(
    DeeplinkRepository repository,
    int deeplinkId,
  ) async {
    try {
      final recorded = await repository.recordDeeplinkOpened(deeplinkId);

      if (!mounted) {
        return;
      }

      if (!recorded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Deeplink opened, but its usage could not be updated.',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deeplink opened, but usage could not be saved.'),
        ),
      );
    }
  }

  Future<void> _toggleFavorite(Deeplink deeplink) async {
    if (_processingFavoriteIds.contains(deeplink.id)) {
      return;
    }

    setState(() {
      _processingFavoriteIds.add(deeplink.id);
    });

    try {
      final updated = await ref
          .read(deeplinkRepositoryProvider)
          .toggleFavorite(deeplink.id);

      if (!mounted) {
        return;
      }

      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update favorite.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingFavoriteIds.remove(deeplink.id);
        });
      }
    }
  }

  Future<void> _duplicateDeeplink(Deeplink deeplink) async {
    if (_processingDeeplinkId != null) {
      return;
    }

    setState(() {
      _processingDeeplinkId = deeplink.id;
    });

    try {
      final duplicatedId = await ref
          .read(deeplinkRepositoryProvider)
          .duplicateDeeplink(deeplink.id);

      if (!mounted) {
        return;
      }

      if (duplicatedId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to duplicate deeplink.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingDeeplinkId = null;
        });
      }
    }
  }

  Future<void> _confirmAndDeleteDeeplink(Deeplink deeplink) async {
    if (_processingDeeplinkId != null) {
      return;
    }

    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Delete deeplink?',
      message: 'This deeplink will be permanently removed.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!mounted || !confirmed) {
      return;
    }

    setState(() {
      _processingDeeplinkId = deeplink.id;
    });

    try {
      final deleted = await ref
          .read(deeplinkRepositoryProvider)
          .deleteDeeplink(deeplink.id);

      if (!mounted) {
        return;
      }

      if (!deleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This deeplink no longer exists.')),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete deeplink.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingDeeplinkId = null;
        });
      }
    }
  }
}
