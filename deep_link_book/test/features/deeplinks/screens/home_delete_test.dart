import 'dart:async';

import 'package:deep_link_book/app/app.dart';
import 'package:deep_link_book/app/router.dart';
import 'package:deep_link_book/core/deeplink/deeplink_launcher.dart';
import 'package:deep_link_book/core/database/app_database.dart';
import 'package:deep_link_book/core/database/database_provider.dart';
import 'package:deep_link_book/features/deeplinks/data/deeplink_repository.dart';
import 'package:deep_link_book/features/deeplinks/providers/deeplink_providers.dart';
import 'package:deep_link_book/features/history/data/history_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an Open action for a deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);

    expect(find.widgetWithText(OutlinedButton, 'Open'), findsOneWidget);
  });

  testWidgets('shows a search field when deeplinks exist', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
      ],
    );

    expect(find.widgetWithText(TextField, 'Search deeplinks'), findsOneWidget);
  });

  testWidgets('empty search shows all deeplinks', (WidgetTester tester) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('searches deeplinks by name case-insensitively', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    await _enterSearch(tester, 'TRANSFER');

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('search ignores leading and trailing whitespace', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    await _enterSearch(tester, '   transfer   ');

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);
  });

  testWidgets('searches deeplinks by URL', (WidgetTester tester) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    await _enterSearch(tester, 'profile');

    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Transfer Out'), findsNothing);
  });

  testWidgets(
    'searches deeplinks by description and handles null description',
    (WidgetTester tester) async {
      await _pumpHome(
        tester,
        deeplinks: [
          _testDeeplink(
            id: 1,
            name: 'Payment',
            url: 'ascendbank-qa://payment',
            description: 'Open confirmation screen',
          ),
          _testDeeplink(
            id: 2,
            name: 'Transfer Out',
            url: 'ascendbank-qa://transfer_out',
          ),
        ],
      );

      await _enterSearch(tester, 'confirmation');

      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Transfer Out'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shows a separate empty state for no search matches', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
      ],
    );

    await _enterSearch(tester, 'something-that-does-not-exist');

    expect(find.text('No matching deeplinks'), findsOneWidget);
    expect(find.text('Try a different search term.'), findsOneWidget);
    expect(find.text('No deeplinks yet'), findsNothing);
  });

  testWidgets('empty database still shows the normal empty state', (
    WidgetTester tester,
  ) async {
    await _pumpHome(tester, deeplinks: const []);

    expect(find.text('No deeplinks yet'), findsOneWidget);
    expect(find.text('No matching deeplinks'), findsNothing);
  });

  testWidgets('clearing search restores all deeplinks', (
    WidgetTester tester,
  ) async {
    await _pumpHome(
      tester,
      deeplinks: [
        _testDeeplink(
          id: 1,
          name: 'Transfer Out',
          url: 'ascendbank-qa://transfer_out',
        ),
        _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
      ],
    );

    await _enterSearch(tester, 'transfer');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('search is reapplied when the deeplink stream updates', (
    WidgetTester tester,
  ) async {
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(tester, deeplinksStream: deeplinksStream.stream);
    deeplinksStream.add([
      _testDeeplink(
        id: 1,
        name: 'Transfer QA',
        url: 'ascendbank-qa://transfer_qa',
      ),
      _testDeeplink(id: 2, name: 'Profile', url: 'ascendbank-qa://profile'),
    ]);
    await tester.pumpAndSettle();

    await _enterSearch(tester, 'transfer');

    deeplinksStream.add([
      _testDeeplink(
        id: 3,
        name: 'Transfer UAT',
        url: 'ascendbank-qa://transfer_uat',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('Transfer QA'), findsNothing);
    expect(find.text('Profile'), findsNothing);
    expect(find.text('Transfer UAT'), findsOneWidget);
  });

  testWidgets('copy action exists and copies the Home deeplink URL', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher();

    final clipboardWrites = _captureClipboardWrites();
    await _pumpHome(tester, launcher: launcher, deeplinks: [deeplink]);

    await _openActionsMenu(tester, 'Transfer Out');

    expect(find.text('Copy'), findsOneWidget);

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();

    expect(clipboardWrites, ['ascendbank-qa://transfer_out']);
    expect(find.text('Deeplink copied.'), findsOneWidget);
    expect(find.text('Edit Deeplink'), findsNothing);
    expect(find.text('Delete deeplink?'), findsNothing);
    expect(find.text('Transfer Out'), findsOneWidget);
    expect(launcher.openedUris, isEmpty);
  });

  testWidgets('valid deeplink reaches the launcher', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher();

    await _pumpHome(tester, launcher: launcher, deeplinks: [deeplink]);
    await _tapOpen(tester, 'Transfer Out');

    expect(launcher.openedUris, [Uri.parse('ascendbank-qa://transfer_out')]);
  });

  testWidgets('invalid deeplink does not launch or update usage', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await _insertDeeplink(
      context.database,
      name: 'Broken',
      url: 'transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final launcher = TestDeeplinkLauncher();

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      launcher: launcher,
      deeplinks: [deeplink!],
    );
    await _tapOpen(tester, 'Broken');

    final unchanged = await context.repository.getDeeplinkById(id);
    final history = await context.historyRepository.getAllHistory();

    expect(launcher.openedUris, isEmpty);
    expect(find.text('Enter a valid deeplink URL.'), findsOneWidget);
    expect(unchanged?.openCount, 0);
    expect(unchanged?.lastOpenedAt, isNull);
    expect(history, hasLength(1));
    expect(history.single.deeplinkId, id);
    expect(history.single.name, 'Broken');
    expect(history.single.url, 'transfer_out');
    expect(history.single.isSuccess, isFalse);
    expect(history.single.errorMessage, 'Invalid deeplink URL.');
  });

  testWidgets('successful open updates usage metadata', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final initial = await context.repository.getDeeplinkById(id);
    final launcher = TestDeeplinkLauncher();
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      launcher: launcher,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([initial!]);
    await tester.pumpAndSettle();

    await _tapOpen(tester, 'Transfer Out');

    final updated = await context.repository.getDeeplinkById(id);
    final history = await context.historyRepository.getAllHistory();
    expect(updated?.openCount, 1);
    expect(updated?.lastOpenedAt, isNotNull);
    expect(history, hasLength(1));
    expect(history.single.deeplinkId, id);
    expect(history.single.name, 'Transfer Out');
    expect(history.single.url, 'ascendbank-qa://transfer_out');
    expect(history.single.isSuccess, isTrue);
    expect(history.single.errorMessage, isNull);

    deeplinksStream.add([updated!]);
    await tester.pumpAndSettle();

    expect(find.text('Opened 1 time'), findsOneWidget);
  });

  testWidgets('repeated successful opens increment usage count', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final launcher = TestDeeplinkLauncher();

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      launcher: launcher,
      deeplinks: [deeplink!],
    );

    await _tapOpen(tester, 'Transfer Out');
    await _tapOpen(tester, 'Transfer Out');

    final updated = await context.repository.getDeeplinkById(id);
    final history = await context.historyRepository.getAllHistory();

    expect(updated?.openCount, 2);
    expect(history, hasLength(2));
    expect(history.every((item) => item.isSuccess), isTrue);
  });

  testWidgets('failed launch does not update usage', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final lastOpenedAt = DateTime(2026, 8, 15, 11);
    final id = await _insertDeeplink(
      context.database,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      openCount: 3,
      lastOpenedAt: lastOpenedAt,
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final launcher = TestDeeplinkLauncher(result: false);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      launcher: launcher,
      deeplinks: [deeplink!],
    );
    await _tapOpen(tester, 'Transfer Out');

    final unchanged = await context.repository.getDeeplinkById(id);
    final history = await context.historyRepository.getAllHistory();

    expect(find.text('No app can open this deeplink.'), findsOneWidget);
    expect(unchanged?.openCount, 3);
    expect(unchanged?.lastOpenedAt, lastOpenedAt);
    expect(history, hasLength(1));
    expect(history.single.deeplinkId, id);
    expect(history.single.isSuccess, isFalse);
    expect(history.single.errorMessage, 'No app can open this deeplink.');
  });

  testWidgets('launcher exception shows an error and does not record usage', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = ThrowingDeeplinkLauncher();
    final repository = RecordingRepository(deeplink);
    final historyRepository = RecordingHistoryRepository();
    addTearDown(repository.close);
    addTearDown(historyRepository.close);

    await _pumpHome(
      tester,
      repository: repository,
      historyRepository: historyRepository,
      launcher: launcher,
      deeplinks: [deeplink],
    );
    await _tapOpen(tester, 'Transfer Out');

    expect(find.text('Unable to open deeplink.'), findsOneWidget);
    expect(repository.recordCallCount, 0);
    expect(historyRepository.createCallCount, 1);
    expect(historyRepository.created.single.isSuccess, isFalse);
    expect(
      historyRepository.created.single.errorMessage,
      'Unable to open deeplink.',
    );
    expect(
      historyRepository.created.single.errorMessage,
      isNot(contains('Launch failed')),
    );
    expect(find.byTooltip('Open Transfer Out'), findsOneWidget);
  });

  testWidgets('usage failure after successful launch is partial success', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher();
    final repository = RecordingRepository(deeplink, recordResult: false);
    final historyRepository = RecordingHistoryRepository();
    addTearDown(repository.close);
    addTearDown(historyRepository.close);

    await _pumpHome(
      tester,
      repository: repository,
      historyRepository: historyRepository,
      launcher: launcher,
      deeplinks: [deeplink],
    );
    await _tapOpen(tester, 'Transfer Out');

    expect(launcher.openedUris, hasLength(1));
    expect(repository.recordCallCount, 1);
    expect(historyRepository.createCallCount, 1);
    expect(historyRepository.created.single.isSuccess, isTrue);
    expect(find.text('Unable to open deeplink.'), findsNothing);
    expect(
      find.text('Deeplink opened, but its usage could not be updated.'),
      findsOneWidget,
    );
  });

  testWidgets('usage exception after successful launch is partial success', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher();
    final repository = RecordingRepository(deeplink, throwsOnRecord: true);
    final historyRepository = RecordingHistoryRepository();
    addTearDown(repository.close);
    addTearDown(historyRepository.close);

    await _pumpHome(
      tester,
      repository: repository,
      historyRepository: historyRepository,
      launcher: launcher,
      deeplinks: [deeplink],
    );
    await _tapOpen(tester, 'Transfer Out');

    expect(launcher.openedUris, hasLength(1));
    expect(repository.recordCallCount, 1);
    expect(historyRepository.createCallCount, 1);
    expect(historyRepository.created.single.isSuccess, isTrue);
    expect(find.text('Unable to open deeplink.'), findsNothing);
    expect(
      find.text('Deeplink opened, but usage could not be saved.'),
      findsOneWidget,
    );
  });

  testWidgets('prevents repeated Open taps while launching', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = ControlledDeeplinkLauncher();

    await _pumpHome(tester, launcher: launcher, deeplinks: [deeplink]);
    await _tapOpen(tester, 'Transfer Out');
    await tester.pump();

    final openButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Open'),
    );

    expect(launcher.openedUris, hasLength(1));
    expect(openButton.onPressed, isNull);

    launcher.complete(result: false);
    await tester.pump();
    await tester.pump();

    expect(launcher.openedUris, hasLength(1));
    expect(find.byTooltip('Open Transfer Out'), findsOneWidget);
  });

  testWidgets('opening one row does not disable other rows', (
    WidgetTester tester,
  ) async {
    final first = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final second = _testDeeplink(
      id: 2,
      name: 'Profile',
      url: 'ascendbank-qa://profile',
    );
    final launcher = ControlledDeeplinkLauncher();

    await _pumpHome(tester, launcher: launcher, deeplinks: [first, second]);
    await _tapOpen(tester, 'Transfer Out');
    await tester.pump();

    expect(find.byTooltip('Open Profile'), findsOneWidget);
  });

  testWidgets('Open tap does not open Edit Deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher(result: false);

    await _pumpHome(tester, launcher: launcher, deeplinks: [deeplink]);
    await _tapOpen(tester, 'Transfer Out');

    expect(find.text('Edit Deeplink'), findsNothing);
  });

  testWidgets('history keeps the opened snapshot after the source changes', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer QA',
      url: 'deeplinktest://transfer?env=qa',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final launcher = TestDeeplinkLauncher();

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      launcher: launcher,
      deeplinks: [deeplink!],
    );
    await _tapOpen(tester, 'Transfer QA');
    await context.repository.updateDeeplink(
      id: id,
      name: 'Transfer UAT',
      url: 'deeplinktest://transfer?env=uat',
    );

    final history = await context.historyRepository.getAllHistory();

    expect(history, hasLength(1));
    expect(history.single.name, 'Transfer QA');
    expect(history.single.url, 'deeplinktest://transfer?env=qa');
  });

  testWidgets(
    'successful launch still updates usage when history insert fails',
    (WidgetTester tester) async {
      final deeplink = _testDeeplink(
        id: 1,
        name: 'Transfer Out',
        url: 'ascendbank-qa://transfer_out',
      );
      final launcher = TestDeeplinkLauncher();
      final repository = RecordingRepository(deeplink);
      final historyRepository = FailingHistoryRepository();
      addTearDown(repository.close);
      addTearDown(historyRepository.close);

      await _pumpHome(
        tester,
        repository: repository,
        historyRepository: historyRepository,
        launcher: launcher,
        deeplinks: [deeplink],
      );
      await _tapOpen(tester, 'Transfer Out');

      expect(launcher.openedUris, hasLength(1));
      expect(repository.recordCallCount, 1);
      expect(historyRepository.createCallCount, 1);
      expect(find.text('Unable to open deeplink.'), findsNothing);
      expect(
        find.text('Deeplink opened, but history could not be saved.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('failed launch still shows failure when history insert fails', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final launcher = TestDeeplinkLauncher(result: false);
    final historyRepository = FailingHistoryRepository();
    addTearDown(historyRepository.close);

    await _pumpHome(
      tester,
      historyRepository: historyRepository,
      launcher: launcher,
      deeplinks: [deeplink],
    );
    await _tapOpen(tester, 'Transfer Out');

    expect(launcher.openedUris, hasLength(1));
    expect(historyRepository.createCallCount, 1);
    expect(find.text('No app can open this deeplink.'), findsOneWidget);
  });

  testWidgets('shows outlined icon for a non-favorite deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);

    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('shows filled icon for a favorite deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      isFavorite: true,
    );

    await _pumpHome(tester, deeplinks: [deeplink]);

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNothing);
  });

  testWidgets('toggles favorite from false to true', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final initial = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([initial!]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);
    expect(updated?.isFavorite, isTrue);

    deeplinksStream.add([updated!]);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('toggles favorite from true to false', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await _insertDeeplink(
      context.database,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      isFavorite: true,
    );
    final initial = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([initial!]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Remove Transfer Out from favorites'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);
    expect(updated?.isFavorite, isFalse);

    deeplinksStream.add([updated!]);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });

  testWidgets('favorite toggle preserves usage metadata', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final createdAt = DateTime(2026, 8, 15, 10);
    final updatedAt = DateTime(2026, 8, 15, 10);
    final lastOpenedAt = DateTime(2026, 8, 15, 11);
    final id = await _insertDeeplink(
      context.database,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      openCount: 4,
      lastOpenedAt: lastOpenedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
    final initial = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [initial!],
    );
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pumpAndSettle();

    final updated = await context.repository.getDeeplinkById(id);

    expect(updated?.isFavorite, isTrue);
    expect(updated?.openCount, 4);
    expect(updated?.lastOpenedAt, lastOpenedAt);
    expect(updated?.createdAt, createdAt);
    expect(updated!.updatedAt.isAfter(updatedAt), isTrue);
  });

  testWidgets('shows a message when toggling a missing deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingFavoriteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pumpAndSettle();

    expect(find.text('This deeplink no longer exists.'), findsOneWidget);
    expect(find.byTooltip('Add Transfer Out to favorites'), findsOneWidget);
  });

  testWidgets('shows an error when favorite update fails', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = FailingFavoriteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to update favorite.'), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byTooltip('Add Transfer Out to favorites'), findsOneWidget);
  });

  testWidgets('prevents repeated favorite taps while processing', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = ControlledFavoriteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pump();

    expect(repository.favoriteCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Add Transfer Out to favorites'), findsNothing);

    repository.completeFavorite(updated: false);
    await tester.pumpAndSettle();

    expect(repository.favoriteCallCount, 1);
    expect(find.byTooltip('Add Transfer Out to favorites'), findsOneWidget);
  });

  testWidgets('favorite actions on different rows stay independent', (
    WidgetTester tester,
  ) async {
    final first = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final second = _testDeeplink(
      id: 2,
      name: 'Profile',
      url: 'ascendbank-qa://profile',
    );
    final repository = ControlledFavoriteRepository(first);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [first, second]);
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pump();

    expect(find.byTooltip('Add Transfer Out to favorites'), findsNothing);
    expect(find.byTooltip('Add Profile to favorites'), findsOneWidget);
  });

  testWidgets('favorite tap does not open Edit Deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingFavoriteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.byTooltip('Add Transfer Out to favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Deeplink'), findsNothing);
  });

  testWidgets('shows item menu actions', (WidgetTester tester) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('duplicates a deeplink through the repository', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final original = saved.singleWhere((deeplink) => deeplink.id == id);
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(saved, hasLength(2));
    expect(copy.id, isNot(original.id));
    expect(copy.name, 'Transfer Out (Copy)');
    expect(copy.url, original.url);
    expect(copy.description, 'Open transfer flow');
  });

  testWidgets('duplicate resets metadata and keeps the original unchanged', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final createdAt = DateTime(2026, 8, 15, 10);
    final lastOpenedAt = DateTime(2026, 8, 15, 11);
    final id = await context.database
        .into(context.database.deeplinks)
        .insert(
          DeeplinksCompanion.insert(
            name: 'Transfer Out',
            url: 'ascendbank-qa://transfer_out',
            description: const Value('Open transfer flow'),
            isFavorite: const Value(true),
            openCount: const Value(5),
            lastOpenedAt: Value(lastOpenedAt),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final original = saved.singleWhere((deeplink) => deeplink.id == id);
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(original.isFavorite, isTrue);
    expect(original.openCount, 5);
    expect(original.lastOpenedAt, lastOpenedAt);
    expect(original.createdAt, createdAt);
    expect(copy.isFavorite, isFalse);
    expect(copy.openCount, 0);
    expect(copy.lastOpenedAt, isNull);
    expect(copy.createdAt, isNot(createdAt));
    expect(copy.updatedAt, isNot(createdAt));
  });

  testWidgets('duplicate preserves a null description', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Profile',
      url: 'ascendbank-qa://profile',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openActionsMenu(tester, 'Profile');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final saved = await context.repository.getAllDeeplinks();
    final copy = saved.singleWhere((deeplink) => deeplink.id != id);

    expect(copy.description, isNull);
  });

  testWidgets('Home shows the duplicated item from the stream', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
      description: 'Open transfer flow',
    );
    final original = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([original!]);
    await tester.pumpAndSettle();

    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    final updatedList = await context.repository.getAllDeeplinks();
    deeplinksStream.add(updatedList);
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.text('Transfer Out (Copy)'), findsOneWidget);
  });

  testWidgets('shows a message when duplicating a missing source', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('This deeplink no longer exists.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
  });

  testWidgets('shows an error when duplicate fails and re-enables the action', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = FailingDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to duplicate deeplink.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('prevents repeated duplicate requests while processing', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = ControlledDuplicateRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openActionsMenu(tester, 'Transfer Out');
    await tester.tap(find.text('Duplicate'));
    await tester.pump();

    expect(repository.duplicateCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsNothing);

    repository.completeDuplicate(duplicatedId: null);
    await tester.pumpAndSettle();

    expect(repository.duplicateCallCount, 1);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('shows a confirmation dialog before deleting', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );

    await _pumpHome(tester, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');

    expect(find.text('Delete deeplink?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Delete'), findsOneWidget);
  });

  testWidgets('cancel keeps the deeplink visible and in the database', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinks: [deeplink!],
    );
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsOneWidget);
    expect(await context.repository.getDeeplinkById(id), isNotNull);
  });

  testWidgets('confirm deletes from the repository and Home updates', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([deeplink!]);
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(await context.repository.getDeeplinkById(id), isNull);

    deeplinksStream.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('Transfer Out'), findsNothing);
  });

  testWidgets('deleting the last item shows the empty state', (
    WidgetTester tester,
  ) async {
    final context = _createDatabaseContext();
    final id = await context.repository.createDeeplink(
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final deeplink = await context.repository.getDeeplinkById(id);
    final deeplinksStream = StreamController<List<Deeplink>>();
    addTearDown(deeplinksStream.close);

    await _pumpHome(
      tester,
      database: context.database,
      repository: context.repository,
      deeplinksStream: deeplinksStream.stream,
    );
    deeplinksStream.add([deeplink!]);
    await tester.pumpAndSettle();

    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    deeplinksStream.add(const []);
    await tester.pumpAndSettle();

    expect(find.text('No deeplinks yet'), findsOneWidget);
  });

  testWidgets('shows a message when the deeplink is already missing', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('This deeplink no longer exists.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
  });

  testWidgets('shows an error when delete fails and re-enables the action', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = FailingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Unable to delete deeplink.'), findsOneWidget);
    expect(find.text('Transfer Out'), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('prevents duplicate delete requests while deleting', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = ControlledDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await _openDeleteDialog(tester, 'Transfer Out');
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pump();

    expect(repository.deleteCallCount, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byTooltip('Actions for Transfer Out'), findsNothing);

    repository.completeDelete(deleted: false);
    await tester.pumpAndSettle();

    expect(repository.deleteCallCount, 1);
    expect(find.byTooltip('Actions for Transfer Out'), findsOneWidget);
  });

  testWidgets('tapping the row still opens Edit Deeplink', (
    WidgetTester tester,
  ) async {
    final deeplink = _testDeeplink(
      id: 1,
      name: 'Transfer Out',
      url: 'ascendbank-qa://transfer_out',
    );
    final repository = MissingDeleteRepository(deeplink);
    addTearDown(repository.close);

    await _pumpHome(tester, repository: repository, deeplinks: [deeplink]);
    await tester.tap(find.text('Transfer Out'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Deeplink'), findsOneWidget);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  AppDatabase? database,
  DeeplinkRepository? repository,
  HistoryRepository? historyRepository,
  DeeplinkLauncher? launcher,
  List<Deeplink>? deeplinks,
  Stream<List<Deeplink>>? deeplinksStream,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (database != null) appDatabaseProvider.overrideWithValue(database),
        if (repository != null)
          deeplinkRepositoryProvider.overrideWithValue(repository),
        if (historyRepository != null)
          historyRepositoryProvider.overrideWithValue(historyRepository),
        if (launcher != null)
          deeplinkLauncherProvider.overrideWithValue(launcher),
        if (deeplinks != null)
          deeplinksProvider.overrideWithValue(AsyncValue.data(deeplinks)),
        if (deeplinksStream != null)
          deeplinksProvider.overrideWith((ref) => deeplinksStream),
      ],
      child: App(router: createAppRouter()),
    ),
  );
}

Future<void> _tapOpen(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Open $name'));
  await tester.pump();
  await tester.pump();
}

Future<void> _enterSearch(WidgetTester tester, String query) async {
  await tester.enterText(
    find.widgetWithText(TextField, 'Search deeplinks'),
    query,
  );
  await tester.pumpAndSettle();
}

List<String?> _captureClipboardWrites() {
  final clipboardWrites = <String?>[];

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          final arguments = call.arguments as Map<Object?, Object?>;
          clipboardWrites.add(arguments['text'] as String?);
        }

        return null;
      });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  return clipboardWrites;
}

Future<void> _openActionsMenu(WidgetTester tester, String name) async {
  await tester.tap(find.byTooltip('Actions for $name'));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(WidgetTester tester, String name) async {
  await _openActionsMenu(tester, name);
  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();
}

_DatabaseTestContext _createDatabaseContext() {
  final database = AppDatabase(NativeDatabase.memory());
  final repository = DeeplinkRepository(database);
  final historyRepository = HistoryRepository(database);
  addTearDown(database.close);

  return _DatabaseTestContext(
    database: database,
    repository: repository,
    historyRepository: historyRepository,
  );
}

Deeplink _testDeeplink({
  required int id,
  required String name,
  required String url,
  String? description,
  bool isFavorite = false,
}) {
  final now = DateTime(2026, 8, 15, 10);

  return Deeplink(
    id: id,
    name: name,
    url: url,
    description: description,
    isFavorite: isFavorite,
    openCount: 0,
    createdAt: now,
    updatedAt: now,
  );
}

Future<int> _insertDeeplink(
  AppDatabase database, {
  required String name,
  required String url,
  String? description,
  bool isFavorite = false,
  int openCount = 0,
  DateTime? lastOpenedAt,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  final now = DateTime(2026, 8, 15, 10);

  return database
      .into(database.deeplinks)
      .insert(
        DeeplinksCompanion.insert(
          name: name,
          url: url,
          description: Value(description),
          isFavorite: Value(isFavorite),
          openCount: Value(openCount),
          lastOpenedAt: Value(lastOpenedAt),
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
        ),
      );
}

class _DatabaseTestContext {
  const _DatabaseTestContext({
    required this.database,
    required this.repository,
    required this.historyRepository,
  });

  final AppDatabase database;
  final DeeplinkRepository repository;
  final HistoryRepository historyRepository;
}

class MissingDeleteRepository extends DeeplinkRepository {
  MissingDeleteRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  MissingDeleteRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var deleteCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<bool> deleteDeeplink(int id) async {
    deleteCallCount++;
    return false;
  }

  Future<void> close() => _database.close();
}

class FailingDeleteRepository extends MissingDeleteRepository {
  FailingDeleteRepository(super.deeplink);

  @override
  Future<bool> deleteDeeplink(int id) {
    deleteCallCount++;
    throw Exception('Delete failed');
  }
}

class ControlledDeleteRepository extends MissingDeleteRepository {
  ControlledDeleteRepository(super.deeplink);

  final _deleteCompleter = Completer<bool>();

  @override
  Future<bool> deleteDeeplink(int id) {
    deleteCallCount++;
    return _deleteCompleter.future;
  }

  void completeDelete({required bool deleted}) {
    if (!_deleteCompleter.isCompleted) {
      _deleteCompleter.complete(deleted);
    }
  }
}

class MissingDuplicateRepository extends DeeplinkRepository {
  MissingDuplicateRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  MissingDuplicateRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var duplicateCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<int?> duplicateDeeplink(int id) async {
    duplicateCallCount++;
    return null;
  }

  Future<void> close() => _database.close();
}

class FailingDuplicateRepository extends MissingDuplicateRepository {
  FailingDuplicateRepository(super.deeplink);

  @override
  Future<int?> duplicateDeeplink(int id) {
    duplicateCallCount++;
    throw Exception('Duplicate failed');
  }
}

class ControlledDuplicateRepository extends MissingDuplicateRepository {
  ControlledDuplicateRepository(super.deeplink);

  final _duplicateCompleter = Completer<int?>();

  @override
  Future<int?> duplicateDeeplink(int id) {
    duplicateCallCount++;
    return _duplicateCompleter.future;
  }

  void completeDuplicate({required int? duplicatedId}) {
    if (!_duplicateCompleter.isCompleted) {
      _duplicateCompleter.complete(duplicatedId);
    }
  }
}

class MissingFavoriteRepository extends DeeplinkRepository {
  MissingFavoriteRepository(Deeplink deeplink)
    : this._(deeplink, AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  MissingFavoriteRepository._(this.deeplink, AppDatabase database)
    : _database = database,
      super(database);

  final Deeplink deeplink;
  final AppDatabase _database;
  var favoriteCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<bool> toggleFavorite(int id) async {
    favoriteCallCount++;
    return false;
  }

  Future<void> close() => _database.close();
}

class FailingFavoriteRepository extends MissingFavoriteRepository {
  FailingFavoriteRepository(super.deeplink);

  @override
  Future<bool> toggleFavorite(int id) {
    favoriteCallCount++;
    throw Exception('Favorite failed');
  }
}

class ControlledFavoriteRepository extends MissingFavoriteRepository {
  ControlledFavoriteRepository(super.deeplink);

  final _favoriteCompleter = Completer<bool>();

  @override
  Future<bool> toggleFavorite(int id) {
    favoriteCallCount++;
    return _favoriteCompleter.future;
  }

  void completeFavorite({required bool updated}) {
    if (!_favoriteCompleter.isCompleted) {
      _favoriteCompleter.complete(updated);
    }
  }
}

class TestDeeplinkLauncher extends DeeplinkLauncher {
  TestDeeplinkLauncher({this.result = true});

  final bool result;
  final openedUris = <Uri>[];

  @override
  Future<bool> open(Uri uri) async {
    openedUris.add(uri);
    return result;
  }
}

class ThrowingDeeplinkLauncher extends DeeplinkLauncher {
  final openedUris = <Uri>[];

  @override
  Future<bool> open(Uri uri) {
    openedUris.add(uri);
    throw Exception('Launch failed');
  }
}

class ControlledDeeplinkLauncher extends DeeplinkLauncher {
  final openedUris = <Uri>[];
  final _openCompleter = Completer<bool>();

  @override
  Future<bool> open(Uri uri) {
    openedUris.add(uri);
    return _openCompleter.future;
  }

  void complete({required bool result}) {
    if (!_openCompleter.isCompleted) {
      _openCompleter.complete(result);
    }
  }
}

class RecordingRepository extends DeeplinkRepository {
  RecordingRepository(
    Deeplink deeplink, {
    bool recordResult = true,
    bool throwsOnRecord = false,
  }) : this._(
         deeplink,
         AppDatabase(NativeDatabase.memory()),
         recordResult: recordResult,
         throwsOnRecord: throwsOnRecord,
       );

  // ignore: use_super_parameters
  RecordingRepository._(
    this.deeplink,
    AppDatabase database, {
    this.recordResult = true,
    this.throwsOnRecord = false,
  }) : _database = database,
       super(database);

  final Deeplink deeplink;
  final bool recordResult;
  final bool throwsOnRecord;
  final AppDatabase _database;
  var recordCallCount = 0;

  @override
  Future<Deeplink?> getDeeplinkById(int id) async {
    return id == deeplink.id ? deeplink : null;
  }

  @override
  Future<bool> recordDeeplinkOpened(int id) {
    recordCallCount++;

    if (throwsOnRecord) {
      throw Exception('Record failed');
    }

    return Future.value(recordResult);
  }

  Future<void> close() => _database.close();
}

class RecordingHistoryRepository extends HistoryRepository {
  RecordingHistoryRepository() : this._(AppDatabase(NativeDatabase.memory()));

  // ignore: use_super_parameters
  RecordingHistoryRepository._(AppDatabase database)
    : _database = database,
      super(database);

  final AppDatabase _database;
  final created = <_RecordedHistory>[];
  var createCallCount = 0;

  @override
  Future<int> createHistory({
    int? deeplinkId,
    required String name,
    required String url,
    required bool isSuccess,
    String? errorMessage,
  }) async {
    createCallCount++;
    created.add(
      _RecordedHistory(
        deeplinkId: deeplinkId,
        name: name,
        url: url,
        isSuccess: isSuccess,
        errorMessage: errorMessage,
      ),
    );
    return createCallCount;
  }

  Future<void> close() => _database.close();
}

class FailingHistoryRepository extends RecordingHistoryRepository {
  @override
  Future<int> createHistory({
    int? deeplinkId,
    required String name,
    required String url,
    required bool isSuccess,
    String? errorMessage,
  }) {
    createCallCount++;
    throw Exception('History insert failed');
  }
}

class _RecordedHistory {
  const _RecordedHistory({
    required this.deeplinkId,
    required this.name,
    required this.url,
    required this.isSuccess,
    required this.errorMessage,
  });

  final int? deeplinkId;
  final String name;
  final String url;
  final bool isSuccess;
  final String? errorMessage;
}
