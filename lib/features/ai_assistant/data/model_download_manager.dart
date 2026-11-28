import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/ai_local_model_spec.dart';

enum ModelDownloadStatus {
  idle,
  downloading,
  completed,
  cancelled,
  error,
}

class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.status,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.filePath,
    this.errorMessage,
  });

  final ModelDownloadStatus status;
  final int receivedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final String? filePath;
  final String? errorMessage;

  double get fraction =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;
}

class ModelDownloadManager {
  ModelDownloadManager({Future<Directory> Function()? baseDirProvider})
      : _baseDirProvider = baseDirProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _baseDirProvider;

  Future<Directory> _modelsDir() async {
    final base = await _baseDirProvider();
    final dir = Directory('${base.path}/ai_models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String?> getDownloadedModelPath(LocalModelSpec spec) async {
    final dir = await _modelsDir();
    final file = File('${dir.path}/${spec.fileName}');
    if (await file.exists() && await file.length() > 0) {
      return file.path;
    }
    return null;
  }

  Future<void> deleteModel(LocalModelSpec spec) async {
    final dir = await _modelsDir();
    final file = File('${dir.path}/${spec.fileName}');
    if (await file.exists()) {
      await file.delete();
    }
    final partFile = File('${dir.path}/${spec.fileName}.part');
    if (await partFile.exists()) {
      await partFile.delete();
    }
  }

  Stream<ModelDownloadProgress> downloadModel(
    LocalModelSpec spec, {
    bool Function()? isCancelled,
  }) async* {
    final dir = await _modelsDir();
    final targetFile = File('${dir.path}/${spec.fileName}');
    final partFile = File('${dir.path}/${spec.fileName}.part');

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    IOSink? sink;

    try {
      yield const ModelDownloadProgress(
          status: ModelDownloadStatus.downloading);

      final req = await client.getUrl(Uri.parse(spec.downloadUrl));
      final res = await req.close();

      if (res.statusCode < 200 || res.statusCode >= 300) {
        yield ModelDownloadProgress(
          status: ModelDownloadStatus.error,
          errorMessage: 'تعذر تنزيل النموذج (رمز ${res.statusCode}).',
        );
        return;
      }

      final total =
          res.contentLength > 0 ? res.contentLength : spec.sizeMb * 1024 * 1024;
      final activeSink = partFile.openWrite();
      sink = activeSink;

      var received = 0;
      var lastEmit = DateTime.now();
      var lastBytes = 0;

      await for (final chunk in res) {
        if (isCancelled?.call() == true) {
          await activeSink.close();
          sink = null;
          if (await partFile.exists()) await partFile.delete();
          yield const ModelDownloadProgress(
            status: ModelDownloadStatus.cancelled,
          );
          return;
        }

        activeSink.add(chunk);
        received += chunk.length;

        final now = DateTime.now();
        final elapsedMs = now.difference(lastEmit).inMilliseconds;
        if (elapsedMs >= 250) {
          final speed = (received - lastBytes) / (elapsedMs / 1000.0);
          lastEmit = now;
          lastBytes = received;
          yield ModelDownloadProgress(
            status: ModelDownloadStatus.downloading,
            receivedBytes: received,
            totalBytes: total,
            bytesPerSecond: speed,
          );
        }
      }

      await activeSink.flush();
      await activeSink.close();
      sink = null;

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);

      yield ModelDownloadProgress(
        status: ModelDownloadStatus.completed,
        receivedBytes: received,
        totalBytes: received,
        filePath: targetFile.path,
      );
    } on SocketException {
      yield const ModelDownloadProgress(
        status: ModelDownloadStatus.error,
        errorMessage: 'لا يوجد اتصال بالإنترنت لإكمال التنزيل.',
      );
    } catch (e) {
      final failure = AppFailure.from(e);
      yield ModelDownloadProgress(
        status: ModelDownloadStatus.error,
        errorMessage: failure.userMessage,
      );
    } finally {
      await sink?.close();
      client.close(force: true);
    }
  }
}
