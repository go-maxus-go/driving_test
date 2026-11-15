import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/answer_evaluation.dart';
import '../models/question.dart';
import '../services/exam_engine.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_card.dart';
import '../widgets/media_cache_scope.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/question_media_stage.dart';
import 'exam_verdict_screen.dart';
import 'home_screen.dart';

class ExamPlayerScreen extends StatefulWidget {
  const ExamPlayerScreen({
    super.key,
    required this.controller,
    this.onPracticeMistakes,
    this.enableNativeVideo = true,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest>? onPracticeMistakes;
  final bool enableNativeVideo;

  @override
  State<ExamPlayerScreen> createState() => _ExamPlayerScreenState();
}

class _ExamPlayerScreenState extends State<ExamPlayerScreen> {
  Timer? _countdownTimer;
  bool _hideTimerDigits = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final exam = widget.controller.activeExam;
      if (exam == null || !mounted || _submitting) return;
      final next = exam.remainingSeconds - 1;
      widget.controller.tickExamTimer(next);
      if (next <= 300 && _hideTimerDigits) {
        _hideTimerDigits = false;
      }
      if (next <= 0) {
        _finalizeAndNavigateToVerdict();
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatClock(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _toggleMcOption(Question q, String letter) async {
    final exam = widget.controller.activeExam;
    if (exam == null) return;
    final prev = exam.submissions[q.questionId] ?? const AnswerSubmission();
    final updated = Set<String>.from(prev.selectedLetters);
    if (!updated.remove(letter)) {
      updated.add(letter);
    }
    await widget.controller.updateExamSubmission(
      q.questionId,
      AnswerSubmission(selectedLetters: updated),
    );
  }

  Future<void> _updateNumeric(Question q, String val) async {
    await widget.controller.updateExamSubmission(
      q.questionId,
      AnswerSubmission(numericText: val),
    );
  }

  Future<void> _requestSubmitExam() async {
    final exam = widget.controller.activeExam;
    if (exam == null) return;
    final unanswered = exam.unansweredIndices(
      widget.controller.currentQuestionsById,
    );

    if (unanswered.isEmpty) {
      await _finalizeAndNavigateToVerdict();
      return;
    }

    final s = widget.controller.strings;
    final firstTargetIdx = unanswered.first;

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.unansweredWarningTitle(unanswered.length, 0),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              if (firstTargetIdx >= 0) ...[
                FilledButton.tonal(
                  key: const Key('jump_to_open_question_btn'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    widget.controller.setExamIndex(firstTargetIdx);
                  },
                  child: Text(s.jumpToQuestion(firstTargetIdx + 1)),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton(
                key: const Key('confirm_submit_exam_anyway_btn'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _finalizeAndNavigateToVerdict();
                },
                child: Text(s.submitAnyway),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finalizeAndNavigateToVerdict() async {
    if (_submitting) return;
    _submitting = true;
    _countdownTimer?.cancel();
    final result = await widget.controller.submitActiveExam();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (verdictCtx) => ExamVerdictScreen(
          controller: widget.controller,
          result: result,
          onRetryExam: () async {
            await widget.controller.retryExam(result.questionIds);
            if (!verdictCtx.mounted) return;
            Navigator.of(verdictCtx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => ExamPlayerScreen(
                  controller: widget.controller,
                  onPracticeMistakes: widget.onPracticeMistakes,
                  enableNativeVideo: widget.enableNativeVideo,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _promptPauseOrDiscard() async {
    final s = widget.controller.strings;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.pauseExamTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                key: const Key('pause_and_save_exam_btn'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.pause_circle_outline_rounded),
                label: Text(s.pauseAndSave),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const Key('discard_exam_btn'),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await widget.controller.discardActiveExam();
                  if (mounted) Navigator.of(context).pop();
                },
                icon: const Icon(Icons.delete_outline_rounded),
                label: Text(s.discardExam),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNavigatorGrid(ActiveExamSession exam) {
    final s = widget.controller.strings;
    final byId = widget.controller.currentQuestionsById;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.questionOverviewTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < exam.questionIds.length; i++)
                    Builder(
                      builder: (_) {
                        final qid = exam.questionIds[i];
                        final q = byId[qid];
                        final answered =
                            q != null &&
                            (exam.submissions[qid]?.isAnsweredFor(q) ?? false);
                        final current = exam.currentIndex == i;

                        return InkWell(
                          key: Key('exam_grid_item_${i + 1}'),
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            widget.controller.setExamIndex(i);
                          },
                          child: Container(
                            width: 46,
                            height: 42,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: answered
                                  ? Theme.of(ctx).colorScheme.primaryContainer
                                  : Theme.of(ctx)
                                        .colorScheme
                                        .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: current
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MediaCacheScope(
      cache: widget.controller.mediaCache,
      child: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final exam = widget.controller.activeExam;
          final s = widget.controller.strings;
          if (exam == null) {
            return const Scaffold(body: SizedBox.shrink());
          }

          final q = widget.controller.questionById(exam.currentQuestionId);
          if (q == null) {
            return const Scaffold(body: SizedBox.shrink());
          }

          if (exam.currentIndex + 1 < exam.questionIds.length) {
            final nextQ = widget.controller.questionById(
              exam.questionIds[exam.currentIndex + 1],
            );
            if (nextQ != null) {
              widget.controller.mediaCache.prefetchQuestionMedia(
                nextQ,
                highPriority: false,
              );
            }
          }

          final semantic = SemanticColors.of(context);

          final isVideoPhaseOne =
              q.mediaKind == QuestionMediaKind.video &&
              !exam.isVideoLocked(q.questionId);
          final isFreezeFrame =
              q.mediaKind == QuestionMediaKind.video &&
              exam.isVideoLocked(q.questionId);

          final submission =
              exam.submissions[q.questionId] ?? const AnswerSubmission();
          final isLastQuestion =
              exam.currentIndex + 1 >= exam.questionIds.length;
          final lowTime = exam.remainingSeconds <= 300;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: const Key('exit_exam_btn'),
                onPressed: _promptPauseOrDiscard,
                icon: const Icon(Icons.close_rounded),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  InkWell(
                    key: const Key('exam_timer_pill'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        setState(() => _hideTimerDigits = !_hideTimerDigits),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 18,
                            color: lowTime ? semantic.wrongBorder : null,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _hideTimerDigits
                                ? '••:••'
                                : _formatClock(exam.remainingSeconds),
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: lowTime ? semantic.wrongBorder : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Q ${exam.currentIndex + 1}/${exam.questionIds.length}',
                    key: const Key('exam_question_counter'),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  key: const Key('open_exam_grid_btn'),
                  tooltip: s.questionOverviewTitle,
                  onPressed: () => _openNavigatorGrid(exam),
                  icon: const Icon(Icons.apps_rounded),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilledButton.tonal(
                    key: const Key('header_submit_exam_btn'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: _requestSubmitExam,
                    child: Text(
                      s.submitExam,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value:
                      exam.countAnswered(
                        widget.controller.currentQuestionsById,
                      ) /
                      exam.questionIds.length,
                  minHeight: 4,
                ),
              ),
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 780),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      QuestionMediaStage(
                        question: q,
                        strings: s,
                        mediaCache: widget.controller.mediaCache,
                        isExamVideoPhaseOne: isVideoPhaseOne,
                        isVideoLockedToFreezeFrame: isFreezeFrame,
                        examPlaysRemaining: exam.playsRemainingFor(
                          q.questionId,
                        ),
                        onExamVideoPlayStarted: () =>
                            widget.controller.recordExamVideoPlay(q.questionId),
                        enableNativeVideo: widget.enableNativeVideo,
                      ),
                      if (!isVideoPhaseOne) ...[
                        if (q.mediaKind == QuestionMediaKind.staticImage ||
                            isFreezeFrame)
                          const SizedBox(height: 14),
                        Text(
                          q.questionText,
                          style: const TextStyle(
                            fontSize: 18.5,
                            height: 1.35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (q.inputKind == QuestionInputKind.multipleChoice)
                          for (var i = 0; i < q.options.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            AnswerOptionCard(
                              option: q.options[i],
                              isSelected: submission.selectedLetters.contains(
                                q.options[i].letter,
                              ),
                              strings: s,
                              onTap: () =>
                                  _toggleMcOption(q, q.options[i].letter),
                            ),
                          ]
                        else
                          ErgonomicNumericKeypad(
                            value: submission.numericText,
                            strings: s,
                            onChanged: (val) => _updateNumeric(q, val),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).appBarTheme.backgroundColor,
                  border: Border(top: BorderSide(color: semantic.subtleBorder)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Align(
                  heightFactor: 1.0,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 780),
                    child: isVideoPhaseOne
                        ? FilledButton.icon(
                            key: const Key('reveal_exam_video_question_btn'),
                            onPressed: () => widget.controller
                                .lockExamVideoAndRevealQuestion(q.questionId),
                            icon: const Icon(Icons.visibility_rounded),
                            label: Text(s.showQuestionAndAnswers),
                          )
                        : Row(
                            children: [
                              OutlinedButton.icon(
                                key: const Key('exam_prev_btn'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: exam.currentIndex > 0
                                    ? () => widget.controller.setExamIndex(
                                        exam.currentIndex - 1,
                                      )
                                    : null,
                                icon: const Icon(Icons.arrow_back_rounded),
                                label: Text(s.prevQuestion),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton.icon(
                                  key: const Key('exam_next_or_submit_btn'),
                                  onPressed: isLastQuestion
                                      ? _requestSubmitExam
                                      : () => widget.controller.setExamIndex(
                                          exam.currentIndex + 1,
                                        ),
                                  icon: Icon(
                                    isLastQuestion
                                        ? Icons.task_alt_rounded
                                        : Icons.arrow_forward_rounded,
                                  ),
                                  label: Text(
                                    isLastQuestion
                                        ? s.finishAndGradeExam
                                        : s.nextQuestion,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
