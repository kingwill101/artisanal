// Internal collector process: never loads the workload's widgets or retains
// profiling objects in the measured process.
import 'dart:convert';
import 'dart:io';

import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

Future<void> main(List<String> args) async {
  if (args.length != 6) {
    throw ArgumentError(
      'Expected VM URI, isolate, output, phase, RSS, output size',
    );
  }
  final service = await vmServiceConnectUri(args[0]);
  try {
    final targetId = args[1];
    await service.getAllocationProfile(targetId, gc: true);
    // Finalizer callbacks execute on the target event loop after collection.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final profile = await service.getAllocationProfile(targetId, gc: true);
    var liveBytes = 0;
    final counts = <String, int>{};
    final bytesByClass = <String, int>{};
    for (final member in profile.members ?? const <vm.ClassHeapStats>[]) {
      final bytes = member.bytesCurrent ?? 0;
      final instances = member.instancesCurrent ?? 0;
      liveBytes += bytes;
      if (instances == 0 && bytes == 0) continue;
      final ref = member.classRef;
      var library = '<unknown-library>';
      if (ref?.id != null) {
        final object = await service.getObject(targetId, ref!.id!);
        if (object is vm.Class) {
          library = object.library?.uri ?? object.library?.name ?? library;
        }
      }
      final key = '$library::${ref?.name ?? ref?.id ?? '<unknown-class>'}';
      counts[key] = (counts[key] ?? 0) + instances;
      bytesByClass[key] = (bytesByClass[key] ?? 0) + bytes;
    }
    await File(args[2]).writeAsString(
      jsonEncode({
        'phase': args[3],
        'rssBytes': int.parse(args[4]),
        'rendererOutputBytes': int.parse(args[5]),
        'liveBytes': liveBytes,
        'classCounts': counts,
        'classBytes': bytesByClass,
      }),
    );
  } finally {
    await service.dispose();
  }
}
