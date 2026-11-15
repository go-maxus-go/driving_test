import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/coverage_bar.dart';

class PracticeLaunchRequest {
  const PracticeLaunchRequest({
    required this.title,
    required this.questionIds,
    this.allowContinueSmartBatch = false,
  });

  final String title;
  final List<String> questionIds;
  final bool allowContinueSmartBatch;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onStartPractice,
    required this.onStartNewExam,
    required this.onResumeExam,
    required this.onOpenProgressTab,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest> onStartPractice;
  final VoidCallback onStartNewExam;
  final VoidCallback onResumeExam;
  final VoidCallback onOpenProgressTab;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final stats = controller.globalStats;
    final readiness = controller.readinessPercent;
    final activeExam = controller.activeExam;

    final mistakesCount = controller.mostMistakesCount;
    final leastCount = controller.leastAnsweredBadgeCount;
    final fivePtIds = controller.buildFivePointQueue();
    final videoIds = controller.buildVideoQueue();
    final numericIds = controller.buildNumericQueue();
    final savedIds = controller.buildSavedQueue();

    String? lastExamSummary;
    if (controller.examHistory.isNotEmpty) {
      final last = controller.examHistory.first;
      final verdict = last.passed
          ? (s.isDe ? 'Bestanden' : 'Passed')
          : (s.isDe ? 'Nicht best.' : 'Failed');
      lastExamSummary = s.isDe
          ? 'Letzte: ${last.totalErrorPoints} Pkt. ($verdict)'
          : 'Last: ${last.totalErrorPoints} Pts ($verdict)';
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            if (activeExam != null) ...[
              _ResumeExamBanner(
                strings: s,
                currentQuestion: activeExam.currentIndex + 1,
                totalQuestions: activeExam.questionIds.length,
                remainingSeconds: activeExam.remainingSeconds,
                onResume: onResumeExam,
              ),
              const SizedBox(height: 14),
            ],
            _LearningProgressCard(
              readinessPercent: readiness,
              stats: stats,
              strings: s,
              onTap: onOpenProgressTab,
            ),
            const SizedBox(height: 14),
            _ActionModeCard(
              cardKey: const Key('smart_practice_cta'),
              buttonKey: const Key('start_practice_button'),
              icon: Icons.play_arrow_rounded,
              title: s.smartPracticeTitle,
              subtitle: s.smartPracticeSubtitle,
              buttonLabel: s.startLabel,
              onTap: () {
                final queue = controller.buildSmartPracticeQueue();
                onStartPractice(
                  PracticeLaunchRequest(
                    title: s.smartPracticeTitle,
                    questionIds: queue,
                    allowContinueSmartBatch: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _ActionModeCard(
              cardKey: const Key('start_exam_simulation_card'),
              buttonKey: const Key('begin_exam_button'),
              icon: Icons.timer_outlined,
              title: s.examSimulationTitle,
              subtitle: s.examSimulationSubtitle(lastExamSummary),
              buttonLabel: s.beginLabel,
              onTap: onStartNewExam,
            ),
            const SizedBox(height: 22),
            Text(
              s.targetedDrillsHeader,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth >= 340;
                final cardWidth = twoColumns
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_most_mistakes'),
                        icon: Icons.error_outline_rounded,
                        accentColor: SemanticColors.of(context).wrongBorder,
                        title: s.drillMostMistakes,
                        subtitle: s.drillMostMistakesSub,
                        count: mistakesCount,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillMostMistakes,
                          ids: controller.buildMostMistakesQueue(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_least_answered'),
                        icon: Icons.explore_outlined,
                        accentColor: Theme.of(context).colorScheme.primary,
                        title: s.drillLeastAnswered,
                        subtitle: s.drillLeastAnsweredSub,
                        count: leastCount,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillLeastAnswered,
                          ids: controller.buildLeastAnsweredQueue(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_five_point'),
                        icon: Icons.warning_amber_rounded,
                        accentColor: SemanticColors.of(context).missedBorder,
                        title: s.drillFivePoint,
                        subtitle: s.drillFivePointSub,
                        count: fivePtIds.length,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillFivePoint,
                          ids: fivePtIds,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_videos'),
                        icon: Icons.videocam_outlined,
                        accentColor: const Color(0xFF7C3AED),
                        title: s.drillVideos,
                        subtitle: s.drillVideosSub,
                        count: videoIds.length,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillVideos,
                          ids: videoIds,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_numeric'),
                        icon: Icons.pin_outlined,
                        accentColor: const Color(0xFF0284C7),
                        title: s.drillNumeric,
                        subtitle: s.drillNumericSub,
                        count: numericIds.length,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillNumeric,
                          ids: numericIds,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _DrillTileCard(
                        key: const Key('drill_saved'),
                        icon: Icons.bookmark_outline_rounded,
                        accentColor: const Color(0xFFD97706),
                        title: s.drillSaved,
                        subtitle: s.drillSavedSub,
                        count: savedIds.length,
                        onTap: () => _launchIfNotEmpty(
                          context,
                          s,
                          title: s.drillSaved,
                          ids: savedIds,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _launchIfNotEmpty(
    BuildContext context,
    AppStrings s, {
    required String title,
    required List<String> ids,
  }) {
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(s.noQuestionsInDrill),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    onStartPractice(
      PracticeLaunchRequest(
        title: title,
        questionIds: ids,
        allowContinueSmartBatch: false,
      ),
    );
  }
}

class _ResumeExamBanner extends StatelessWidget {
  const _ResumeExamBanner({
    required this.strings,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.remainingSeconds,
    required this.onResume,
  });

  final AppStrings strings;
  final int currentQuestion;
  final int totalQuestions;
  final int remainingSeconds;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final mins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (remainingSeconds % 60).toString().padLeft(2, '0');
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.primaryContainer,
      child: InkWell(
        key: const Key('resume_exam_banner'),
        borderRadius: BorderRadius.circular(16),
        onTap: onResume,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.play_circle_fill_rounded,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.resumeExamBannerTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Q $currentQuestion/$totalQuestions • $mins:$secs',
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onPrimaryContainer.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonal(
                onPressed: onResume,
                child: Text(strings.resumeAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  const _LearningProgressCard({
    required this.readinessPercent,
    required this.stats,
    required this.strings,
    required this.onTap,
  });

  final int readinessPercent;
  final dynamic stats;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        key: const Key('readiness_hero_card'),
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: readinessPercent / 100.0,
                          strokeWidth: 6.5,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                        Text(
                          '$readinessPercent%',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.examReadiness,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CoverageLegendRow(stats: stats, strings: strings),
                        const SizedBox(height: 4),
                        Text(
                          strings.ofTotalQuestions(stats.totalQuestions),
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              StackedCoverageBar(stats: stats, height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionModeCard extends StatelessWidget {
  const _ActionModeCard({
    required this.cardKey,
    required this.buttonKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final Key cardKey;
  final Key buttonKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        key: cardKey,
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonal(
                key: buttonKey,
                onPressed: onTap,
                child: Text(buttonLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrillTileCard extends StatelessWidget {
  const _DrillTileCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
