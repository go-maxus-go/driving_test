import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../models/user_progress.dart';
import '../services/exam_engine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/coverage_bar.dart';
import 'exam_verdict_screen.dart';
import 'home_screen.dart';

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

  void _openPastExamVerdict(BuildContext context, ExamResultRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (verdictContext) => ExamVerdictScreen(
          controller: controller,
          result: record,
          onPracticeMistakes: (req) {
            Navigator.of(verdictContext).pop();
            onStartPractice(req);
          },
          onStartNewExam: () {
            Navigator.of(verdictContext).pop();
            onStartExam();
          },
        ),
      ),
    );
  }

  void _launchExposureBucket({
    required BuildContext context,
    required String title,
    required List<String> questionIds,
  }) {
    if (questionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _showBackupAndResetSheet(BuildContext context) async {
    final exportedJson = controller.exportBackupJson();
    final importCtrl = TextEditingController();
    String? importError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final s = controller.strings;
            final scheme = Theme.of(sheetContext).colorScheme;
            final semantic = SemanticColors.of(sheetContext);
            final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + viewInsets),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.exportProgressTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 110),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.55,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          exportedJson,
                          key: const Key('exported_backup_json_preview'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.tonalIcon(
                      key: const Key('copy_backup_json_btn'),
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: exportedJson),
                        );
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              s.isDe
                                  ? 'Backup-JSON in die Zwischenablage kopiert.'
                                  : 'Backup JSON copied to clipboard.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(s.copyToClipboard),
                    ),
                    const Divider(height: 28),
                    Text(
                      s.importProgressTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      key: const Key('import_backup_json_input'),
                      controller: importCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: '{"version": 1, ...}',
                        errorText: importError,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      key: const Key('confirm_import_backup_btn'),
                      onPressed: () async {
                        final ok = await controller.importBackupJson(
                          importCtrl.text.trim(),
                        );
                        if (!sheetContext.mounted) return;
                        if (ok) {
                          Navigator.of(sheetContext).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                controller.strings.isDe
                                    ? 'Fortschritt erfolgreich wiederhergestellt!'
                                    : 'Progress backup restored successfully!',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } else {
                          setSheetState(() {
                            importError = s.isDe
                                ? 'Ungültiges Backup-JSON.'
                                : 'Invalid backup JSON format.';
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(s.importButton),
                    ),
                    const Divider(height: 28),
                    OutlinedButton.icon(
                      key: const Key('reset_all_progress_btn'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: semantic.wrongBorder,
                        side: BorderSide(color: semantic.wrongBorder),
                      ),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: sheetContext,
                          builder: (dlgContext) => AlertDialog(
                            title: Text(s.resetProgressTitle),
                            content: Text(s.resetConfirmBody),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dlgContext).pop(false),
                                child: Text(s.cancelSelection),
                              ),
                              FilledButton(
                                key: const Key('confirm_reset_progress_btn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: semantic.wrongBorder,
                                ),
                                onPressed: () =>
                                    Navigator.of(dlgContext).pop(true),
                                child: Text(s.resetConfirmAction),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await controller.resetAllProgress();
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_forever_rounded),
                      label: Text(s.resetProgressTitle),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

        final zeroQuestions = controller.currentQuestions
            .where(
              (q) => controller.progressFor(q.questionId).attemptsCount == 0,
            )
            .map((q) => q.questionId)
            .toList(growable: false);
        final onceQuestions = controller.currentQuestions
            .where(
              (q) => controller.progressFor(q.questionId).attemptsCount == 1,
            )
            .map((q) => q.questionId)
            .toList(growable: false);
        final twoPlusCount = controller.exposureCountFor(minAttempts: 2);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              key: const Key('progress_scroll_view'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.navProgress,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          key: const Key('progress_readiness_pill'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
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
                    OutlinedButton.icon(
                      key: const Key('open_backup_reset_btn'),
                      onPressed: () => _showBackupAndResetSheet(context),
                      icon: const Icon(Icons.import_export_rounded, size: 18),
                      label: Text(s.backupExportImport),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _CoverageOverviewCard(stats: stats, controller: controller),
                const SizedBox(height: 20),
                _SectionHeader(title: s.weakTopicsHeader),
                const SizedBox(height: 10),
                if (weakTopics.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        s.noWeakTopicsYet,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  for (final item in weakTopics.take(6)) ...[
                    _WeakTopicCard(
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
                const SizedBox(height: 14),
                _SectionHeader(title: s.mockExamHistoryHeader),
                const SizedBox(height: 10),
                _ExamHistorySection(
                  exams: exams,
                  controller: controller,
                  onSelectExam: (exam) => _openPastExamVerdict(context, exam),
                  onStartExam: onStartExam,
                ),
                const SizedBox(height: 20),
                _SectionHeader(title: s.exposureHeader),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ExposureRow(
                          rowKey: const Key('exposure_row_0'),
                          buttonKey: const Key('exposure_drill_0'),
                          label: s.exposureZero,
                          count: zeroQuestions.length,
                          total: stats.totalQuestions,
                          actionLabel: s.navTrain,
                          onAction: zeroQuestions.isEmpty
                              ? null
                              : () => _launchExposureBucket(
                                  context: context,
                                  title: s.exposureZero,
                                  questionIds: controller
                                      .buildLeastAnsweredQueue(
                                        maxAttemptsExclusive: 1,
                                      ),
                                ),
                        ),
                        const Divider(height: 22),
                        _ExposureRow(
                          rowKey: const Key('exposure_row_1'),
                          buttonKey: const Key('exposure_drill_1'),
                          label: s.exposureOne,
                          count: onceQuestions.length,
                          total: stats.totalQuestions,
                          actionLabel: s.navTrain,
                          onAction: onceQuestions.isEmpty
                              ? null
                              : () => _launchExposureBucket(
                                  context: context,
                                  title: s.exposureOne,
                                  questionIds: onceQuestions,
                                ),
                        ),
                        const Divider(height: 22),
                        _ExposureRow(
                          rowKey: const Key('exposure_row_2plus'),
                          label: s.exposureTwoPlus,
                          count: twoPlusCount,
                          total: stats.totalQuestions,
                        ),
                      ],
                    ),
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
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
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
                          Text(
                            '✓ ${item.stats.correctQuestions}  •  ✗ ${item.stats.wrongQuestions}  •  ○ ${item.stats.unseenQuestions}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: Key('train_weak_topic_${item.theme.themeCode}'),
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

class _ExamHistorySection extends StatelessWidget {
  const _ExamHistorySection({
    required this.exams,
    required this.controller,
    required this.onSelectExam,
    required this.onStartExam,
  });

  final List<ExamResultRecord> exams;
  final AppController controller;
  final ValueChanged<ExamResultRecord> onSelectExam;
  final VoidCallback onStartExam;

  String _formatDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final s = controller.strings;
    final semantic = SemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (exams.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Text(
                s.noExamsTakenYet,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              FilledButton.tonalIcon(
                key: const Key('progress_start_first_exam_btn'),
                onPressed: onStartExam,
                icon: const Icon(Icons.timer_outlined, size: 18),
                label: Text(s.beginLabel),
              ),
            ],
          ),
        ),
      );
    }

    final recentChronological = exams.take(8).toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 88,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < recentChronological.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${recentChronological[i].totalErrorPoints}p',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: recentChronological[i].passed
                                      ? semantic.correctText
                                      : semantic.wrongText,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                height:
                                    12 +
                                    (recentChronological[i].totalErrorPoints
                                            .clamp(0, 20) *
                                        2.6),
                                decoration: BoxDecoration(
                                  color: recentChronological[i].passed
                                      ? semantic.correctBorder
                                      : semantic.wrongBorder,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  s.isDe
                      ? 'Tippe auf eine Prüfung, um alle Fehler und Erklärungen einzusehen.'
                      : 'Tap any completed exam to review its mistakes and explanations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < exams.take(10).length; i++) ...[
          Card(
            child: InkWell(
              key: Key('exam_history_item_$i'),
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelectExam(exams[i]),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      exams[i].passed
                          ? Icons.verified_rounded
                          : Icons.cancel_rounded,
                      color: exams[i].passed
                          ? semantic.correctBorder
                          : semantic.wrongBorder,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${exams[i].passed ? (s.isDe ? "Bestanden" : "Passed") : (s.isDe ? "Nicht bestanden" : "Failed")}  •  ${exams[i].totalErrorPoints} / 10 ${s.isDe ? "Pkt." : "Pts"}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatDate(exams[i].completedAtMs)}  •  ✓ ${exams[i].correctCount}  ✗ ${exams[i].wrongCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ExposureRow extends StatelessWidget {
  const _ExposureRow({
    required this.rowKey,
    this.buttonKey,
    required this.label,
    required this.count,
    required this.total,
    this.actionLabel,
    this.onAction,
  });

  final Key rowKey;
  final Key? buttonKey;
  final String label;
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
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            minHeight: 7,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}
