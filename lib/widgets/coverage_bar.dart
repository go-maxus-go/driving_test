import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../models/user_progress.dart';
import '../theme/app_theme.dart';

class StackedCoverageBar extends StatelessWidget {
  const StackedCoverageBar({super.key, required this.stats, this.height = 10});

  final CoverageStats stats;
  final double height;

  @override
  Widget build(BuildContext context) {
    final semantic = SemanticColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unseenColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    if (stats.totalQuestions <= 0) {
      return SizedBox(height: height);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (stats.correctQuestions > 0)
              Expanded(
                flex: stats.correctQuestions,
                child: ColoredBox(
                  color: semantic.correctBorder,
                  child: const SizedBox.expand(),
                ),
              ),
            if (stats.wrongQuestions > 0)
              Expanded(
                flex: stats.wrongQuestions,
                child: ColoredBox(
                  color: semantic.wrongBorder,
                  child: const SizedBox.expand(),
                ),
              ),
            if (stats.unseenQuestions > 0)
              Expanded(
                flex: stats.unseenQuestions,
                child: ColoredBox(
                  color: unseenColor,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoverageLegendRow extends StatelessWidget {
  const CoverageLegendRow({
    super.key,
    required this.stats,
    required this.strings,
    this.compact = false,
  });

  final CoverageStats stats;
  final AppStrings strings;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final semantic = SemanticColors.of(context);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = TextStyle(
      fontSize: compact ? 12.5 : 13.5,
      fontWeight: FontWeight.w600,
    );

    return Wrap(
      spacing: compact ? 12 : 16,
      runSpacing: 4,
      children: [
        _StatChip(
          icon: Icons.check_circle_rounded,
          color: semantic.correctBorder,
          label: compact
              ? '${stats.correctQuestions}'
              : '${stats.correctQuestions} ${strings.masteredLabel}',
          style: style,
        ),
        _StatChip(
          icon: Icons.cancel_rounded,
          color: semantic.wrongBorder,
          label: compact
              ? '${stats.wrongQuestions}'
              : '${stats.wrongQuestions} ${strings.mistakesLabel}',
          style: style,
        ),
        _StatChip(
          icon: Icons.radio_button_unchecked_rounded,
          color: muted,
          label: compact
              ? '${stats.unseenQuestions} ${strings.leftLabel}'
              : '${stats.unseenQuestions} ${strings.unseenLabel}',
          style: style,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.style,
  });

  final IconData icon;
  final Color color;
  final String label;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: style),
      ],
    );
  }
}
