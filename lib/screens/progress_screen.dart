import 'package:material_ui/material_ui.dart';

import '../models/user_progress.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/coverage_bar.dart';
import 'home_screen.dart';
import 'mock_exam_history_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({
    super.key,
    required this.controller,
    required this.onStartPractice,
    required this.onStartExam,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest> onStartPractice;
  final VoidCallback onStartExam;

  void _launchExposureBucket({
    required BuildContext context,
    required String title,
    required List<String> questionIds,
  }) {
    if (questionIds.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(controller.strings.noQuestionsInDrill),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    onStartPractice(
      PracticeLaunchRequest(title: title, questionIds: questionIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.strings;
        final stats = controller.globalStats;
        final weakTopics = controller.rankedWeakTopics;
        final exams = controller.examHistory;

        final unseenIds = controller.currentQuestions
            .where((q) => controller.progressFor(q.questionId).isUnseen)
            .map((q) => q.questionId)
            .toList();

        final inTrainingIds = controller.currentQuestions
            .where((q) => controller.progressFor(q.questionId).isInTraining)
            .map((q) => q.questionId)
            .toList();

        final learnedIds = controller.currentQuestions
            .where((q) => controller.progressFor(q.questionId).isLearned)
            .map((q) => q.questionId)
            .toList();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.progressAnalyticsTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${controller.readinessPercent}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CoverageOverviewCard(stats: stats, controller: controller),
                const SizedBox(height: 22),
                _SectionHeader(title: s.weakTopicsHeader),
                const SizedBox(height: 10),
                if (weakTopics.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        s.allTopicsInGoodShape,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  for (final item in weakTopics.take(3)) ...[
                    _WeakTopicCard(
                      key: Key('weak_topic_row_${item.theme.themeCode}'),
                      item: item,
                      controller: controller,
                      onTrain: () {
                        var queue = controller.buildTopicQueue(
                          item.theme.questionIds,
                          unfinishedOnly: true,
                        );
                        if (queue.isEmpty) {
                          queue = controller.buildTopicQueue(
                            item.theme.questionIds,
                            unfinishedOnly: false,
                          );
                        }
                        onStartPractice(
                          PracticeLaunchRequest(
                            title:
                                '${item.theme.themeCode} ${item.theme.themeName}',
                            questionIds: queue,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 20),
                _SectionHeader(title: s.questionExposureTitle),
                const SizedBox(height: 6),
                Text(
                  s.questionExposureExplanation,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ExposureRow(
                          rowKey: const Key('exposure_row_0'),
                          buttonKey: const Key('exposure_drill_0'),
                          label: s.unseenBucketTitle,
                          subtitle: s.bucketDescription(
                            QuestionExposureBucket.neverAnswered,
                          ),
                          count: unseenIds.length,
                          total: stats.totalQuestions,
                          actionLabel: s.navTrain,
                          onAction: unseenIds.isEmpty
                              ? null
                              : () => _launchExposureBucket(
                                  context: context,
                                  title: s.unseenBucketTitle,
                                  questionIds: unseenIds,
                                ),
                        ),
                        const Divider(height: 22),
                        _ExposureRow(
                          rowKey: const Key('exposure_row_1'),
                          buttonKey: const Key('exposure_drill_1'),
                          label: s.inTrainingBucketTitle,
                          subtitle: s.bucketDescription(
                            QuestionExposureBucket.answeredOnce,
                          ),
                          count: inTrainingIds.length,
                          total: stats.totalQuestions,
                          actionLabel: s.navTrain,
                          onAction: inTrainingIds.isEmpty
                              ? null
                              : () => _launchExposureBucket(
                                  context: context,
                                  title: s.inTrainingBucketTitle,
                                  questionIds: inTrainingIds,
                                ),
                        ),
                        const Divider(height: 22),
                        _ExposureRow(
                          rowKey: const Key('exposure_row_2plus'),
                          buttonKey: const Key('exposure_drill_2'),
                          label: s.learnedBucketTitle,
                          subtitle: s.bucketDescription(
                            QuestionExposureBucket.practicedMultiple,
                          ),
                          count: learnedIds.length,
                          total: stats.totalQuestions,
                          actionLabel: s.navTrain,
                          onAction: learnedIds.isEmpty
                              ? null
                              : () => _launchExposureBucket(
                                  context: context,
                                  title: s.learnedBucketTitle,
                                  questionIds: learnedIds,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    key: const Key('open_mock_exam_history_btn'),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      s.mockExamHistoryTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      exams.isEmpty
                          ? s.noMockExamsYet
                          : (s.isDe
                                ? '${exams.length} Prüfungen absolviert'
                                : '${exams.length} exams completed'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MockExamHistoryScreen(
                            controller: controller,
                            onStartPractice: onStartPractice,
                            onStartExam: onStartExam,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _CoverageOverviewCard extends StatelessWidget {
  const _CoverageOverviewCard({required this.stats, required this.controller});

  final CoverageStats stats;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final semantic = SemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accuracyPct = (stats.accuracyRate * 100).round();
    final mistakeRatePct = (stats.errorRate * 100).round();

    return Card(
      key: const Key('progress_coverage_card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.catalogCoverageHeader,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    tileKey: const Key('coverage_mastered_count'),
                    value: '${stats.correctQuestions}',
                    label: '✓ ${s.masteredLabel}',
                    backgroundColor: semantic.correctSurface,
                    textColor: semantic.correctText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    tileKey: const Key('coverage_mistakes_count'),
                    value: '${stats.wrongQuestions}',
                    label: '✗ ${s.mistakesLabel}',
                    backgroundColor: semantic.wrongSurface,
                    textColor: semantic.wrongText,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MetricTile(
                    tileKey: const Key('coverage_unseen_count'),
                    value: '${stats.unseenQuestions}',
                    label: '○ ${s.unseenLabel}',
                    backgroundColor: scheme.surfaceContainerHighest,
                    textColor: scheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            StackedCoverageBar(stats: stats, height: 12),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  s.overallAccuracy(accuracyPct, stats.totalAttempts),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (stats.totalAttempts > 0)
                  Text(
                    s.errorRateBadge(mistakeRatePct),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: mistakeRatePct > 15
                          ? semantic.wrongBorder
                          : scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.tileKey,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final Key tileKey;
  final String value;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: tileKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeakTopicCard extends StatelessWidget {
  const _WeakTopicCard({
    super.key,
    required this.item,
    required this.controller,
    required this.onTrain,
  });

  final TopicTrainingNeed item;
  final AppController controller;
  final VoidCallback onTrain;

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final semantic = SemanticColors.of(context);
    final errPct = (item.stats.errorRate * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.theme.themeCode}  ${item.theme.themeName}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: errPct > 0
                              ? semantic.wrongSurface
                              : semantic.correctSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          s.errorRateBadge(errPct),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: errPct > 0
                                ? semantic.wrongText
                                : semantic.correctText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: Key('drill_weak_topic_${item.theme.themeCode}'),
                  onPressed: onTrain,
                  child: Text(s.navTrain),
                ),
              ],
            ),
            const SizedBox(height: 10),
            StackedCoverageBar(stats: item.stats, height: 7),
          ],
        ),
      ),
    );
  }
}

class _ExposureRow extends StatelessWidget {
  const _ExposureRow({
    required this.rowKey,
    this.buttonKey,
    required this.label,
    required this.subtitle,
    required this.count,
    required this.total,
    this.actionLabel,
    this.onAction,
  });

  final Key rowKey;
  final Key? buttonKey;
  final String label;
  final String subtitle;
  final int count;
  final int total;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ratio = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      key: rowKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$count / $total',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null)
              FilledButton.tonal(
                key: buttonKey,
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
