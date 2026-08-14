// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:go_router/go_router.dart';
//
// import '../data/package_repository.dart';
// import '../domain/task_package.dart';
// import 'package_controller.dart';
//
// class CreatePackagePage extends ConsumerStatefulWidget {
//   const CreatePackagePage({super.key});
//
//   @override
//   ConsumerState<CreatePackagePage> createState() => _CreatePackagePageState();
// }
//
// class _CreatePackagePageState extends ConsumerState<CreatePackagePage> {
//   final _notes = TextEditingController();
//   final _itemName = TextEditingController();
//   final _itemDescription = TextEditingController();
//   final List<PackageItem> _items = [];
//   final List<String> _files = [];
//
//   PackagePriority _priority = PackagePriority.normal;
//   double? _latitude;
//   double? _longitude;
//   bool _submitting = false;
//
//   Future<void> _captureLocation() async {
//     var permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }
//     if (permission == LocationPermission.denied ||
//         permission == LocationPermission.deniedForever) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Location permission not granted.')),
//         );
//       }
//       return;
//     }
//
//     final position = await Geolocator.getCurrentPosition();
//     setState(() {
//       _latitude = position.latitude;
//       _longitude = position.longitude;
//     });
//   }
//
//   Future<void> _pickFiles() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       type: FileType.custom,
//       allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
//     );
//
//     if (result == null) return;
//     setState(() {
//       _files.addAll(
//         result.files.map((e) => e.path).whereType<String>(),
//       );
//     });
//   }
//
//   Future<void> _submit() async {
//     if (_items.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Add at least one item.')),
//       );
//       return;
//     }
//
//     setState(() => _submitting = true);
//
//     try {
//       final id = await ref.read(packagesProvider.notifier).create(
//             priority: _priority,
//             notes: _notes.text.trim(),
//             items: _items,
//             latitude: _latitude,
//             longitude: _longitude,
//           );
//
//       for (final path in _files) {
//         try {
//           await ref.read(packageRepositoryProvider).uploadAttachment(
//                 packageId: id,
//                 filePath: path,
//               );
//         } catch (_) {
//           // Attachment retry can be promoted to a dedicated offline operation.
//         }
//       }
//
//       if (mounted) context.go('/packages/$id');
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Unable to submit: $e')),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Create package')),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Text(
//             'Task Package',
//             style: Theme.of(context).textTheme.headlineSmall,
//           ),
//           const SizedBox(height: 16),
//           DropdownButtonFormField<PackagePriority>(
//             value: _priority,
//             items: PackagePriority.values
//                 .map(
//                   (e) => DropdownMenuItem(
//                     value: e,
//                     child: Text(e.name.toUpperCase()),
//                   ),
//                 )
//                 .toList(),
//             onChanged: (value) {
//               if (value != null) setState(() => _priority = value);
//             },
//             decoration: const InputDecoration(labelText: 'Priority'),
//           ),
//           const SizedBox(height: 16),
//           TextField(
//             controller: _notes,
//             maxLines: 4,
//             decoration: const InputDecoration(labelText: 'Notes'),
//           ),
//           const SizedBox(height: 24),
//           Text('Items', style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 8),
//           TextField(
//             controller: _itemName,
//             decoration: const InputDecoration(labelText: 'Item name'),
//           ),
//           const SizedBox(height: 12),
//           TextField(
//             controller: _itemDescription,
//             decoration: const InputDecoration(labelText: 'Description'),
//           ),
//           const SizedBox(height: 12),
//           OutlinedButton.icon(
//             onPressed: () {
//               if (_itemName.text.trim().isEmpty) return;
//               setState(() {
//                 _items.add(
//                   PackageItem(
//                     name: _itemName.text.trim(),
//                     quantity: 1,
//                     description: _itemDescription.text.trim(),
//                   ),
//                 );
//                 _itemName.clear();
//                 _itemDescription.clear();
//               });
//             },
//             icon: const Icon(Icons.add),
//             label: const Text('Add item'),
//           ),
//           ..._items.asMap().entries.map(
//                 (entry) => ListTile(
//                   contentPadding: EdgeInsets.zero,
//                   leading: const Icon(Icons.check_circle_outline),
//                   title: Text(entry.value.name),
//                   subtitle: Text(entry.value.description),
//                   trailing: IconButton(
//                     icon: const Icon(Icons.delete_outline),
//                     onPressed: () => setState(
//                       () => _items.removeAt(entry.key),
//                     ),
//                   ),
//                 ),
//               ),
//           const Divider(height: 32),
//           Text('Attachments', style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 8),
//           OutlinedButton.icon(
//             onPressed: _pickFiles,
//             icon: const Icon(Icons.attach_file),
//             label: const Text('Add image or PDF'),
//           ),
//           ..._files.map(
//             (path) => ListTile(
//               dense: true,
//               contentPadding: EdgeInsets.zero,
//               leading: const Icon(Icons.description_outlined),
//               title: Text(path.split('/').last),
//             ),
//           ),
//           const Divider(height: 32),
//           Text('Location', style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 8),
//           OutlinedButton.icon(
//             onPressed: _captureLocation,
//             icon: const Icon(Icons.my_location),
//             label: const Text('Capture current location'),
//           ),
//           if (_latitude != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 '${_latitude!.toStringAsFixed(6)}, '
//                 '${_longitude!.toStringAsFixed(6)}',
//               ),
//             ),
//           const SizedBox(height: 32),
//           FilledButton.icon(
//             onPressed: _submitting ? null : _submit,
//             icon: _submitting
//                 ? const SizedBox.square(
//                     dimension: 18,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Icon(Icons.send),
//             label: const Text('Submit package'),
//           ),
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
// }



import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/connectivity_service.dart';
import '../../offline/presentation/offline_queue_page.dart';
import '../data/package_repository.dart';
import '../domain/task_package.dart';
import 'package_controller.dart';

class CreatePackagePage extends ConsumerStatefulWidget {
  const CreatePackagePage({super.key});

  @override
  ConsumerState<CreatePackagePage> createState() =>
      _CreatePackagePageState();
}

class _CreatePackagePageState
    extends ConsumerState<CreatePackagePage> {
  final _notes = TextEditingController();
  final _itemName = TextEditingController();
  final _itemDescription = TextEditingController();

  final List<PackageItem> _items = [];
  final List<String> _files = [];

  PackagePriority _priority = PackagePriority.normal;

  double? _latitude;
  double? _longitude;

  bool _submitting = false;
  bool _gettingLocation = false;

  @override
  void dispose() {
    _notes.dispose();
    _itemName.dispose();
    _itemDescription.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    if (_gettingLocation) return;

    setState(() {
      _gettingLocation = true;
    });

    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location services on your phone.',
            ),
          ),
        );

        return;
      }

      var permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission was denied.',
            ),
          ),
        );

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Location permission is permanently denied. '
                  'Enable it from app settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                Geolocator.openAppSettings();
              },
            ),
          ),
        );

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location captured successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to capture location: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _gettingLocation = false;
        });
      }
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'pdf',
        ],
      );

      if (result == null) return;

      final paths = result.files
          .map((file) => file.path)
          .whereType<String>()
          .where((path) => !_files.contains(path))
          .toList();

      if (!mounted) return;

      setState(() {
        _files.addAll(paths);
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select attachment: $error',
          ),
        ),
      );
    }
  }

  void _addItem() {
    final name =
    _itemName.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter an item name first.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _items.add(
        PackageItem(
          name: name,
          quantity: 1,
          description:
          _itemDescription.text.trim(),
        ),
      );

      _itemName.clear();
      _itemDescription.clear();
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Add at least one item.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final connectivity =
      ref.read(
        connectivityServiceProvider,
      );

      final isOnline =
      await connectivity.isOnline;

      final packageId =
      await ref
          .read(
        packagesProvider.notifier,
      )
          .create(
        priority: _priority,
        notes:
        _notes.text.trim(),
        items:
        List.unmodifiable(_items),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!isOnline) {
        // Save every selected attachment into
        // persistent app storage + Drift queue.
        for (final path in _files) {
          try {
            await ref
                .read(packageRepositoryProvider)
                .queueAttachment(
              packageId: packageId,
              originalFilePath: path,
            );
          } catch (error) {
            debugPrint(
              'OFFLINE ATTACHMENT QUEUE FAILED: '
                  '$path -> $error',
            );
          }
        }

        ref.invalidate(offlineQueueProvider);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              _files.isEmpty
                  ? 'Package saved safely to the offline queue.'
                  : 'Package and ${_files.length} attachment(s) '
                  'saved safely to the offline queue.',
            ),
          ),
        );

        context.go('/offline');

        return;
      }
      //
      // if (!isOnline) {
      //   if (!mounted) return;
      //
      //   ScaffoldMessenger.of(context)
      //       .showSnackBar(
      //     const SnackBar(
      //       content: Text(
      //         'No internet connection. '
      //             'Package saved safely to the offline queue.',
      //       ),
      //     ),
      //   );
      //
      //   context.go('/offline');
      //
      //   return;
      // }

      // Online attachment uploads.
      //
      // The package itself has already been created on
      // the backend before attachments are uploaded.
      var uploadedCount = 0;
      var failedCount = 0;

      for (final path in _files) {
        try {
          await ref
              .read(
            packageRepositoryProvider,
          )
              .uploadAttachment(
            packageId: packageId,
            filePath: path,
          );

          uploadedCount++;
        } catch (error) {
          failedCount++;

          debugPrint(
            'ATTACHMENT UPLOAD FAILED: '
                '$path -> $error',
          );
        }
      }

      if (!mounted) return;

      if (_files.isNotEmpty) {
        if (failedCount == 0) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                '$uploadedCount attachment(s) uploaded.',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                '$uploadedCount attachment(s) uploaded, '
                    '$failedCount failed.',
              ),
            ),
          );
        }
      }

      context.go(
        '/packages/$packageId',
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to submit package: $error',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Create package'),
      ),
      body: ListView(
        padding:
        const EdgeInsets.all(16),
        children: [
          Text(
            'Task Package',
            style: Theme.of(context)
                .textTheme
                .headlineSmall,
          ),

          const SizedBox(height: 16),

          DropdownButtonFormField<
              PackagePriority>(
            value: _priority,
            items: PackagePriority.values
                .map(
                  (priority) =>
                  DropdownMenuItem(
                    value: priority,
                    child: Text(
                      priority.name
                          .toUpperCase(),
                    ),
                  ),
            )
                .toList(),
            onChanged: _submitting
                ? null
                : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _priority = value;
              });
            },
            decoration:
            const InputDecoration(
              labelText: 'Priority',
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _notes,
            enabled: !_submitting,
            maxLines: 4,
            decoration:
            const InputDecoration(
              labelText: 'Notes',
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Items',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 8),

          TextField(
            controller: _itemName,
            enabled: !_submitting,
            decoration:
            const InputDecoration(
              labelText: 'Item name',
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
            _itemDescription,
            enabled: !_submitting,
            decoration:
            const InputDecoration(
              labelText: 'Description',
            ),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed:
            _submitting ? null : _addItem,
            icon:
            const Icon(Icons.add),
            label:
            const Text('Add item'),
          ),

          ..._items.asMap().entries.map(
                (entry) {
              final index = entry.key;
              final item = entry.value;

              return ListTile(
                contentPadding:
                EdgeInsets.zero,
                leading: const Icon(
                  Icons
                      .check_circle_outline,
                ),
                title:
                Text(item.name),
                subtitle:
                item.description.isEmpty
                    ? null
                    : Text(
                  item.description,
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  onPressed: _submitting
                      ? null
                      : () {
                    setState(() {
                      _items.removeAt(
                        index,
                      );
                    });
                  },
                ),
              );
            },
          ),

          const Divider(height: 32),

          Text(
            'Attachments',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _submitting
                ? null
                : _pickFiles,
            icon: const Icon(
              Icons.attach_file,
            ),
            label: const Text(
              'Add image or PDF',
            ),
          ),

          ..._files.asMap().entries.map(
                (entry) {
              final index = entry.key;
              final path = entry.value;

              final fileName =
                  path
                      .replaceAll(
                    '\\',
                    '/',
                  )
                      .split('/')
                      .last;

              return ListTile(
                dense: true,
                contentPadding:
                EdgeInsets.zero,
                leading: const Icon(
                  Icons
                      .description_outlined,
                ),
                title:
                Text(fileName),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.close,
                  ),
                  onPressed: _submitting
                      ? null
                      : () {
                    setState(() {
                      _files.removeAt(
                        index,
                      );
                    });
                  },
                ),
              );
            },
          ),

          const Divider(height: 32),

          Text(
            'Location',
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: _submitting ||
                _gettingLocation
                ? null
                : _captureLocation,
            icon: _gettingLocation
                ? const SizedBox.square(
              dimension: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.my_location,
            ),
            label: Text(
              _gettingLocation
                  ? 'Getting location...'
                  : 'Capture current location',
            ),
          ),

          if (_latitude != null &&
              _longitude != null)
            Card(
              margin:
              const EdgeInsets.only(
                top: 12,
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.location_on_outlined,
                ),
                title: const Text(
                  'Location captured',
                ),
                subtitle: Text(
                  '${_latitude!.toStringAsFixed(6)}, '
                      '${_longitude!.toStringAsFixed(6)}',
                ),
                trailing: IconButton(
                  tooltip:
                  'Remove location',
                  icon: const Icon(
                    Icons.close,
                  ),
                  onPressed: _submitting
                      ? null
                      : () {
                    setState(() {
                      _latitude = null;
                      _longitude = null;
                    });
                  },
                ),
              ),
            ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed:
            _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
              dimension: 18,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : const Icon(
              Icons.send,
            ),
            label: Text(
              _submitting
                  ? 'Submitting...'
                  : 'Submit package',
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}