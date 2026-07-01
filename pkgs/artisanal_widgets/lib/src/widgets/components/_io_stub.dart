// Stub for dart:io types used by file_picker.dart on web/WASM platforms.
// ignore_for_file: avoid_classes_with_only_static_members, one_member_abstracts

/// Stub for [dart:io FileSystemEntity].
abstract class FileSystemEntity {
  String get path;
  Future<bool> exists();
  Future<FileStat> stat();
}

/// Stub for [dart:io Directory].
class Directory implements FileSystemEntity {
  Directory(this.path);
  @override
  final String path;
  @override
  Future<bool> exists() async => false;
  @override
  Future<FileStat> stat() async => const FileStat._();
  Stream<FileSystemEntity> list({bool recursive = false}) =>
      const Stream.empty();
  Future<String> resolveSymbolicLinks() async => path;
  Directory get parent => Directory(path);
}

/// Stub for [dart:io Link].
class Link implements FileSystemEntity {
  Link(this.path);
  @override
  final String path;
  @override
  Future<bool> exists() async => false;
  @override
  Future<FileStat> stat() async => const FileStat._();
  Future<String> resolveSymbolicLinks() async => path;
  Future<String> target() async => path;
}

/// Stub for [dart:io FileStat].
class FileStat {
  const FileStat._();
  FileSystemEntityType get type => FileSystemEntityType.notFound;
  int get size => 0;
  int get mode => 0;
  static Future<FileStat> stat(String path) async => const FileStat._();
}

/// Stub for [dart:io FileSystemEntityType].
class FileSystemEntityType {
  const FileSystemEntityType._(this._name);
  final String _name;
  @override
  String toString() => _name;

  static const FileSystemEntityType file = FileSystemEntityType._('file');
  static const FileSystemEntityType directory = FileSystemEntityType._(
    'directory',
  );
  static const FileSystemEntityType link = FileSystemEntityType._('link');
  static const FileSystemEntityType notFound = FileSystemEntityType._(
    'notFound',
  );
}

/// Stub for [dart:io Platform].
class Platform {
  static const String pathSeparator = '/';
  static const Map<String, String> environment = {};
}
