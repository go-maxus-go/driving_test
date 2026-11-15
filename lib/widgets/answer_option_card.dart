import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../models/answer_evaluation.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import 'question_media_stage.dart';

class AnswerOptionCard extends StatelessWidget {
  const AnswerOptionCard({
    super.key,
    required this.option,
    required this.isSelected,
    required this.strings,
    this.feedbackState,
    this.peekTranslationText,
    this.onTap,
  });

  final QuestionOption option;
  final bool isSelected;
  final AppStrings strings;
  final OptionFeedbackState? feedbackState;
  final String? peekTranslationText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = SemanticColors.of(context);

    Color bgColor = semantic.cardSurface;
    Color borderColor = semantic.subtleBorder;
    double borderWidth = 1.2;
    bool useDashedBorder = false;
    double opacity = 1.0;
    Widget leadingIcon;
    Widget? statusBadge;

    if (feedbackState == null) {
      if (isSelected) {
        bgColor = scheme.primaryContainer.withValues(alpha: 0.55);
        borderColor = scheme.primary;
        borderWidth = 2.0;
        leadingIcon = Icon(
          Icons.check_box_rounded,
          color: scheme.primary,
          size: 24,
        );
      } else {
        leadingIcon = Icon(
          Icons.check_box_outline_blank_rounded,
          color: scheme.onSurfaceVariant,
          size: 24,
        );
      }
    } else {
      switch (feedbackState!) {
        case OptionFeedbackState.selectedCorrect:
          bgColor = semantic.correctSurface;
          borderColor = semantic.correctBorder;
          borderWidth = 2.0;
          leadingIcon = Icon(
            Icons.check_box_rounded,
            color: semantic.correctBorder,
            size: 24,
          );
          statusBadge = _FeedbackPill(
            key: Key('badge_correct_${option.letter}'),
            label: strings.badgeCorrect,
            bgColor: semantic.correctBorder,
            fgColor: Colors.white,
          );
        case OptionFeedbackState.selectedWrong:
          bgColor = semantic.wrongSurface;
          borderColor = semantic.wrongBorder;
          borderWidth = 2.0;
          leadingIcon = Icon(
            Icons.check_box_rounded,
            color: semantic.wrongBorder,
            size: 24,
          );
          statusBadge = _FeedbackPill(
            key: Key('badge_wrong_${option.letter}'),
            label: strings.badgeWrong,
            bgColor: semantic.wrongBorder,
            fgColor: Colors.white,
          );
        case OptionFeedbackState.missedCorrect:
          bgColor = semantic.missedSurface;
          borderColor = semantic.missedBorder;
          borderWidth = 2.2;
          useDashedBorder = true;
          leadingIcon = Icon(
            Icons.check_box_outline_blank_rounded,
            color: semantic.missedBorder,
            size: 24,
          );
          statusBadge = _FeedbackPill(
            key: Key('badge_missed_${option.letter}'),
            label: strings.badgeMissed,
            bgColor: semantic.missedBorder,
            fgColor: Colors.white,
          );
        case OptionFeedbackState.unselectedWrong:
          opacity = 0.58;
          leadingIcon = Icon(
            Icons.check_box_outline_blank_rounded,
            color: scheme.outline,
            size: 24,
          );
      }
    }

    Widget cardBody = Container(
      constraints: const BoxConstraints(minHeight: 58),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: useDashedBorder
            ? null
            : Border.all(color: borderColor, width: borderWidth),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('option_card_${option.letter}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                leadingIcon,
                const SizedBox(width: 12),
                Text(
                  option.displayLetter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 10),
                if (option.imageAssetPath != null) ...[
                  GestureDetector(
                    onTap: () =>
                        showImageZoomLightbox(context, option.imageAssetPath!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 76,
                        height: 76,
                        color: Colors.white,
                        padding: const EdgeInsets.all(4),
                        child: Image.asset(
                          option.imageAssetPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.traffic_rounded, size: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option.text.isNotEmpty)
                        Text(
                          option.text,
                          style: const TextStyle(
                            fontSize: 15.5,
                            height: 1.32,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (peekTranslationText != null &&
                          peekTranslationText!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          peekTranslationText!,
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (statusBadge != null) ...[
                  const SizedBox(width: 8),
                  statusBadge,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (useDashedBorder) {
      cardBody = CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: borderColor,
          strokeWidth: borderWidth,
          radius: 14,
        ),
        child: cardBody,
      );
    }

    return Opacity(opacity: opacity, child: cardBody);
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({
    super.key,
    required this.label,
    required this.bgColor,
    required this.fgColor,
  });

  final String label;
  final Color bgColor;
  final Color fgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fgColor,
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 7.0;
    const gapLength = 4.5;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}
