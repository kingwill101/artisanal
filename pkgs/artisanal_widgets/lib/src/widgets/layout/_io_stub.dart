// Stub for dart:io types used by image.dart on web/WASM platforms.
// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:async';
import 'dart:typed_data' show Uint8List;

/// Stub for [dart:io File].
class File {
  File(this.path);
  final String path;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
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
