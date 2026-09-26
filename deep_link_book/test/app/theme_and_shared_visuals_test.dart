import 'package:deep_link_book/app/theme/app_theme.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/widgets/app_empty_state.dart';
import 'package:deep_link_book/core/widgets/app_error_state.dart';
import 'package:deep_link_book/features/deeplinks/widgets/deeplink_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('light theme exposes the Figma visual foundation', () {
    final theme = AppTheme.lightTheme;
    final colors = theme.colorScheme;
    final inputBorder = theme.inputDecorationTheme.enabledBorder;

    expect(theme.scaffoldBackgroundColor, const Color(0xFFF8F9FF));
    expect(colors.primary, const Color(0xFF005C55));
    expect(colors.surface, Colors.white);
    expect(colors.surfaceContainer, const Color(0xFFEFF4FF));
    expect(colors.surfaceContainerHigh, const Color(0xFFE5EEFF));
    expect(colors.onSurface, const Color(0xFF0B1C30));
    expect(colors.onSurfaceVariant, const Color(0xFF3E4947));
    expect(colors.outlineVariant, const Color(0xFFDCE9FF));
    expect(colors.error, const Color(0xFFBA1A1A));
    expect(theme.textTheme.titleMedium?.fontSize, 16);
    expect(theme.textTheme.titleMedium?.height, 22 / 16);
    expect(theme.textTheme.bodyMedium?.fontSize, 12);
    expect(theme.textTheme.bodyMedium?.height, 16 / 12);
    expect(theme.textTheme.labelSmall?.fontSize, 11);
    expect(theme.textTheme.labelSmall?.height, 14 / 11);
    expect((inputBorder as OutlineInputBorder).borderRadius.topLeft.x, 4);
  });

  testWidgets('deeplink item keeps data primary and actions compact', (
    tester,
  ) async {
    var openCount = 0;
    var copyCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: DeeplinkListItem(
            deeplink: _deeplink(),
            cardLayout: true,
            onOpen: () => openCount++,
            onCopy: () => copyCount++,
          ),
        ),
      ),
    );

    expect(find.text('Payment callback'), findsOneWidget);
    expect(find.text('myapp://payment?status=complete'), findsOneWidget);
    expect(find.text('Launch'), findsNothing);
    expect(find.byTooltip('Open Payment callback'), findsOneWidget);
    expect(find.byTooltip('Copy Payment callback'), findsOneWidget);
    expect(find.byTooltip('More actions for Payment callback'), findsOneWidget);

    await tester.tap(find.byTooltip('Open Payment callback'));
    await tester.tap(find.byTooltip('Copy Payment callback'));

    expect(openCount, 1);
    expect(copyCount, 1);
  });

  testWidgets('empty state uses compact visual hierarchy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppEmptyState(
            icon: Icons.link_off,
            title: 'No deeplinks',
            description: 'Create one to get started.',
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.link_off));
    final title = tester.widget<Text>(find.text('No deeplinks'));

    expect(icon.size, 32);
    expect(title.style?.fontSize, 16);
    expect(title.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('error state uses the semantic error color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: AppErrorState(
            title: 'Unable to load',
            description: 'Try again.',
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.error_outline));

    expect(icon.color, AppTheme.lightTheme.colorScheme.error);
  });
}

Deeplink _deeplink() {
  final now = DateTime(2026, 9, 20);

  return Deeplink(
    id: 1,
    projectId: 1,
    name: 'Payment callback',
    url: 'myapp://payment?status=complete',
    isFavorite: true,
    openCount: 3,
    createdAt: now,
    updatedAt: now,
  );
}
