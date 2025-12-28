import 'dart:io';

import 'package:file_cloud/drivers.dart';
import 'package:file_cloud/file_cloud.dart';
import 'package:path/path.dart' as p;
import 'package:storage_fs/storage_fs.dart';

import '../config/paths.dart';

// #region storage-service
class StorageService {
  StorageService({String? uploadsRoot})
    : uploadsRoot = uploadsRoot ?? AppPaths.uploadsDir;

  final String uploadsRoot;
  CloudFileSystem? _cloud;

  // #region storage-init
  Future<void> init() async {
    Directory(uploadsRoot).createSync(recursive: true);

    Storage.initialize({
      'default': 'uploads',
      'disks': {
        'uploads': {'driver': 'local', 'root': uploadsRoot},
      },
    });

    _cloud = _initCloudFromEnv();
    if (_cloud != null) {
      await _cloud!.driver.ensureReady();
    }
  }
  // #endregion storage-init

  // #region storage-save
  Future<String?> savePoster({
    required String? originalName,
    required List<int>? bytes,
  }) async {
    if (bytes == null || bytes.isEmpty) return null;

    final safeName = _buildSafeName(originalName ?? 'poster');
    final storagePath = p.join('posters', safeName);

    await Storage.put(storagePath, bytes);
    return storagePath;
  }
  // #endregion storage-save

  String publicUrl(String storagePath) {
    return '/uploads/${p.posix.normalize(storagePath)}';
  }

  Future<String?> cloudDownloadUrl(String storagePath, Duration ttl) async {
    if (_cloud == null) return null;
    return _cloud!.driver.presignDownload(storagePath, ttl);
  }

  CloudFileSystem? _initCloudFromEnv() {
    final endpoint = Platform.environment['S3_ENDPOINT'];
    final key = Platform.environment['S3_KEY'];
    final secret = Platform.environment['S3_SECRET'];
    final bucket = Platform.environment['S3_BUCKET'];
    if (endpoint == null || key == null || secret == null || bucket == null) {
      return null;
    }

    final uri = Uri.parse(endpoint);
    final client = Minio(
      endPoint: uri.host,
      port: uri.port == 0 ? null : uri.port,
      useSSL: uri.scheme == 'https',
      accessKey: key,
      secretKey: secret,
    );

    final driver = MinioCloudDriver(
      client: client,
      bucket: bucket,
      autoCreateBucket: true,
    );

    return CloudFileSystem(driver: driver);
  }

  String _buildSafeName(String name) {
    final base = p.basename(name).replaceAll(RegExp(r'\s+'), '-');
    final stamp = DateTime.now().millisecondsSinceEpoch;
    return '$stamp-$base';
  }
}

// #endregion storage-service
