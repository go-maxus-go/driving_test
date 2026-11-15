import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../l10n/app_language.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';

Matrix4 computeDoubleTapZoomMatrix({
  required Offset tapPosition,
  required Size viewportSize,
  double scale = 2.0,
}) {
  final minDx = -(scale - 1.0) * viewportSize.width;
  final minDy = -(scale - 1.0) * viewportSize.height;
  final dx = (viewportSize.width / 2.0 - scale * tapPosition.dx).clamp(
    minDx,
    0.0,
  );
  final dy = (viewportSize.height / 2.0 - scale * tapPosition.dy).clamp(
    minDy,
    0.0,
  );
  return Matrix4.diagonal3Values(scale, scale, 1.0)
    ..setTranslationRaw(dx, dy, 0.0);
}

class QuestionMediaStage extends StatefulWidget {
  const QuestionMediaStage({
    super.key,
    required this.question,
    required this.strings,
    this.isExamVideoPhaseOne = false,
    this.isVideoLockedToFreezeFrame = false,
    this.allowVideoScrubbing = false,
    this.examPlaysRemaining = 5,
    this.maxExamPlays = 5,
    this.onExamVideoPlayStarted,
    this.onRevealExamQuestion,
    this.enableNativeVideo = true,
  });

  final Question question;
  final AppStrings strings;
  final bool isExamVideoPhaseOne;
  final bool isVideoLockedToFreezeFrame;
  final bool allowVideoScrubbing;
  final int examPlaysRemaining;
  final int maxExamPlays;
  final VoidCallback? onExamVideoPlayStarted;
  final VoidCallback? onRevealExamQuestion;
  final bool enableNativeVideo;

  @override
  State<QuestionMediaStage> createState() => _QuestionMediaStageState();
}

class _QuestionMediaStageState extends State<QuestionMediaStage> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    _setupMedia();
  }

  @override
  void didUpdateWidget(covariant QuestionMediaStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.questionId != widget.question.questionId ||
        oldWidget.isVideoLockedToFreezeFrame !=
            widget.isVideoLockedToFreezeFrame) {
      _disposeVideo();
      _setupMedia();
    }
  }

  void _setupMedia() {
    if (widget.question.mediaKind != QuestionMediaKind.video ||
        widget.isVideoLockedToFreezeFrame ||
        !widget.enableNativeVideo) {
      return;
    }
    final assetPath = widget.question.videoAssetPath;
    if (assetPath == null || assetPath.isEmpty) return;

    final controller = VideoPlayerController.asset(assetPath);
    _videoController = controller;

    unawaited(
      controller
          .initialize()
          .then((_) async {
            if (!mounted || _videoController != controller) return;
            await controller.setVolume(0);
            setState(() {
              _videoReady = true;
              _videoError = false;
            });
            if (!widget.isExamVideoPhaseOne || widget.examPlaysRemaining > 0) {
              widget.onExamVideoPlayStarted?.call();
              await controller.play();
            }
          })
          .catchError((_) {
            if (!mounted || _videoController != controller) return;
            setState(() {
              _videoReady = false;
              _videoError = true;
            });
          }),
    );
  }

  void _disposeVideo() {
    final old = _videoController;
    _videoController = null;
    _videoReady = false;
    _videoError = false;
    if (old != null) {
      unawaited(old.dispose());
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  Future<void> _replayClip() async {
    if (widget.isExamVideoPhaseOne && widget.examPlaysRemaining <= 0) return;
    widget.onExamVideoPlayStarted?.call();
    final ctrl = _videoController;
    if (ctrl != null && _videoReady) {
      await ctrl.seekTo(Duration.zero);
      await ctrl.play();
      if (mounted) setState(() {});
    }
  }

  void _openFullscreenVideo(BuildContext context) {
    final ctrl = _videoController;
    final img = widget.question.primaryImageAsset;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ctrl != null && _videoReady
                      ? VideoPlayer(ctrl)
                      : (img != null
                            ? Image.asset(img, fit: BoxFit.contain)
                            : const Center(
                                child: Icon(
                                  Icons.videocam_outlined,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                              )),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _SubtleFullscreenCloseButton(
                  buttonKey: const Key('close_fullscreen_video_btn'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
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
        strings: widget.strings,
        isFreezeFrame: widget.isVideoLockedToFreezeFrame,
      );
    }

    // Video media stage
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: Colors.black,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_videoReady && _videoController != null)
                    VideoPlayer(_videoController!)
                  else if (q.primaryImageAsset != null)
                    Image.asset(
                      q.primaryImageAsset!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.videocam_outlined,
                          color: Colors.white54,
                          size: 42,
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.videocam_outlined,
                        color: Colors.white54,
                        size: 42,
                      ),
                    ),
                  if (_videoReady &&
                      _videoController != null &&
                      widget.allowVideoScrubbing &&
                      !widget.isExamVideoPhaseOne)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: VideoProgressIndicator(
                          _videoController!,
                          allowScrubbing: true,
                        ),
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
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(6),
                        ),
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
                onPressed: _replayClip,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(widget.strings.replayVideo),
              ),
              const Spacer(),
              IconButton.filledTonal(
                key: const Key('video_fullscreen_btn'),
                tooltip: 'Full Screen',
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
                  OutlinedButton.icon(
                    key: const Key('exam_watch_video_again_btn'),
                    onPressed: widget.examPlaysRemaining > 0
                        ? _replayClip
                        : null,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      widget.strings.watchAgainButton(
                        widget.examPlaysRemaining,
                      ),
                    ),
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
    required this.strings,
    required this.isFreezeFrame,
  });

  final String imageAssetPath;
  final AppStrings strings;
  final bool isFreezeFrame;

  @override
  Widget build(BuildContext context) {
    final semantic = SemanticColors.of(context);
    return GestureDetector(
      key: const Key('question_image_tap_area'),
      onTap: () => showImageZoomLightbox(context, imageAssetPath),
      child: Container(
        key: const Key('question_image_surface'),
        constraints: const BoxConstraints(maxHeight: 240),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: semantic.subtleBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(
                  imageAssetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.black38,
                      size: 40,
                    ),
                  ),
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
      ),
    );
  }
}

class _SubtleFullscreenCloseButton extends StatelessWidget {
  const _SubtleFullscreenCloseButton({
    required this.buttonKey,
    required this.onPressed,
  });

  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      key: buttonKey,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white70,
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        side: const BorderSide(color: Colors.white38, width: 1.0),
      ),
      icon: const Icon(Icons.close_rounded, size: 20),
    );
  }
}

void showImageZoomLightbox(BuildContext context, String imageAssetPath) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final transformCtrl = TransformationController();
      TapDownDetails? doubleTapDetails;
      return Dialog.fullscreen(
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
                    onDoubleTapDown: (details) {
                      doubleTapDetails = details;
                    },
                    onDoubleTap: () {
                      if (transformCtrl.value.isIdentity()) {
                        final tapPos =
                            doubleTapDetails?.localPosition ??
                            Offset(
                              viewportSize.width / 2,
                              viewportSize.height / 2,
                            );
                        transformCtrl.value = computeDoubleTapZoomMatrix(
                          tapPosition: tapPos,
                          viewportSize: viewportSize,
                        );
                      } else {
                        transformCtrl.value = Matrix4.identity();
                      }
                    },
                    child: InteractiveViewer(
                      transformationController: transformCtrl,
                      minScale: 0.8,
                      maxScale: 4.5,
                      child: SizedBox(
                        width: viewportSize.width,
                        height: viewportSize.height,
                        child: Center(
                          child: Container(
                            key: const Key('lightbox_image_surface'),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                imageAssetPath,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.black45,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _SubtleFullscreenCloseButton(
                      buttonKey: const Key('close_lightbox_btn'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}
