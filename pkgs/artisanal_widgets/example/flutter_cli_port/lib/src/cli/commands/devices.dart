import 'dart:io';

import '../../model.dart';
import '../../panels/devices.dart' show platformIcon;

Future<void> runDevicesCommand() async {
  final devices = <FlutterCliDevice>[];
  final adb = await _run('adb', ['devices', '-l']);
  if (adb case final result? when result.exitCode == 0) {
    devices.addAll(parseAdbDevices(result.stdout));
  }
  for (var i = 0; i < devices.length; i++) {
    final device = devices[i];
    if (_isApple(device.platform)) continue;
    final version = await _run('adb', [
      '-s',
      device.serial,
      'shell',
      'getprop',
      'ro.build.version.release',
    ]);
    final androidVersion = version?.stdout.trim();
    if (androidVersion != null && androidVersion.isNotEmpty) {
      devices[i] = FlutterCliDevice(
        serial: device.serial,
        name: device.name,
        connection: device.connection,
        state: device.state,
        model: device.model,
        ip: device.ip,
        androidVersion: androidVersion,
        battery: device.battery,
        platform: device.platform,
      );
    }
  }
  printDevicesTable(devices);
}

List<FlutterCliDevice> parseAdbDevices(String output) {
  final devices = <FlutterCliDevice>[];
  for (final line in output.split('\n').skip(1)) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length < 2) continue;
    final serial = parts[0];
    final state = switch (parts[1]) {
      'device' => FlutterCliDeviceState.online,
      'offline' => FlutterCliDeviceState.offline,
      'unauthorized' => FlutterCliDeviceState.unauthorized,
      _ => FlutterCliDeviceState.connecting,
    };
    String? model;
    for (final part in parts.skip(2)) {
      if (part.startsWith('model:')) model = part.substring('model:'.length);
    }
    devices.add(
      FlutterCliDevice(
        serial: serial,
        name: model ?? serial,
        connection: serial.contains(':')
            ? FlutterCliConnectionKind.wifi
            : FlutterCliConnectionKind.usb,
        state: state,
        model: model,
        platform: 'android',
      ),
    );
  }
  return devices;
}

void printDevicesTable(List<FlutterCliDevice> devices) {
  if (devices.isEmpty) {
    stdout.writeln('(no devices)');
    return;
  }
  stdout.writeln(
    '  ${'NAME'.padRight(24)} ${'SERIAL'.padRight(32)} ${'PLATFORM'.padRight(10)} ${'CONN'.padRight(6)} OS',
  );
  for (final device in devices) {
    final state = switch (device.state) {
      FlutterCliDeviceState.online => '●',
      FlutterCliDeviceState.offline => '✗',
      FlutterCliDeviceState.unauthorized => '?',
      FlutterCliDeviceState.connecting => '…',
    };
    final platformRaw = device.platform ?? '-';
    final platformLabel = platformRaw == 'ios-simulator'
        ? 'ios-sim'
        : platformRaw;
    final glyph = platformIcon(platformRaw);
    final platform = glyph.isEmpty
        ? platformLabel.padRight(10)
        : '$glyph ${platformLabel.padRight(7)}';
    final connection = switch (device.connection) {
      FlutterCliConnectionKind.usb => 'USB',
      FlutterCliConnectionKind.wifi => 'WiFi',
    };
    stdout.writeln(
      '$state ${_truncate(device.name, 24).padRight(24)} '
      '${_truncate(device.serial, 32).padRight(32)} '
      '$platform ${connection.padRight(6)} ${device.androidVersion ?? ''}',
    );
  }
}

Future<ProcessResult?> _run(String executable, List<String> args) async {
  try {
    return await Process.run(executable, args);
  } on ProcessException {
    return null;
  }
}

bool _isApple(String? platform) {
  final value = platform?.toLowerCase();
  if (value == null) return false;
  return value.startsWith('ios') ||
      value.startsWith('ipad') ||
      value.startsWith('watch') ||
      value.contains('darwin') ||
      value.contains('macos');
}

String _truncate(String value, int max) {
  if (value.runes.length <= max) return value;
  return '${String.fromCharCodes(value.runes.take(max - 1))}…';
}
