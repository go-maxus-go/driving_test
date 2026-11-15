import 'dart:js_interop';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:web/web.dart' as web;

import 'media_store.dart';

MediaStore createMediaStore() => WebMediaStore();

class WebMediaStore implements MediaStore {
  static const String _cacheName = 'driving_exam_media_v1';

  final Map<String, Uint8List> _fallbackMemory = <String, Uint8List>{};
  final Map<String, String> _blobUrlsByPath = <String, String>{};

  Future<web.Cache?> _openCache() async {
    try {
      return await web.window.caches.open(_cacheName).toDart;
    } catch (_) {
      return null;
    }
  }

  static String _mimeTypeFor(String assetPath) {
    final lower = assetPath.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }

  static String? _extractAssetPathFromUrl(String url) {
    final idx = url.indexOf('/assets/');
    if (idx < 0) return null;
    final raw = url.substring(idx + 1);
    return Uri.decodeFull(raw);
  }

  @override
  Future<Set<String>> listCachedAssetPaths() async {
    final found = <String>{..._fallbackMemory.keys};
    final cache = await _openCache();
    if (cache == null) return found;
    try {
      final keys = await cache.keys().toDart;
      for (final request in keys.toDart) {
        final extracted = _extractAssetPathFromUrl(request.url);
        if (extracted != null && extracted.isNotEmpty) {
          found.add(extracted);
        }
      }
    } catch (_) {
      // Ignore browser cache enumeration issues in restricted contexts.
    }
    return found;
  }

  @override
  Future<bool> contains(String assetPath, String remoteUrl) async {
    if (_fallbackMemory.containsKey(assetPath)) return true;
    final cache = await _openCache();
    if (cache == null) return false;
    try {
      final resp = await cache.match(remoteUrl.toJS).toDart;
      return resp != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<Uint8List?> readBytes(String assetPath, String remoteUrl) async {
    final inMem = _fallbackMemory[assetPath];
    if (inMem != null) return inMem;
    final cache = await _openCache();
    if (cache == null) return null;
    try {
      final resp = await cache.match(remoteUrl.toJS).toDart;
      if (resp == null) return null;
      final buffer = await resp.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
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
    final cache = await _openCache();
    if (cache == null) {
      _fallbackMemory[assetPath] = bytes;
      return;
    }
    try {
      final parts = <JSAny>[bytes.toJS].toJS;
      final blob = web.Blob(
        parts,
        web.BlobPropertyBag(type: _mimeTypeFor(assetPath)),
      );
      final response = web.Response(blob);
      await cache.put(remoteUrl.toJS, response).toDart;
    } catch (_) {
      _fallbackMemory[assetPath] = bytes;
    }
  }

  @override
  Future<VideoPlayerController> createVideoController(
    String assetPath,
    String remoteUrl,
  ) async {
    final existingBlobUrl = _blobUrlsByPath[assetPath];
    if (existingBlobUrl != null) {
      return VideoPlayerController.networkUrl(Uri.parse(existingBlobUrl));
    }

    final bytes = await readBytes(assetPath, remoteUrl);
    if (bytes != null && bytes.isNotEmpty) {
      try {
        final parts = <JSAny>[bytes.toJS].toJS;
        final blob = web.Blob(
          parts,
          web.BlobPropertyBag(type: _mimeTypeFor(assetPath)),
        );
        final objectUrl = web.URL.createObjectURL(blob);
        _blobUrlsByPath[assetPath] = objectUrl;
        return VideoPlayerController.networkUrl(Uri.parse(objectUrl));
      } catch (_) {
        // Fall back to direct remote URL if ObjectURL creation fails.
      }
    }

    return VideoPlayerController.networkUrl(Uri.parse(remoteUrl));
  }

  @override
  Future<void> dispose() async {
    for (final url in _blobUrlsByPath.values) {
      try {
        web.URL.revokeObjectURL(url);
      } catch (_) {}
    }
    _blobUrlsByPath.clear();
  }
}
