import 'package:material_ui/material_ui.dart';

import '../services/exam_engine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import 'exam_verdict_screen.dart';
import 'home_screen.dart';

class MockExamHistoryScreen extends StatelessWidget {
  const MockExamHistoryScreen({
    super.key,
    required this.controller,
    required this.onStartPractice,
    required this.onStartExam,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest> onStartPractice;
  final VoidCallback onStartExam;

  String _formatDate(int timestampMs) {
    if (timestampMs <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day.$month.$year  $hour:$min';
  }

  void _openVerdict(BuildContext context, ExamResultRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (verdictContext) => ExamVerdictScreen(
          controller: controller,
          result: record,
          onRetryExam: () async {
            await controller.retryExam(record.questionIds);
            if (!verdictContext.mounted) return;
            Navigator.of(verdictContext).pop();
            if (!context.mounted) return;
            Navigator.of(context).pop();
            onStartExam();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.strings;
        final exams = controller.examHistory;
        final scheme = Theme.of(context).colorScheme;
        final semantic = SemanticColors.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              s.mockExamHistoryTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: exams.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 64,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              s.noMockExamsYet,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              key: const Key('history_start_first_exam_btn'),
                              onPressed: () async {
                                await controller.startNewExam();
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                onStartExam();
                              },
                              icon: const Icon(Icons.timer_outlined),
                              label: Text(s.beginLabel),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      children: [
                        for (var i = 0; i < exams.length; i++) ...[
                          Card(
                            key: Key('past_exam_card_$i'),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openVerdict(context, exams[i]),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: exams[i].passed
                                            ? semantic.correctSurface
                                            : semantic.wrongSurface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        exams[i].passed
                                            ? Icons.check_circle_rounded
                                            : Icons.cancel_rounded,
                                        color: exams[i].passed
                                            ? semantic.correctText
                                            : semantic.wrongText,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${exams[i].passed ? (s.isDe ? "Bestanden" : "Passed") : (s.isDe ? "Nicht bestanden" : "Failed")} • ${exams[i].totalErrorPoints} / 10 ${s.isDe ? "Pkt." : "Pts"}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            '${_formatDate(exams[i].completedAtMs)} • ✓ ${exams[i].correctCount}  ✗ ${exams[i].wrongCount}',
                                            style: TextStyle(
                                              fontSize: 12.5,
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
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
