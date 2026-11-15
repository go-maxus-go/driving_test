import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

import '../models/question.dart';
import 'media_store.dart';

typedef MediaByteFetcher = Future<Uint8List> Function(Uri uri);

class MediaDownloadException implements Exception {
  const MediaDownloadException(this.message);
  final String message;

  @override
  String toString() => 'MediaDownloadException($message)';
}

class MediaCacheService extends ChangeNotifier {
  MediaCacheService({
    required this.store,
    MediaByteFetcher? fetcher,
    this.remoteBaseUrl = defaultRemoteBaseUrl,
    this.enableBackgroundSync = false,
    this.backgroundStepDelay = const Duration(milliseconds: 1200),
    this.backgroundRetryDelay = const Duration(seconds: 15),
    this.bulkConcurrency = 4,
    this.maxMemoryCachedImages = 80,
  }) : _fetcher = fetcher ?? _offlineStubFetcher;

  factory MediaCacheService.production({
    MediaStore? store,
    http.Client? httpClient,
    bool enableBackgroundSync = true,
  }) {
    final client = httpClient ?? http.Client();
    return MediaCacheService(
      store: store ?? createPlatformMediaStore(),
      enableBackgroundSync: enableBackgroundSync,
      fetcher: (uri) async {
        final response = await client.get(uri);
        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          throw MediaDownloadException('HTTP ${response.statusCode} for $uri');
        }
        return response.bodyBytes;
      },
    ).._ownedHttpClient = httpClient == null ? client : null;
  }

  static const String defaultRemoteBaseUrl =
      'https://raw.githubusercontent.com/go-maxus-go/driving_test/main';

  static Future<Uint8List> _offlineStubFetcher(Uri uri) {
    return Future<Uint8List>.error(
      MediaDownloadException('Offline test fetcher for $uri'),
    );
  }

  final MediaStore store;
  final MediaByteFetcher _fetcher;
  final String remoteBaseUrl;
  final bool enableBackgroundSync;
  final Duration backgroundStepDelay;
  final Duration backgroundRetryDelay;
  final int bulkConcurrency;
  final int maxMemoryCachedImages;

  http.Client? _ownedHttpClient;

  final List<String> _catalogOrderedPaths = <String>[];
  final Set<String> _catalogPathSet = <String>{};
  final Set<String> _cachedPaths = <String>{};
  final Map<String, Future<bool>> _inFlight = <String, Future<bool>>{};
  final LinkedHashMap<String, Uint8List> _memoryImages =
      LinkedHashMap<String, Uint8List>();

  int _activeUrgentCount = 0;
  Completer<void>? _urgentDrainCompleter;

  bool _backgroundLoopRunning = false;
  bool _isDownloadingAllOffline = false;
  bool _cancelOfflineRequested = false;
  String? _offlineDownloadError;
  bool _disposed = false;

  static String normalizeAssetPath(String rawPath) {
    final clean = rawPath.trim().replaceAll('\\', '/');
    if (clean.isEmpty) return '';
    final stripped = clean.startsWith('/') ? clean.substring(1) : clean;
    return stripped.startsWith('assets/') ? stripped : 'assets/$stripped';
  }

  static bool _isImagePath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  String remoteUrlFor(String assetPath) {
    final normalized = normalizeAssetPath(assetPath);
    final encoded = normalized
        .split('/')
        .where((s) => s.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    final trimmedBase = remoteBaseUrl.endsWith('/')
        ? remoteBaseUrl.substring(0, remoteBaseUrl.length - 1)
        : remoteBaseUrl;
    return '$trimmedBase/$encoded';
  }

  int get totalMediaCount => _catalogOrderedPaths.length;

  int get cachedMediaCount =>
      _catalogPathSet.where(_cachedPaths.contains).length;

  bool get isFullyCached =>
      _catalogOrderedPaths.isNotEmpty && cachedMediaCount >= totalMediaCount;

  double get offlineProgress => totalMediaCount == 0
      ? 1.0
      : (cachedMediaCount / totalMediaCount).clamp(0.0, 1.0);

  bool get isDownloadingAllOffline => _isDownloadingAllOffline;

  String? get offlineDownloadError => _offlineDownloadError;

  int get activeUrgentCount => _activeUrgentCount;

  bool isCached(String assetPath) =>
      _cachedPaths.contains(normalizeAssetPath(assetPath));

  Uint8List? getMemoryCachedImageBytes(String assetPath) {
    final normalized = normalizeAssetPath(assetPath);
    final existing = _memoryImages.remove(normalized);
    if (existing != null) {
      // Refresh LRU order
      _memoryImages[normalized] = existing;
    }
    return existing;
  }

  void _rememberImageBytes(String normalizedPath, Uint8List bytes) {
    if (!_isImagePath(normalizedPath) || maxMemoryCachedImages <= 0) return;
    _memoryImages.remove(normalizedPath);
    _memoryImages[normalizedPath] = bytes;
    while (_memoryImages.length > maxMemoryCachedImages) {
      _memoryImages.remove(_memoryImages.keys.first);
    }
  }

  void registerCatalogQuestions(Iterable<Question> questions) {
    final images = <String>[];
    final videos = <String>[];
    final seen = <String>{};

    for (final q in questions) {
      for (final img in q.imageAssetPaths) {
        final norm = normalizeAssetPath(img);
        if (norm.isNotEmpty && seen.add(norm)) {
          images.add(norm);
        }
      }
      for (final opt in q.options) {
        final optImg = opt.imageAssetPath;
        if (optImg != null) {
          final norm = normalizeAssetPath(optImg);
          if (norm.isNotEmpty && seen.add(norm)) {
            images.add(norm);
          }
        }
      }
      final vid = q.videoAssetPath;
      if (vid != null) {
        final norm = normalizeAssetPath(vid);
        if (norm.isNotEmpty && seen.add(norm)) {
          videos.add(norm);
        }
      }
    }

    _catalogOrderedPaths
      ..clear()
      ..addAll(images)
      ..addAll(videos);
    _catalogPathSet
      ..clear()
      ..addAll(_catalogOrderedPaths);
  }

  Future<void> initializeWithQuestions(Iterable<Question> questions) async {
    registerCatalogQuestions(questions);
    final persisted = await store.listCachedAssetPaths();
    if (_disposed) return;
    for (final path in persisted) {
      final norm = normalizeAssetPath(path);
      if (norm.isNotEmpty) {
        _cachedPaths.add(norm);
      }
    }
    notifyListeners();
    if (enableBackgroundSync) {
      _ensureBackgroundLoopRunning();
    }
  }

  void prefetchQuestionMedia(Question question, {bool highPriority = true}) {
    final vid = question.videoAssetPath;
    if (vid != null && vid.isNotEmpty) {
      unawaited(ensureAvailable(vid, highPriority: highPriority));
    }
    for (final img in question.imageAssetPaths) {
      if (img.isNotEmpty) {
        unawaited(ensureAvailable(img, highPriority: highPriority));
      }
    }
    for (final opt in question.options) {
      final optImg = opt.imageAssetPath;
      if (optImg != null && optImg.isNotEmpty) {
        unawaited(ensureAvailable(optImg, highPriority: highPriority));
      }
    }
  }

  Future<bool> ensureAvailable(
    String assetPath, {
    bool highPriority = true,
  }) async {
    final normalized = normalizeAssetPath(assetPath);
    if (normalized.isEmpty || _disposed) return false;
    if (_cachedPaths.contains(normalized)) return true;

    final remoteUrl = remoteUrlFor(normalized);
    if (await store.contains(normalized, remoteUrl)) {
      if (_disposed) return false;
      if (_cachedPaths.add(normalized)) {
        notifyListeners();
      }
      return true;
    }

    if (highPriority) {
      _incrementUrgent();
      try {
        return await _startOrJoinDownload(normalized);
      } finally {
        _decrementUrgent();
      }
    }

    return _startOrJoinDownload(normalized);
  }

  Future<Uint8List?> getOrDownloadImageBytes(
    String assetPath, {
    bool highPriority = true,
  }) async {
    final normalized = normalizeAssetPath(assetPath);
    if (normalized.isEmpty || _disposed) return null;

    final mem = getMemoryCachedImageBytes(normalized);
    if (mem != null) return mem;

    final remoteUrl = remoteUrlFor(normalized);
    final existingDisk = await store.readBytes(normalized, remoteUrl);
    if (existingDisk != null && existingDisk.isNotEmpty) {
      _rememberImageBytes(normalized, existingDisk);
      if (_cachedPaths.add(normalized) && !_disposed) {
        notifyListeners();
      }
      return existingDisk;
    }

    final ok = await ensureAvailable(normalized, highPriority: highPriority);
    if (!ok || _disposed) return null;

    final memAfter = getMemoryCachedImageBytes(normalized);
    if (memAfter != null) return memAfter;

    final loaded = await store.readBytes(normalized, remoteUrl);
    if (loaded != null && loaded.isNotEmpty) {
      _rememberImageBytes(normalized, loaded);
    }
    return loaded;
  }

  Future<VideoPlayerController?> obtainVideoController(
    String assetPath, {
    bool highPriority = true,
  }) async {
    final normalized = normalizeAssetPath(assetPath);
    if (normalized.isEmpty || _disposed) return null;
    final ok = await ensureAvailable(normalized, highPriority: highPriority);
    if (!ok || _disposed) return null;
    return store.createVideoController(normalized, remoteUrlFor(normalized));
  }

  Future<void> startDownloadAllOffline() async {
    if (_disposed || _isDownloadingAllOffline) return;
    if (isFullyCached) return;

    _isDownloadingAllOffline = true;
    _cancelOfflineRequested = false;
    _offlineDownloadError = null;
    notifyListeners();

    final queue = _catalogOrderedPaths
        .where((p) => !_cachedPaths.contains(p))
        .toList(growable: false);

    var nextIndex = 0;
    var failedCount = 0;

    Future<void> worker() async {
      while (!_disposed && !_cancelOfflineRequested) {
        if (nextIndex >= queue.length) break;
        final path = queue[nextIndex++];
        if (_cachedPaths.contains(path)) continue;
        final ok = await _startOrJoinDownload(path);
        if (!ok) {
          failedCount++;
        }
      }
    }

    final workerCount = bulkConcurrency.clamp(1, 8);
    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );

    if (_disposed) return;
    final wasCancelled = _cancelOfflineRequested;
    _isDownloadingAllOffline = false;
    _cancelOfflineRequested = false;

    if (!wasCancelled && failedCount > 0 && !isFullyCached) {
      _offlineDownloadError = 'failed_$failedCount';
    }
    notifyListeners();

    if (enableBackgroundSync && !isFullyCached) {
      _ensureBackgroundLoopRunning();
    }
  }

  void cancelDownloadAllOffline() {
    if (!_isDownloadingAllOffline) return;
    _cancelOfflineRequested = true;
    _isDownloadingAllOffline = false;
    notifyListeners();
    if (enableBackgroundSync && !isFullyCached) {
      _ensureBackgroundLoopRunning();
    }
  }

  void _incrementUrgent() {
    _activeUrgentCount++;
    _urgentDrainCompleter ??= Completer<void>();
  }

  void _decrementUrgent() {
    if (_activeUrgentCount > 0) {
      _activeUrgentCount--;
    }
    if (_activeUrgentCount == 0) {
      final c = _urgentDrainCompleter;
      _urgentDrainCompleter = null;
      if (c != null && !c.isCompleted) {
        c.complete();
      }
    }
  }

  Future<void> _waitUntilNoUrgentDownloads() async {
    while (!_disposed && _activeUrgentCount > 0) {
      final waiter = _urgentDrainCompleter?.future;
      if (waiter != null) {
        await waiter;
      } else {
        break;
      }
    }
  }

  Future<bool> _startOrJoinDownload(String normalizedPath) {
    final existing = _inFlight[normalizedPath];
    if (existing != null) return existing;

    final future = _performDownload(normalizedPath);
    _inFlight[normalizedPath] = future;
    future.whenComplete(() {
      _inFlight.remove(normalizedPath);
    });
    return future;
  }

  Future<bool> _performDownload(String normalizedPath) async {
    final remoteUrl = remoteUrlFor(normalizedPath);
    try {
      final bytes = await _fetcher(Uri.parse(remoteUrl));
      if (_disposed || bytes.isEmpty) return false;
      await store.writeBytes(normalizedPath, remoteUrl, bytes);
      if (_disposed) return false;
      _rememberImageBytes(normalizedPath, bytes);
      _cachedPaths.add(normalizedPath);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void _ensureBackgroundLoopRunning() {
    if (_backgroundLoopRunning || _disposed || !enableBackgroundSync) return;
    _backgroundLoopRunning = true;
    unawaited(_runBackgroundLoop());
  }

  Future<void> _runBackgroundLoop() async {
    try {
      while (!_disposed && enableBackgroundSync) {
        if (_isDownloadingAllOffline || isFullyCached) {
          break;
        }
        await _waitUntilNoUrgentDownloads();
        if (_disposed || _isDownloadingAllOffline || isFullyCached) break;

        String? nextTarget;
        for (final path in _catalogOrderedPaths) {
          if (!_cachedPaths.contains(path) && !_inFlight.containsKey(path)) {
            nextTarget = path;
            break;
          }
        }
        if (nextTarget == null) break;

        final ok = await _startOrJoinDownload(nextTarget);
        if (_disposed || _isDownloadingAllOffline) break;

        final pause = ok ? backgroundStepDelay : backgroundRetryDelay;
        if (pause > Duration.zero) {
          await Future<void>.delayed(pause);
        }
      }
    } finally {
      _backgroundLoopRunning = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final c = _urgentDrainCompleter;
    _urgentDrainCompleter = null;
    if (c != null && !c.isCompleted) {
      c.complete();
    }
    _ownedHttpClient?.close();
    unawaited(store.dispose());
    super.dispose();
  }
}
