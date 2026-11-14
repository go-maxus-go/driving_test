import 'package:material_ui/material_ui.dart';

import '../models/answer_evaluation.dart';
import '../models/question.dart';
import '../services/exam_engine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_card.dart';
import 'home_screen.dart';

class ExamVerdictScreen extends StatefulWidget {
  const ExamVerdictScreen({
    super.key,
    required this.controller,
    required this.result,
    required this.onPracticeMistakes,
    required this.onStartNewExam,
  });

  final AppController controller;
  final ExamResultRecord result;
  final ValueChanged<PracticeLaunchRequest> onPracticeMistakes;
  final VoidCallback onStartNewExam;

  @override
  State<ExamVerdictScreen> createState() => _ExamVerdictScreenState();
}

class _ExamVerdictScreenState extends State<ExamVerdictScreen> {
  bool _wrongOnly = true;
  final Set<String> _expandedQuestionIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.result.wrongQuestionIds.isEmpty) {
      _wrongOnly = false;
    } else {
      // Auto-expand the first mistake so the learner sees why immediately
      _expandedQuestionIds.add(widget.result.wrongQuestionIds.first);
    }
  }

  String _formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '${mins}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;
        final res = widget.result;
        final semantic = SemanticColors.of(context);
        final scheme = Theme.of(context).colorScheme;

        final shownIds = _wrongOnly ? res.wrongQuestionIds : res.questionIds;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              key: const Key('close_verdict_btn'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
            title: Text(
              s.isDe ? 'Prüfungsergebnis' : 'Exam Result',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              TextButton.icon(
                key: const Key('verdict_new_exam_btn'),
                onPressed: widget.onStartNewExam,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(s.newExamButton),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Container(
                    key: const Key('exam_verdict_banner'),
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: res.passed
                          ? semantic.correctSurface
                          : semantic.wrongSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: res.passed
                            ? semantic.correctBorder
                            : semantic.wrongBorder,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          res.passed
                              ? Icons.verified_rounded
                              : Icons.cancel_rounded,
                          size: 52,
                          color: res.passed
                              ? semantic.correctBorder
                              : semantic.wrongBorder,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          res.passed ? s.examPassed : s.examFailed,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: res.passed
                                ? semantic.correctText
                                : semantic.wrongText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.errorPointsSummary(res.totalErrorPoints),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: res.passed
                                ? semantic.correctText
                                : semantic.wrongText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (res.totalErrorPoints / 15.0).clamp(
                              0.0,
                              1.0,
                            ),
                            minHeight: 10,
                            backgroundColor: Colors.black12,
                            color: res.passed
                                ? semantic.correctBorder
                                : semantic.wrongBorder,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 14,
                          runSpacing: 6,
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              '✓ ${res.correctCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '✗ ${res.wrongCount}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '⏱ ${_formatDuration(res.durationSeconds)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          res.failedByTwoFivePointRule
                              ? s.twoFivePointFailWarning
                              : s.fivePointRuleOk,
                          key: const Key('five_point_rule_status'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: res.failedByTwoFivePointRule
                                ? semantic.wrongText
                                : semantic.correctText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (res.wrongQuestionIds.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      key: const Key('practice_exam_mistakes_btn'),
                      onPressed: () {
                        widget.onPracticeMistakes(
                          PracticeLaunchRequest(
                            title: s.drillMostMistakes,
                            questionIds: res.wrongQuestionIds,
                          ),
                        );
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text(
                        s.practiceExamMistakes(res.wrongQuestionIds.length),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            s.isDe ? 'AUFSCHLÜSSELUNG' : 'SECTION BREAKDOWN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                s.filterGrundstoff,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${res.basicCorrectCount}/${res.basicTotalCount} ✓  •  ${res.basicErrorPoints} ${s.isDe ? "Fehlerpkt." : "Error Pts"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                s.filterZusatzstoff,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${res.classBCorrectCount}/${res.classBTotalCount} ✓  •  ${res.classBErrorPoints} ${s.isDe ? "Fehlerpkt." : "Error Pts"}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        key: const Key('verdict_filter_wrong'),
                        label: Text(
                          '${s.reviewWrongOnly} (${res.wrongQuestionIds.length})',
                        ),
                        selected: _wrongOnly,
                        onSelected: (_) => setState(() => _wrongOnly = true),
                      ),
                      ChoiceChip(
                        key: const Key('verdict_filter_all'),
                        label: Text(s.reviewAll30),
                        selected: !_wrongOnly,
                        onSelected: (_) => setState(() => _wrongOnly = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (final qid in shownIds) ...[
                    _buildReviewItem(context, qid),
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

  Widget _buildReviewItem(BuildContext context, String questionId) {
    final q = widget.controller.questionById(questionId);
    if (q == null) return const SizedBox.shrink();

    final s = widget.controller.strings;
    final semantic = SemanticColors.of(context);
    final indexInExam = widget.result.questionIds.indexOf(questionId) + 1;
    final submission =
        widget.result.submissions[questionId] ?? const AnswerSubmission();
    final eval = AnswerEvaluator.evaluate(q, submission);
    final expanded = _expandedQuestionIds.contains(questionId);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: Key('verdict_item_$questionId'),
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                if (!_expandedQuestionIds.remove(questionId)) {
                  _expandedQuestionIds.add(questionId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    eval.isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: eval.isCorrect
                        ? semantic.correctBorder
                        : semantic.wrongBorder,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q$indexInExam • [${s.pointsBadge(q.points)}] • ${q.themeName}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          q.questionText,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 16),
                  if (q.inputKind == QuestionInputKind.multipleChoice)
                    for (var i = 0; i < q.options.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      AnswerOptionCard(
                        option: q.options[i],
                        isSelected: submission.selectedLetters.contains(
                          q.options[i].letter,
                        ),
                        strings: s,
                        feedbackState: eval.optionStates[q.options[i].letter],
                      ),
                    ]
                  else ...[
                    Text(
                      '${s.yourNumericAnswer(submission.numericText.isEmpty ? "—" : submission.numericText)}   •   ${s.correctNumericAnswer(q.correctNumericAnswer ?? "")}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  if (q.comment.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        q.comment,
                        style: const TextStyle(fontSize: 13.5, height: 1.4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
