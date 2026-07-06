// Stub for dart:io types used by image.dart on web/WASM platforms.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:typed_data' show Uint8List;

/// Stub for [dart:io File].
class File {
  File(this.path);
  final String path;
  Future<Uint8List> readAsBytes() async => Uint8List(0);

  Future<void> writeAsString(String s) async {}

  Future<void> delete() async {}
}

/// Stub for [dart:io Platform].
class Platform {
  static const String pathSeparator = '/';
  static const Map<String, String> environment = {};
}

/// Stub for [dart:io HttpClient].
class HttpClient {
  Future<HttpClientRequest> getUrl(Uri url) =>
      throw UnsupportedError('HttpClient not available on web');
  void close({bool force = false}) {}
}

/// Stub for [dart:io HttpClientRequest].
class HttpClientRequest {
  HttpHeaders get headers => _HttpHeadersStub();
  Future<HttpClientResponse> close() =>
      throw UnsupportedError('HttpClient not available on web');
}

/// Stub for [dart:io HttpHeaders] content type.
abstract class ContentTypeStub {
  String? get mimeType;
}

class _ContentTypeImpl implements ContentTypeStub {
  @override
  String? get mimeType => null;
}

/// Stub for [dart:io HttpClientResponse].
class HttpClientResponse extends Stream<List<int>> {
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.empty().listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  int get statusCode => 0;
  int get contentLength => -1;
  HttpHeaders get headers => _HttpHeadersStub();
}

/// Stub for [dart:io HttpHeaders].
abstract class HttpHeaders {
  static const String userAgentHeader = 'user-agent';
  static const String acceptHeader = 'accept';
  ContentTypeStub? get contentType => _ContentTypeImpl();
  void set(String name, Object value);
}

class _HttpHeadersStub implements HttpHeaders {
  @override
  ContentTypeStub? get contentType => _ContentTypeImpl();
  @override
  void set(String name, Object value) {}
}


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

  static Directory get systemTemp => Directory('');

  Future<Directory> createTemp(String s) async => Directory('');
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
