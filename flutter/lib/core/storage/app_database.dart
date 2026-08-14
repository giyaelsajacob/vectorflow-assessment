// import 'dart:io';
//
// import 'package:drift/drift.dart';
// import 'package:drift/native.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:path/path.dart' as p;
// import 'package:path_provider/path_provider.dart';
//
// part 'app_database.g.dart';
//
// class OfflineOperations extends Table {
//   TextColumn get id => text()();
//   TextColumn get entityId => text()();
//   TextColumn get operation => text()();
//   TextColumn get payload => text()();
//   TextColumn get status => text().withDefault(const Constant('pending'))();
//   IntColumn get retryCount => integer().withDefault(const Constant(0))();
//   DateTimeColumn get createdAt => dateTime()();
//   DateTimeColumn get lastAttemptAt => dateTime().nullable()();
//
//   @override
//   Set<Column> get primaryKey => {id};
// }
//
// @DriftDatabase(tables: [OfflineOperations])
// class AppDatabase extends _$AppDatabase {
//   AppDatabase() : super(_openConnection());
//
//   @override
//   int get schemaVersion => 1;
//
//   Future<List<OfflineOperation>> pendingOperations() {
//     return (select(offlineOperations)
//           ..where((t) => t.status.equals('pending'))
//           ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
//         .get();
//   }
//
//   Future<void> enqueue(OfflineOperationsCompanion item) {
//     return into(offlineOperations).insertOnConflictUpdate(item);
//   }
//
//   Future<void> markSynced(String id) {
//     return (update(offlineOperations)..where((t) => t.id.equals(id))).write(
//       const OfflineOperationsCompanion(status: Value('synced')),
//     );
//   }
//
//   Future<void> markFailed(String id, int retryCount) {
//     return (update(offlineOperations)..where((t) => t.id.equals(id))).write(
//       OfflineOperationsCompanion(
//         retryCount: Value(retryCount),
//         lastAttemptAt: Value(DateTime.now()),
//       ),
//     );
//   }
// }
//
// LazyDatabase _openConnection() {
//   return LazyDatabase(() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final file = File(p.join(directory.path, 'vectorflow.sqlite'));
//     return NativeDatabase.createInBackground(file);
//   });
// }
//
// final databaseProvider = Provider<AppDatabase>((ref) {
//   final database = AppDatabase();
//   ref.onDispose(database.close);
//   return database;
// });


import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class OfflineOperations extends Table {
  TextColumn get id => text()();

  /// Local package ID initially.
  /// After CREATE_PACKAGE synchronizes, attachment operations
  /// are updated to the real server package ID.
  TextColumn get entityId => text()();

  /// Examples:
  /// CREATE_PACKAGE
  /// UPLOAD_ATTACHMENT
  TextColumn get operation => text()();

  /// JSON payload containing the data required to replay
  /// the operation later.
  TextColumn get payload => text()();

  /// pending / syncing / failed / synced
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();

  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get lastAttemptAt =>
      dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    OfflineOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ------------------------------------------------------------
  // READ PENDING OPERATIONS
  // ------------------------------------------------------------

  Future<List<OfflineOperation>> pendingOperations() {
    return (
        select(offlineOperations)
          ..where(
                (table) =>
            table.status.equals('pending') |
            table.status.equals('failed'),
          )
          ..orderBy([
                (table) => OrderingTerm.asc(
              table.createdAt,
            ),
          ])
    ).get();
  }

  // ------------------------------------------------------------
  // INSERT / UPDATE OPERATION
  // ------------------------------------------------------------

  Future<void> enqueue(
      OfflineOperationsCompanion item,
      ) {
    return into(
      offlineOperations,
    ).insertOnConflictUpdate(item);
  }

  // ------------------------------------------------------------
  // MARK SYNCING
  // ------------------------------------------------------------

  Future<void> markSyncing(
      String id,
      ) {
    return (
        update(offlineOperations)
          ..where(
                (table) =>
                table.id.equals(id),
          )
    ).write(
      OfflineOperationsCompanion(
        status: const Value(
          'syncing',
        ),
        lastAttemptAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MARK SYNCED
  // ------------------------------------------------------------

  Future<void> markSynced(
      String id,
      ) {
    return (
        update(offlineOperations)
          ..where(
                (table) =>
                table.id.equals(id),
          )
    ).write(
      OfflineOperationsCompanion(
        status: const Value(
          'synced',
        ),
        lastAttemptAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // MARK FAILED
  // ------------------------------------------------------------

  Future<void> markFailed(
      String id,
      int retryCount,
      ) {
    return (
        update(offlineOperations)
          ..where(
                (table) =>
                table.id.equals(id),
          )
    ).write(
      OfflineOperationsCompanion(
        status: const Value(
          'failed',
        ),
        retryCount: Value(
          retryCount,
        ),
        lastAttemptAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RESET FAILED OPERATION
  // ------------------------------------------------------------

  Future<void> resetToPending(
      String id,
      ) {
    return (
        update(offlineOperations)
          ..where(
                (table) =>
                table.id.equals(id),
          )
    ).write(
      const OfflineOperationsCompanion(
        status: Value(
          'pending',
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // ATTACHMENT PACKAGE-ID MAPPING
  // ------------------------------------------------------------
  //
  // Example:
  //
  // Offline:
  //
  // local package id:
  // 12bd...
  //
  // CREATE_PACKAGE
  // entityId = 12bd...
  //
  // UPLOAD_ATTACHMENT
  // entityId = 12bd...
  //
  //
  // After CREATE_PACKAGE reaches backend:
  //
  // backend returns:
  //
  // server package id:
  // 85aa...
  //
  // We update every pending attachment operation:
  //
  // 12bd... → 85aa...
  //
  // so attachments can upload against the real API package.
  // ------------------------------------------------------------

  Future<void> replacePendingEntityId({
    required String oldEntityId,
    required String newEntityId,
  }) {
    return (
        update(offlineOperations)
          ..where(
                (table) =>
            table.entityId.equals(
              oldEntityId,
            ) &
            table.status.isNotValue(
              'synced',
            ),
          )
    ).write(
      OfflineOperationsCompanion(
        entityId: Value(
          newEntityId,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FIND OPERATIONS FOR PACKAGE
  // ------------------------------------------------------------

  Future<List<OfflineOperation>>
  operationsForEntity(
      String entityId,
      ) {
    return (
        select(offlineOperations)
          ..where(
                (table) =>
                table.entityId.equals(
                  entityId,
                ),
          )
          ..orderBy([
                (table) =>
                OrderingTerm.asc(
                  table.createdAt,
                ),
          ])
    ).get();
  }

  // ------------------------------------------------------------
  // DELETE COMPLETED OPERATIONS
  // ------------------------------------------------------------

  Future<int> deleteSyncedOperations() {
    return (
        delete(offlineOperations)
          ..where(
                (table) =>
                table.status.equals(
                  'synced',
                ),
          )
    ).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(
        () async {
      final directory =
      await getApplicationDocumentsDirectory();

      final file = File(
        p.join(
          directory.path,
          'vectorflow.sqlite',
        ),
      );

      return NativeDatabase.createInBackground(
        file,
      );
    },
  );
}

final databaseProvider =
Provider<AppDatabase>(
      (ref) {
    final database =
    AppDatabase();

    ref.onDispose(
      database.close,
    );

    return database;
  },
);