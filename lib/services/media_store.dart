import 'dart:typed_data';

import 'package:video_player/video_player.dart';

import 'media_store_io.dart'
    if (dart.library.js_interop) 'media_store_web.dart'
    as platform_store;

abstract class MediaStore {
  Future<Set<String>> listCachedAssetPaths();

  Future<bool> contains(String assetPath, String remoteUrl);

  Future<Uint8List?> readBytes(String assetPath, String remoteUrl);

  Future<void> writeBytes(String assetPath, String remoteUrl, Uint8List bytes);

  Future<VideoPlayerController> createVideoController(
    String assetPath,
    String remoteUrl,
  );

  Future<void> dispose() async {}
}

MediaStore createPlatformMediaStore() => platform_store.createMediaStore();

class InMemoryMediaStore implements MediaStore {
  InMemoryMediaStore([Map<String, Uint8List>? initialFiles])
    : _files = Map<String, Uint8List>.from(initialFiles ?? const {});

  final Map<String, Uint8List> _files;

  void seed(String assetPath, Uint8List bytes) {
    _files[assetPath] = bytes;
  }

  @override
  Future<Set<String>> listCachedAssetPaths() async => _files.keys.toSet();

  @override
  Future<bool> contains(String assetPath, String remoteUrl) async =>
      _files.containsKey(assetPath);

  @override
  Future<Uint8List?> readBytes(String assetPath, String remoteUrl) async =>
      _files[assetPath];

  @override
  Future<void> writeBytes(
    String assetPath,
    String remoteUrl,
    Uint8List bytes,
  ) async {
    _files[assetPath] = bytes;
  }

  @override
  Future<VideoPlayerController> createVideoController(
    String assetPath,
    String remoteUrl,
  ) async {
    return VideoPlayerController.networkUrl(Uri.parse(remoteUrl));
  }

  @override
  Future<void> dispose() async {}
}
