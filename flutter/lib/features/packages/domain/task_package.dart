enum PackagePriority { low, normal, high, urgent }

enum PackageStatus {
  draft,
  queued,
  submitted,
  processing,
  waiting_for_external_result,
  ready,
  completed,
  failed,
}

class PackageItem {
  const PackageItem({
    required this.name,
    required this.quantity,
    this.description = '',
  });

  final String name;
  final int quantity;
  final String description;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'description': description,
      };

  factory PackageItem.fromJson(Map<String, dynamic> json) => PackageItem(
        name: json['name'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
        description: json['description'] as String? ?? '',
      );
}

class TaskPackage {
  const TaskPackage({
    required this.id,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.latitude,
    this.longitude,
    this.items = const [],
    this.attachments = const [],
  });

  final String id;
  final PackagePriority priority;
  final PackageStatus status;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final List<PackageItem> items;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskPackage copyWith({
    PackageStatus? status,
    List<String>? attachments,
  }) {
    return TaskPackage(
      id: id,
      priority: priority,
      status: status ?? this.status,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
      items: items,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  factory TaskPackage.fromJson(Map<String, dynamic> json) {
    PackagePriority priorityFrom(String? value) {
      return PackagePriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PackagePriority.normal,
      );
    }

    PackageStatus statusFrom(String? value) {
      return PackageStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => PackageStatus.submitted,
      );
    }

    return TaskPackage(
      id: json['id'] as String,
      priority: priorityFrom(json['priority'] as String?),
      status: statusFrom(json['status'] as String?),
      notes: json['notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      items: ((json['items'] as List?) ?? [])
          .map((e) => PackageItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      attachments: ((json['attachments'] as List?) ?? [])
          .map((e) => e is String ? e : (e as Map)['url'].toString())
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
