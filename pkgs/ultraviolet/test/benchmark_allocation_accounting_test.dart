import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../benchmark/src/allocation_accounting.dart';

void main() {
  test(
    'reports allocation bytes and instances per measured operation',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'uv_allocation_test_',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final region = Directory('${temporary.path}/regions/region-1')
        ..createSync(recursive: true);
      File('${region.path}/summary.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'name': 'ultraviolet.decoder.csi_parameters',
          'attributes': <String, String>{'operations': '100'},
          'memory': <String, Object?>{
            'rawProfilePath': '${region.path}/memory_profile.json',
          },
        }),
      );
      File('${region.path}/memory_profile.json').writeAsStringSync(
        jsonEncode(<String, Object?>{
          'start': _snapshot(stringBytes: 100, stringInstances: 5),
          'end': _snapshot(stringBytes: 700, stringInstances: 35),
        }),
      );
      final report = <String, Object?>{
        'schema_version': 2,
        'metadata': <String, Object?>{},
        'benchmarks': <Map<String, Object?>>[
          <String, Object?>{
            'name': 'decoder.csi_parameters',
            'allocation': <String, Object?>{'status': 'not_measured'},
          },
        ],
      };

      await addAllocationAccounting(
        report: report,
        sessionDirectory: temporary,
      );

      final benchmark = (report['benchmarks']! as List).single as Map;
      final allocation = benchmark['allocation'] as Map;
      expect(allocation['status'], 'measured');
      expect(allocation['operations'], 100);
      expect(allocation['allocated_bytes'], 600);
      expect(allocation['allocated_instances'], 30);
      expect(allocation['bytes_per_operation'], 6.0);
      expect(allocation['instances_per_operation'], 0.3);
      expect(
        (allocation['top_classes'] as List).single,
        containsPair('class_name', '_OneByteString'),
      );
    },
  );

  test('marks a workload unavailable when no region was captured', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'uv_allocation_test_',
    );
    addTearDown(() => temporary.delete(recursive: true));
    final report = <String, Object?>{
      'metadata': <String, Object?>{},
      'benchmarks': <Map<String, Object?>>[
        <String, Object?>{'name': 'renderer.unchanged_120x40'},
      ],
    };

    await addAllocationAccounting(report: report, sessionDirectory: temporary);

    final benchmark = (report['benchmarks']! as List).single as Map;
    expect((benchmark['allocation'] as Map)['status'], 'unavailable');
  });
}

Map<String, Object?> _snapshot({
  required int stringBytes,
  required int stringInstances,
}) => <String, Object?>{
  'profiles': <Object?>[
    <String, Object?>{
      'allocationProfile': <String, Object?>{
        'members': <Object?>[
          <String, Object?>{
            'class': <String, Object?>{
              'name': '_OneByteString',
              'library': <String, Object?>{'uri': 'dart:core'},
            },
            'accumulatedSize': stringBytes,
            'instancesAccumulated': stringInstances,
          },
        ],
      },
    },
  ],
};
