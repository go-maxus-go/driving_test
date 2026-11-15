import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import 'media_store.dart';

MediaStore createMediaStore() => IoMediaStore();

class IoMediaStore implements MediaStore {
  IoMediaStore({this.rootDirectoryProvider});

  final Future<Directory> Function()? rootDirectoryProvider;
  Directory? _cachedRootDir;

  Future<Directory> _rootDir() async {
    if (_cachedRootDir != null) return _cachedRootDir!;
    if (rootDirectoryProvider != null) {
      final custom = await rootDirectoryProvider!();
      if (!await custom.exists()) {
        await custom.create(recursive: true);
      }
      _cachedRootDir = custom;
      return custom;
    }
    final appSupport = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appSupport.path, 'media_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedRootDir = dir;
    return dir;
  }

  Future<File> _fileFor(String assetPath) async {
    final root = await _rootDir();
    final safeSegments = assetPath
        .split('/')
        .where((s) => s.isNotEmpty && s != '.' && s != '..')
        .toList(growable: false);
    return File(p.joinAll([root.path, ...safeSegments]));
  }

  @override
  Future<Set<String>> listCachedAssetPaths() async {
    final root = await _rootDir();
    if (!await root.exists()) return <String>{};
    final result = <String>{};
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && !entity.path.endsWith('.part')) {
        try {
          if (await entity.length() > 0) {
            final rel = p
                .relative(entity.path, from: root.path)
                .replaceAll('\\', '/');
            if (rel.isNotEmpty) {
              result.add(rel);
            }
          }
        } catch (_) {
          // Ignore transient filesystem errors on partial files.
        }
      }
    }
    return result;
  }

  @override
  Future<bool> contains(String assetPath, String remoteUrl) async {
    final file = await _fileFor(assetPath);
    if (!await file.exists()) return false;
    return (await file.length()) > 0;
  }

  @override
  Future<Uint8List?> readBytes(String assetPath, String remoteUrl) async {
    final file = await _fileFor(assetPath);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeBytes(
    String assetPath,
    String remoteUrl,
    Uint8List bytes,
  ) async {
    final target = await _fileFor(assetPath);
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.part');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(target.path);
  }

  @override
  Future<VideoPlayerController> createVideoController(
    String assetPath,
    String remoteUrl,
  ) async {
    final file = await _fileFor(assetPath);
    if (await file.exists() && await file.length() > 0) {
      return VideoPlayerController.file(file);
    }
    return VideoPlayerController.networkUrl(Uri.parse(remoteUrl));
  }

  @override
  Future<void> dispose() async {}
}
