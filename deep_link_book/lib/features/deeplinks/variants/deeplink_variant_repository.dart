import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

class DeeplinkVariantRepository {
  DeeplinkVariantRepository(this._database);

  final AppDatabase _database;

  Stream<List<DeeplinkVariant>> watchVariantsForDeeplink(int deeplinkId) {
    final query = _database.select(_database.deeplinkVariants)
      ..where((variant) => variant.deeplinkId.equals(deeplinkId))
      ..orderBy([
        (variant) => OrderingTerm(
          expression: variant.updatedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch();
  }

  Future<DeeplinkVariant?> getVariantById(int id) {
    return (_database.select(
      _database.deeplinkVariants,
    )..where((variant) => variant.id.equals(id))).getSingleOrNull();
  }

  Future<int> createVariant({
    required int deeplinkId,
    required String name,
    String overridesJson = '{}',
  }) {
    final now = DateTime.now();

    return _database
        .into(_database.deeplinkVariants)
        .insert(
          DeeplinkVariantsCompanion.insert(
            deeplinkId: deeplinkId,
            name: name,
            overridesJson: Value(overridesJson),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<bool> updateVariant({
    required int id,
    required String name,
    required String overridesJson,
  }) async {
    final updatedRows =
        await (_database.update(
          _database.deeplinkVariants,
        )..where((variant) => variant.id.equals(id))).write(
          DeeplinkVariantsCompanion(
            name: Value(name),
            overridesJson: Value(overridesJson),
            updatedAt: Value(DateTime.now()),
          ),
        );

    return updatedRows > 0;
  }

  Future<bool> deleteVariant(int id) async {
    final deletedRows = await (_database.delete(
      _database.deeplinkVariants,
    )..where((variant) => variant.id.equals(id))).go();

    return deletedRows > 0;
  }
}

final deeplinkVariantRepositoryProvider = Provider<DeeplinkVariantRepository>((
  ref,
) {
  return DeeplinkVariantRepository(ref.watch(appDatabaseProvider));
});

final deeplinkVariantsProvider =
    StreamProvider.family<List<DeeplinkVariant>, int>((ref, deeplinkId) {
      return ref
          .watch(deeplinkVariantRepositoryProvider)
          .watchVariantsForDeeplink(deeplinkId);
    });
