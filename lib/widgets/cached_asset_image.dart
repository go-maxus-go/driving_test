import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../services/media_cache_service.dart';
import 'media_cache_scope.dart';

class CachedAssetImage extends StatefulWidget {
  const CachedAssetImage({
    super.key,
    required this.assetPath,
    this.mediaCache,
    this.fit = BoxFit.contain,
    this.loadingKey,
    this.indicatorSize = 28,
    this.fallbackIcon = Icons.image_outlined,
    this.fallbackIconSize = 40,
  });

  final String assetPath;
  final MediaCacheService? mediaCache;
  final BoxFit fit;
  final Key? loadingKey;
  final double indicatorSize;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  @override
  State<CachedAssetImage> createState() => _CachedAssetImageState();
}

class _CachedAssetImageState extends State<CachedAssetImage> {
  MediaCacheService? _subscribedCache;
  Uint8List? _bytes;
  bool _loading = false;
  int _loadGeneration = 0;

  MediaCacheService? _resolveCache(BuildContext context) =>
      widget.mediaCache ?? MediaCacheScope.maybeOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cache = _resolveCache(context);
    if (_subscribedCache != cache) {
      _subscribedCache?.removeListener(_onCacheUpdated);
      _subscribedCache = cache;
      _subscribedCache?.addListener(_onCacheUpdated);
      _startLoad();
    } else if (_bytes == null && !_loading && cache == null) {
      // No cache scope; Image.asset fallback will be used.
    }
  }

  @override
  void didUpdateWidget(covariant CachedAssetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cache = _resolveCache(context);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.mediaCache != widget.mediaCache) {
      if (_subscribedCache != cache) {
        _subscribedCache?.removeListener(_onCacheUpdated);
        _subscribedCache = cache;
        _subscribedCache?.addListener(_onCacheUpdated);
      }
      _startLoad();
    }
  }

  void _onCacheUpdated() {
    final cache = _subscribedCache;
    if (cache == null || _bytes != null || _loading) return;
    if (cache.isCached(widget.assetPath)) {
      _startLoad();
    }
  }

  void _startLoad() {
    final cache = _subscribedCache;
    final gen = ++_loadGeneration;
    if (cache == null) {
      _bytes = null;
      _loading = false;
      return;
    }

    final syncBytes = cache.getMemoryCachedImageBytes(widget.assetPath);
    if (syncBytes != null) {
      _bytes = syncBytes;
      _loading = false;
      return;
    }

    _bytes = null;
    _loading = true;

    unawaited(
      cache
          .getOrDownloadImageBytes(widget.assetPath, highPriority: true)
          .then((loaded) {
            if (!mounted || gen != _loadGeneration) return;
            setState(() {
              _bytes = loaded;
              _loading = false;
            });
          })
          .catchError((_) {
            if (!mounted || gen != _loadGeneration) return;
            setState(() {
              _bytes = null;
              _loading = false;
            });
          }),
    );
  }

  @override
  void dispose() {
    _subscribedCache?.removeListener(_onCacheUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cache = _resolveCache(context);
    if (cache == null) {
      return Image.asset(
        widget.assetPath,
        fit: widget.fit,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            widget.fallbackIcon,
            color: Colors.black38,
            size: widget.fallbackIconSize,
          ),
        ),
      );
    }

    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            widget.fallbackIcon,
            color: Colors.black38,
            size: widget.fallbackIconSize,
          ),
        ),
      );
    }

    if (_loading) {
      return Center(
        child: SizedBox(
          width: widget.indicatorSize,
          height: widget.indicatorSize,
          child: CircularProgressIndicator(
            key: widget.loadingKey ?? const Key('media_loading_indicator'),
            strokeWidth: 2.6,
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        widget.fallbackIcon,
        color: Colors.black38,
        size: widget.fallbackIconSize,
      ),
    );
  }
}
