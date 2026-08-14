import 'package:flutter_test/flutter_test.dart';
import 'package:vectorflow/features/packages/domain/task_package.dart';

void main() {
  test('TaskPackage parses API JSON', () {
    final pkg = TaskPackage.fromJson({
      'id': 'VF-1',
      'priority': 'high',
      'status': 'processing',
      'items': [],
      'attachments': [],
      'createdAt': '2026-08-13T10:00:00Z',
      'updatedAt': '2026-08-13T10:00:00Z',
    });

    expect(pkg.priority, PackagePriority.high);
    expect(pkg.status, PackageStatus.processing);
  });
}
