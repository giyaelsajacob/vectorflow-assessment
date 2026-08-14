


import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/storage/app_database.dart';
import '../domain/task_package.dart';

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepository(
    ref.watch(dioProvider),
    ref.watch(databaseProvider),
    ref.watch(connectivityServiceProvider),
  );
});

class PackageRepository {
  PackageRepository(
      this._dio,
      this._db,
      this._connectivity,
      );

  final Dio _dio;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  static const _uuid = Uuid();

  // ============================================================
  // GET ALL PACKAGES
  // ============================================================

  Future<List<TaskPackage>> getPackages() async {
    final response = await _dio.get('/packages');

    final data = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? []);

    return data
        .map(
          (item) => TaskPackage.fromJson(
        Map<String, dynamic>.from(
          item as Map,
        ),
      ),
    )
        .toList();
  }

  // ============================================================
  // GET SINGLE PACKAGE
  // ============================================================

  Future<TaskPackage> getPackage(
      String id,
      ) async {
    final response = await _dio.get(
      '/packages/$id',
    );

    return TaskPackage.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  // ============================================================
  // CREATE PACKAGE
  // ============================================================

  Future<String> createPackage({
    required PackagePriority priority,
    required String notes,
    required List<PackageItem> items,
    double? latitude,
    double? longitude,
  }) async {
    final clientId = _uuid.v4();

    final payload = <String, dynamic>{
      'clientId': clientId,
      'priority': priority.name,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'items': items
          .map(
            (item) => item.toJson(),
      )
          .toList(),
    };

    final online =
    await _connectivity.isOnline;

    // ----------------------------------------------------------
    // OFFLINE
    // ----------------------------------------------------------

    if (!online) {
      await _db.enqueue(
        OfflineOperationsCompanion.insert(
          id: clientId,
          entityId: clientId,
          operation: 'CREATE_PACKAGE',
          payload: jsonEncode(payload),
          createdAt: DateTime.now(),
        ),
      );

      return clientId;
    }

    // ----------------------------------------------------------
    // ONLINE
    // ----------------------------------------------------------

    final response = await _dio.post(
      '/packages',
      data: payload,
      options: Options(
        headers: {
          'Idempotency-Key': clientId,
        },
      ),
    );

    return response.data['id'] as String;
  }

  // ============================================================
  // ONLINE ATTACHMENT UPLOAD
  // ============================================================

  Future<void> uploadAttachment({
    required String packageId,
    required String filePath,
  }) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception(
        'Attachment file does not exist: $filePath',
      );
    }

    final fileName = p.basename(filePath);

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    await _dio.post(
      '/packages/$packageId/attachments',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
  }

  // ============================================================
  // SAVE ATTACHMENT FOR OFFLINE SYNC
  // ============================================================
  //
  // IMPORTANT:
  //
  // We do not store only FilePicker's original path.
  //
  // Android may remove temporary files later.
  //
  // Instead:
  //
  // selected file
  //      ↓
  // copied into VectorFlow application storage
  //      ↓
  // local path saved inside Drift queue
  //      ↓
  // app can be killed/reopened safely
  //
  // ============================================================

  Future<String> queueAttachment({
    required String packageId,
    required String originalFilePath,
  }) async {
    final sourceFile =
    File(originalFilePath);

    if (!await sourceFile.exists()) {
      throw Exception(
        'Selected attachment no longer exists.',
      );
    }

    final appDirectory =
    await getApplicationDocumentsDirectory();

    final attachmentDirectory =
    Directory(
      p.join(
        appDirectory.path,
        'pending_attachments',
      ),
    );

    if (!await attachmentDirectory.exists()) {
      await attachmentDirectory.create(
        recursive: true,
      );
    }

    final operationId = _uuid.v4();

    final originalName =
    p.basename(originalFilePath);

    final storedName =
        '${operationId}_$originalName';

    final storedPath = p.join(
      attachmentDirectory.path,
      storedName,
    );

    await sourceFile.copy(
      storedPath,
    );

    final payload = {
      'filePath': storedPath,
      'fileName': originalName,
    };

    await _db.enqueue(
      OfflineOperationsCompanion.insert(
        id: operationId,
        entityId: packageId,
        operation: 'UPLOAD_ATTACHMENT',
        payload: jsonEncode(payload),
        createdAt: DateTime.now(),
      ),
    );

    return operationId;
  }

  // ============================================================
  // SYNCHRONIZE OFFLINE OPERATIONS
  // ============================================================

  Future<int> syncPendingOperations() async {
    if (!await _connectivity.isOnline) {
      return 0;
    }

    var synchronizedCount = 0;

    // ==========================================================
    // STEP 1
    // CREATE PACKAGES FIRST
    // ==========================================================

    final firstPass =
    await _db.pendingOperations();

    for (final operation in firstPass) {
      if (operation.operation !=
          'CREATE_PACKAGE') {
        continue;
      }

      try {
        await _db.markSyncing(
          operation.id,
        );

        final payload =
        jsonDecode(operation.payload)
        as Map<String, dynamic>;

        final response = await _dio.post(
          '/packages',
          data: payload,
          options: Options(
            headers: {
              'Idempotency-Key':
              operation.id,
            },
          ),
        );

        final serverPackageId =
        response.data['id'] as String;

        final localPackageId =
            operation.entityId;

        // ------------------------------------------------------
        // Update attachment operations so they now reference
        // the REAL server package ID instead of the local UUID.
        // ------------------------------------------------------

        await _db.replacePendingEntityId(
          oldEntityId: localPackageId,
          newEntityId: serverPackageId,
        );

        await _db.markSynced(
          operation.id,
        );

        synchronizedCount++;

        print(
          'SYNC CREATE_PACKAGE: '
              '$localPackageId → $serverPackageId',
        );
      } catch (error) {
        await _db.markFailed(
          operation.id,
          operation.retryCount + 1,
        );

        print(
          'SYNC CREATE_PACKAGE FAILED: '
              '${operation.id} -> $error',
        );
      }
    }

    // ==========================================================
    // STEP 2
    // RELOAD QUEUE
    //
    // We reload because attachment entityIds may have changed
    // from local package ID → server package ID.
    // ==========================================================

    final secondPass =
    await _db.pendingOperations();

    // ==========================================================
    // STEP 3
    // UPLOAD ATTACHMENTS
    // ==========================================================

    for (final operation in secondPass) {
      if (operation.operation !=
          'UPLOAD_ATTACHMENT') {
        continue;
      }

      try {
        await _db.markSyncing(
          operation.id,
        );

        final payload =
        jsonDecode(operation.payload)
        as Map<String, dynamic>;

        final filePath =
        payload['filePath'] as String?;

        final fileName =
        payload['fileName'] as String?;

        if (filePath == null ||
            fileName == null) {
          throw Exception(
            'Attachment queue payload is invalid.',
          );
        }

        final file =
        File(filePath);

        if (!await file.exists()) {
          throw Exception(
            'Offline attachment file is missing.',
          );
        }

        final formData =
        FormData.fromMap({
          'file':
          await MultipartFile.fromFile(
            filePath,
            filename: fileName,
          ),
        });

        await _dio.post(
          '/packages/'
              '${operation.entityId}'
              '/attachments',
          data: formData,
          options: Options(
            contentType:
            'multipart/form-data',
            headers: {
              // Prevent duplicate attachment processing
              // when retrying the same operation.
              'Idempotency-Key':
              operation.id,
            },
          ),
        );

        await _db.markSynced(
          operation.id,
        );

        synchronizedCount++;

        print(
          'SYNC ATTACHMENT SUCCESS: '
              '$fileName',
        );

        // ------------------------------------------------------
        // Local copy is no longer needed after successful upload.
        // ------------------------------------------------------

        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {
          // File cleanup failure should not make the
          // already successful upload fail.
        }
      } catch (error) {
        await _db.markFailed(
          operation.id,
          operation.retryCount + 1,
        );

        print(
          'SYNC ATTACHMENT FAILED: '
              '${operation.id} -> $error',
        );
      }
    }

    return synchronizedCount;
  }
}