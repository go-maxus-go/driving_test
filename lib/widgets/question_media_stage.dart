import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_language.dart';
import '../models/question.dart';
import '../services/media_cache_service.dart';
import '../theme/app_theme.dart';
import 'cached_asset_image.dart';
import 'media_cache_scope.dart';

const SystemUiOverlayStyle _kFullscreenBlackOverlayStyle = SystemUiOverlayStyle(
  statusBarColor: Colors.black,
  statusBarIconBrightness: Brightness.light,
  statusBarBrightness: Brightness.dark,
  systemNavigationBarColor: Colors.black,
  systemNavigationBarIconBrightness: Brightness.light,
);

/// Computes a new zoom transform at [scale] (default 3x) while keeping the
/// exact scene point currently at the viewport center pinned to the center.
Matrix4 computeCenterZoomMatrix({
  required Matrix4 currentMatrix,
  required Size viewportSize,
  double scale = 3.0,
}) {
  final currentScale = currentMatrix.getMaxScaleOnAxis();
  final safeCurrentScale = currentScale > 0 ? currentScale : 1.0;
  final currentTranslation = currentMatrix.getTranslation();

  final centerX = viewportSize.width / 2.0;
  final centerY = viewportSize.height / 2.0;

  // Map viewport center back into scene coordinates under the current transform.
  final sceneCenterX = (centerX - currentTranslation.x) / safeCurrentScale;
  final sceneCenterY = (centerY - currentTranslation.y) / safeCurrentScale;

  final minDx = -(scale - 1.0) * viewportSize.width;
  final minDy = -(scale - 1.0) * viewportSize.height;
  final dx = (centerX - scale * sceneCenterX).clamp(minDx, 0.0);
  final dy = (centerY - scale * sceneCenterY).clamp(minDy, 0.0);

  return Matrix4.diagonal3Values(scale, scale, 1.0)
    ..setTranslationRaw(dx, dy, 0.0);
}

bool isVideoStoppedAtEnd(VideoPlayerValue value) {
  if (!value.isInitialized || value.isPlaying) return false;
  if (value.isCompleted) return true;
  return value.duration > Duration.zero &&
      value.position >= value.duration - const Duration(milliseconds: 150);
}

class QuestionMediaStage extends StatefulWidget {
  const QuestionMediaStage({
    super.key,
    required this.question,
    required this.strings,
    this.mediaCache,
    this.isAnswered = false,
    this.isExamVideoPhaseOne = false,
    this.isVideoLockedToFreezeFrame = false,
    this.examPlaysRemaining = 5,
    this.maxExamPlays = 5,
    this.onExamVideoPlayStarted,
    this.onRevealExamQuestion,
    this.enableNativeVideo = true,
    this.videoControllerBuilder,
  });

  final Question question;
  final AppStrings strings;
  final MediaCacheService? mediaCache;
  final bool isAnswered;
  final bool isExamVideoPhaseOne;
  final bool isVideoLockedToFreezeFrame;
  final int examPlaysRemaining;
  final int maxExamPlays;
  final VoidCallback? onExamVideoPlayStarted;
  final VoidCallback? onRevealExamQuestion;
  final bool enableNativeVideo;
  final VideoPlayerController Function(String assetPath)?
  videoControllerBuilder;

  @override
  State<QuestionMediaStage> createState() => _QuestionMediaStageState();
}

class _QuestionMediaStageState extends State<QuestionMediaStage> {
  VideoPlayerController? _videoController;
  Future<void>? _pendingDispose;
  MediaCacheService? _lastCache;
  bool _didInitMedia = false;
  bool _videoLoading = false;
  bool _videoReady = false;
  bool _videoError = false;
  int _setupGeneration = 0;
  final ValueNotifier<int> _stageRevision = ValueNotifier<int>(0);

  MediaCacheService? _resolveCache(BuildContext context) =>
      widget.mediaCache ?? MediaCacheScope.maybeOf(context);

  void _bumpRevision() {
    _stageRevision.value++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cache = _resolveCache(context);
    if (!_didInitMedia || _lastCache != cache) {
      _didInitMedia = true;
      _lastCache = cache;
      _disposeVideo();
      _setupMedia(cache);
    }
  }

  @override
  void didUpdateWidget(covariant QuestionMediaStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cache = _resolveCache(context);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.isVideoLockedToFreezeFrame !=
            widget.isVideoLockedToFreezeFrame ||
        oldWidget.mediaCache != widget.mediaCache) {
      _lastCache = cache;
      _disposeVideo();
      _setupMedia(cache);
      return;
    }

    if (!oldWidget.isAnswered && widget.isAnswered) {
      unawaited(_pauseIfPlaying());
    } else if (oldWidget.isAnswered && !widget.isAnswered) {
      unawaited(_replayClip());
    }
  }

  void _onVideoControllerUpdate() {
    if (mounted) {
      setState(_bumpRevision);
    }
  }

  Future<void> _pauseIfPlaying() async {
    final ctrl = _videoController;
    if (ctrl == null || !_videoReady) return;
    if (ctrl.value.isPlaying) {
      await ctrl.pause();
      if (mounted) {
        setState(_bumpRevision);
      }
    }
  }

  void _setupMedia(MediaCacheService? cache) {
    final gen = ++_setupGeneration;
    if (widget.question.mediaKind != QuestionMediaKind.video ||
        widget.isVideoLockedToFreezeFrame) {
      return;
    }

    final previewImg = widget.question.primaryImageAsset;
    if (cache != null && previewImg != null && previewImg.isNotEmpty) {
      unawaited(cache.ensureAvailable(previewImg, highPriority: false));
    }

    if (!widget.enableNativeVideo && widget.videoControllerBuilder == null) {
      return;
    }

    final assetPath = widget.question.videoAssetPath;
    if (assetPath == null || assetPath.isEmpty) return;

    final alreadyCached = cache == null || cache.isCached(assetPath);
    _videoLoading = !alreadyCached;
    _videoReady = false;
    _videoError = false;
    _bumpRevision();

    unawaited(_loadAndStartVideo(assetPath: assetPath, cache: cache, gen: gen));
  }

  Future<void> _loadAndStartVideo({
    required String assetPath,
    required MediaCacheService? cache,
    required int gen,
  }) async {
    try {
      final previousDispose = _pendingDispose;
      if (previousDispose != null) {
        await previousDispose;
      }
      if (!mounted || gen != _setupGeneration) return;

      VideoPlayerController? controller;
      if (widget.videoControllerBuilder != null) {
        if (cache != null) {
          final ok = await cache.ensureAvailable(assetPath, highPriority: true);
          if (!mounted || gen != _setupGeneration) return;
          if (!ok) {
            setState(() {
              _videoLoading = false;
              _videoReady = false;
              _videoError = true;
              _bumpRevision();
            });
            return;
          }
        }
        controller = widget.videoControllerBuilder!(assetPath);
      } else if (cache != null) {
        controller = await cache.obtainVideoController(
          assetPath,
          highPriority: true,
        );
      } else {
        controller = VideoPlayerController.asset(assetPath);
      }

      if (!mounted || gen != _setupGeneration) {
        if (controller != null) {
          unawaited(controller.dispose());
        }
        return;
      }

      if (controller == null) {
        setState(() {
          _videoLoading = false;
          _videoReady = false;
          _videoError = true;
          _bumpRevision();
        });
        return;
      }

      controller.addListener(_onVideoControllerUpdate);
      _videoController = controller;

      await controller.initialize();
      if (!mounted ||
          gen != _setupGeneration ||
          _videoController != controller) {
        return;
      }
      await controller.setVolume(0);
      await controller.seekTo(Duration.zero);
      setState(() {
        _videoLoading = false;
        _videoReady = true;
        _videoError = false;
        _bumpRevision();
      });

      if (widget.isAnswered) {
        await controller.pause();
      } else if (!widget.isExamVideoPhaseOne || widget.examPlaysRemaining > 0) {
        widget.onExamVideoPlayStarted?.call();
        await controller.play();
      }
    } catch (_) {
      if (!mounted || gen != _setupGeneration) return;
      setState(() {
        _videoLoading = false;
        _videoReady = false;
        _videoError = true;
        _bumpRevision();
      });
    }
  }

  void _disposeVideo() {
    _setupGeneration++;
    final old = _videoController;
    _videoController = null;
    _videoLoading = false;
    _videoReady = false;
    _videoError = false;
    if (old != null) {
      old.removeListener(_onVideoControllerUpdate);
      final prev = _pendingDispose;
      _pendingDispose = () async {
        if (prev != null) {
          try {
            await prev;
          } catch (_) {}
        }
        try {
          await old.dispose();
        } catch (_) {}
      }();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    _stageRevision.dispose();
    super.dispose();
  }

  bool get _canReplay =>
      !widget.isExamVideoPhaseOne || widget.examPlaysRemaining > 0;

  Future<void> _replayClip() async {
    if (!_canReplay) return;
    final ctrl = _videoController;
    if (ctrl != null && _videoReady) {
      widget.onExamVideoPlayStarted?.call();
      await ctrl.seekTo(Duration.zero);
      await ctrl.play();
      if (mounted) setState(_bumpRevision);
    } else if (_videoError) {
      _setupMedia(_resolveCache(context));
      if (mounted) setState(_bumpRevision);
    } else if (!widget.enableNativeVideo &&
        widget.videoControllerBuilder == null) {
      widget.onExamVideoPlayStarted?.call();
    }
  }

  void _handleVideoSurfaceTap() {
    final ctrl = _videoController;
    if (ctrl != null &&
        _videoReady &&
        (isVideoStoppedAtEnd(ctrl.value) ||
            (widget.isAnswered && !ctrl.value.isPlaying))) {
      unawaited(_replayClip());
    } else if (_videoError) {
      _setupMedia(_resolveCache(context));
      if (mounted) setState(_bumpRevision);
    }
  }

  void _openFullscreenVideo(BuildContext context) {
    final cache = _resolveCache(context);
    final img = widget.question.primaryImageAsset;
    showDialog<void>(
      context: context,
      useSafeArea: false,
      barrierColor: Colors.black,
      builder: (ctx) => AnnotatedRegion<SystemUiOverlayStyle>(
        key: const Key('fullscreen_video_overlay_region'),
        value: _kFullscreenBlackOverlayStyle,
        child: Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: ValueListenableBuilder<int>(
              valueListenable: _stageRevision,
              builder: (context, _, _) {
                final ctrl = _videoController;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      key: const Key('fullscreen_video_tap_area'),
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleVideoSurfaceTap,
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _videoReady && ctrl != null
                              ? VideoPlayer(ctrl)
                              : _videoLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 34,
                                    height: 34,
                                    child: CircularProgressIndicator(
                                      key: Key(
                                        'fullscreen_video_loading_indicator',
                                      ),
                                      color: Colors.white,
                                      strokeWidth: 2.8,
                                    ),
                                  ),
                                )
                              : (img != null
                                    ? CachedAssetImage(
                                        assetPath: img,
                                        mediaCache: cache,
                                        fit: BoxFit.contain,
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.videocam_outlined,
                                          color: Colors.white54,
                                          size: 48,
                                        ),
                                      )),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _SubtleFullscreenIconButton(
                        buttonKey: const Key('replay_fullscreen_video_btn'),
                        icon: Icons.replay_rounded,
                        tooltip: widget.strings.replayVideo,
                        onPressed: !_videoLoading && _canReplay
                            ? _replayClip
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _SubtleFullscreenIconButton(
                        buttonKey: const Key('close_fullscreen_video_btn'),
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final cache = _resolveCache(context);

    if (q.mediaKind == QuestionMediaKind.none ||
        q.mediaKind == QuestionMediaKind.optionImages) {
      return const SizedBox.shrink();
    }

    if (q.mediaKind == QuestionMediaKind.staticImage ||
        widget.isVideoLockedToFreezeFrame) {
      final imgPath = q.primaryImageAsset;
      if (imgPath == null) return const SizedBox.shrink();
      return _StaticOrFreezeImageCard(
        imageAssetPath: imgPath,
        mediaCache: cache,
        strings: widget.strings,
        isFreezeFrame: widget.isVideoLockedToFreezeFrame,
      );
    }

    final semantic = SemanticColors.of(context);

    // Video media stage (sharp square-cornered surface, no horizontal progress bar)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const Key('question_video_tap_area'),
          behavior: HitTestBehavior.opaque,
          onTap: _handleVideoSurfaceTap,
          child: Container(
            key: const Key('question_video_surface'),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: semantic.subtleBorder),
            ),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_videoReady && _videoController != null)
                    VideoPlayer(_videoController!)
                  else if (_videoLoading)
                    const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          key: Key('video_loading_indicator'),
                          color: Colors.white,
                          strokeWidth: 2.8,
                        ),
                      ),
                    )
                  else if (q.primaryImageAsset != null)
                    CachedAssetImage(
                      assetPath: q.primaryImageAsset!,
                      mediaCache: cache,
                      fit: BoxFit.contain,
                      fallbackIcon: Icons.videocam_outlined,
                      fallbackIconSize: 42,
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  if (_videoError && q.primaryImageAsset != null)
                    Positioned(
                      left: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: const BoxDecoration(color: Colors.black54),
                        child: const Text(
                          'Preview Frame',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (!widget.isExamVideoPhaseOne) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                key: const Key('practice_replay_video_btn'),
                onPressed: _videoLoading ? null : _replayClip,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(widget.strings.replayVideo),
              ),
              const Spacer(),
              IconButton.filledTonal(
                key: const Key('video_fullscreen_btn'),
                tooltip: widget.strings.fullScreenVideo,
                icon: const Icon(Icons.fullscreen_rounded),
                onPressed: () => _openFullscreenVideo(context),
              ),
            ],
          ),
        ],
        if (widget.isExamVideoPhaseOne) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.videocam_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.strings.watchVideoCarefully,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < widget.maxExamPlays; i++) ...[
                        Icon(
                          i < widget.examPlaysRemaining
                              ? Icons.circle
                              : Icons.circle_outlined,
                          size: 12,
                          color: i < widget.examPlaysRemaining
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(width: 5),
                      ],
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.strings.videoPlaysRemaining(
                            widget.examPlaysRemaining,
                            widget.maxExamPlays,
                          ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('exam_watch_video_again_btn'),
                          onPressed:
                              !_videoLoading && widget.examPlaysRemaining > 0
                              ? _replayClip
                              : null,
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(
                            widget.strings.watchAgainButton(
                              widget.examPlaysRemaining,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        key: const Key('video_fullscreen_btn'),
                        tooltip: widget.strings.fullScreenVideo,
                        icon: const Icon(Icons.fullscreen_rounded),
                        onPressed: () => _openFullscreenVideo(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.strings.tuvVideoRuleNote,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StaticOrFreezeImageCard extends StatelessWidget {
  const _StaticOrFreezeImageCard({
    required this.imageAssetPath,
    required this.mediaCache,
    required this.strings,
    required this.isFreezeFrame,
  });

  final String imageAssetPath;
  final MediaCacheService? mediaCache;
  final AppStrings strings;
  final bool isFreezeFrame;

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return GestureDetector(
      key: const Key('question_image_tap_area'),
      onTap: () => showImageZoomLightbox(
        context,
        imageAssetPath,
        mediaCache: mediaCache,
      ),
      child: Container(
        key: const Key('question_image_surface'),
        constraints: const BoxConstraints(maxHeight: 240),
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.zero,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedAssetImage(
                assetPath: imageAssetPath,
                mediaCache: mediaCache,
                fit: BoxFit.contain,
                loadingKey: const Key('image_loading_indicator'),
              ),
            ),
            if (isFreezeFrame)
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  key: const Key('freeze_frame_badge'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        strings.freezeFrameBadge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SubtleFullscreenIconButton extends StatelessWidget {
  const _SubtleFullscreenIconButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      key: buttonKey,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white70,
        disabledForegroundColor: Colors.white30,
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        side: const BorderSide(color: Colors.white38, width: 1.0),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

void showImageZoomLightbox(
  BuildContext context,
  String imageAssetPath, {
  MediaCacheService? mediaCache,
}) {
  final effectiveCache = mediaCache ?? MediaCacheScope.maybeOf(context);
  showDialog<void>(
    context: context,
    useSafeArea: false,
    barrierColor: Colors.black,
    builder: (ctx) {
      final transformCtrl = TransformationController();
      return AnnotatedRegion<SystemUiOverlayStyle>(
        key: const Key('fullscreen_image_overlay_region'),
        value: _kFullscreenBlackOverlayStyle,
        child: Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewportSize = Size(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      key: const Key('lightbox_double_tap_area'),
                      onDoubleTap: () {
                        final currentScale = transformCtrl.value
                            .getMaxScaleOnAxis();
                        if (currentScale < 2.95) {
                          transformCtrl.value = computeCenterZoomMatrix(
                            currentMatrix: transformCtrl.value,
                            viewportSize: viewportSize,
                            scale: 3.0,
                          );
                        } else {
                          transformCtrl.value = Matrix4.identity();
                        }
                      },
                      child: InteractiveViewer(
                        transformationController: transformCtrl,
                        minScale: 0.8,
                        maxScale: 5.0,
                        child: SizedBox(
                          width: viewportSize.width,
                          height: viewportSize.height,
                          child: Center(
                            child: Container(
                              key: const Key('lightbox_image_surface'),
                              constraints: const BoxConstraints(
                                minWidth: 120,
                                minHeight: 120,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: CachedAssetImage(
                                assetPath: imageAssetPath,
                                mediaCache: effectiveCache,
                                fit: BoxFit.contain,
                                loadingKey: const Key(
                                  'lightbox_loading_indicator',
                                ),
                                fallbackIcon: Icons.broken_image_outlined,
                                fallbackIconSize: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _SubtleFullscreenIconButton(
                        buttonKey: const Key('close_lightbox_btn'),
                        icon: Icons.close_rounded,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );
}
