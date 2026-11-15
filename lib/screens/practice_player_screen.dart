import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../models/answer_evaluation.dart';
import '../models/question.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_option_card.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/question_media_stage.dart';
import 'home_screen.dart';

class PracticePlayerScreen extends StatefulWidget {
  const PracticePlayerScreen({
    super.key,
    required this.controller,
    required this.request,
    this.enableNativeVideo = true,
  });

  final AppController controller;
  final PracticeLaunchRequest request;
  final bool enableNativeVideo;

  @override
  State<PracticePlayerScreen> createState() => _PracticePlayerScreenState();
}

class _PracticePlayerScreenState extends State<PracticePlayerScreen> {
  late List<String> _queueIds;
  int _currentIndex = 0;

  Set<String> _selectedLetters = <String>{};
  String _numericValue = '';
  AnswerEvaluation? _evaluation;
  bool _sessionFinished = false;

  int _sessionCorrect = 0;
  int _sessionWrong = 0;
  final List<String> _sessionMistakeIds = <String>[];

  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _queueIds = List<String>.from(widget.request.questionIds);
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Question? get _currentQuestion {
    if (_queueIds.isEmpty || _currentIndex >= _queueIds.length) return null;
    return widget.controller.questionById(_queueIds[_currentIndex]);
  }

  bool get _canSubmit {
    final q = _currentQuestion;
    if (q == null || _evaluation != null) return false;
    if (q.inputKind == QuestionInputKind.numericInput) {
      return _numericValue.trim().isNotEmpty;
    }
    return _selectedLetters.isNotEmpty;
  }

  void _toggleOption(String letter) {
    if (_evaluation != null) return;
    HapticFeedback.selectionClick();
    setState(() {
      final next = Set<String>.from(_selectedLetters);
      if (!next.remove(letter)) {
        next.add(letter);
      }
      _selectedLetters = next;
    });
  }

  Future<void> _submitAnswer() async {
    final q = _currentQuestion;
    if (q == null || !_canSubmit) return;

    final eval = await widget.controller.recordPracticeAnswer(
      question: q,
      submission: AnswerSubmission(
        selectedLetters: _selectedLetters,
        numericText: _numericValue,
      ),
    );

    if (!mounted) return;
    setState(() {
      _evaluation = eval;
      if (eval.isCorrect) {
        _sessionCorrect++;
      } else {
        _sessionWrong++;
        if (!_sessionMistakeIds.contains(q.questionId)) {
          _sessionMistakeIds.add(q.questionId);
        }
      }
    });
  }

  void _advanceToNext() {
    if (_currentIndex + 1 >= _queueIds.length) {
      setState(() {
        _sessionFinished = true;
      });
      return;
    }
    setState(() {
      _currentIndex++;
      _resetQuestionState();
    });
  }

  void _skipCurrentQuestion() {
    if (_evaluation != null) return;
    if (_currentIndex + 1 >= _queueIds.length) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _currentIndex++;
      _resetQuestionState();
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _resetQuestionState();
      });
    }
  }

  void _retryCurrentQuestion() {
    setState(() {
      _resetQuestionState();
    });
  }

  void _resetQuestionState() {
    _selectedLetters = <String>{};
    _numericValue = '';
    _evaluation = null;
  }

  void _restartWithIds(List<String> newIds) {
    setState(() {
      _queueIds = List<String>.from(newIds);
      _currentIndex = 0;
      _sessionCorrect = 0;
      _sessionWrong = 0;
      _sessionMistakeIds.clear();
      _sessionFinished = false;
      _resetQuestionState();
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _sessionFinished) {
      return KeyEventResult.ignored;
    }
    final q = _currentQuestion;
    if (q == null) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_evaluation != null) {
        _advanceToNext();
        return KeyEventResult.handled;
      } else if (_canSubmit) {
        _submitAnswer();
        return KeyEventResult.handled;
      }
    }

    if (key == LogicalKeyboardKey.keyB) {
      widget.controller.toggleBookmark(q.questionId);
      return KeyEventResult.handled;
    }

    if (_evaluation == null) {
      if (q.inputKind == QuestionInputKind.multipleChoice) {
        int? optIdx;
        if (key == LogicalKeyboardKey.digit1 ||
            key == LogicalKeyboardKey.keyA) {
          optIdx = 0;
        } else if (key == LogicalKeyboardKey.digit2 ||
            key == LogicalKeyboardKey.keyB) {
          optIdx = 1;
        } else if (key == LogicalKeyboardKey.digit3 ||
            key == LogicalKeyboardKey.keyC) {
          optIdx = 2;
        }
        if (optIdx != null && optIdx < q.options.length) {
          _toggleOption(q.options[optIdx].letter);
          return KeyEventResult.handled;
        }
      } else {
        final ch = event.character;
        if (ch != null && RegExp(r'^[0-9.,]$').hasMatch(ch)) {
          if ((ch == '.' || ch == ',') &&
              (_numericValue.contains('.') || _numericValue.contains(','))) {
            return KeyEventResult.handled;
          }
          if (_numericValue.length < 6) {
            setState(() => _numericValue = '$_numericValue$ch');
          }
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.backspace && _numericValue.isNotEmpty) {
          setState(
            () => _numericValue = _numericValue.substring(
              0,
              _numericValue.length - 1,
            ),
          );
          return KeyEventResult.handled;
        }
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;
        if (_sessionFinished) {
          return _SessionCompleteScreen(
            strings: s,
            correctCount: _sessionCorrect,
            wrongCount: _sessionWrong,
            mistakeIds: _sessionMistakeIds,
            canContinueSmartBatch: widget.request.allowContinueSmartBatch,
            onRetryMistakes: () => _restartWithIds(_sessionMistakeIds),
            onContinueSmartBatch: () =>
                _restartWithIds(widget.controller.buildSmartPracticeQueue()),
            onClose: () => Navigator.of(context).pop(),
          );
        }

        final q = _currentQuestion;
        if (q == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(s.noQuestionsInDrill)),
          );
        }

        final answeredInRun = _evaluation != null
            ? _currentIndex + 1
            : _currentIndex;
        final remainingCount = (_queueIds.length - answeredInRun).clamp(
          0,
          _queueIds.length,
        );
        final semantic = SemanticColors.of(context);
        final scheme = Theme.of(context).colorScheme;
        final isWide = MediaQuery.sizeOf(context).width >= 880;
        final hasDedicatedMediaPane =
            isWide &&
            (q.mediaKind == QuestionMediaKind.staticImage ||
                q.mediaKind == QuestionMediaKind.video);

        final mediaWidget = QuestionMediaStage(
          question: q,
          strings: s,
          allowVideoScrubbing: _evaluation != null,
          enableNativeVideo: widget.enableNativeVideo,
        );

        final questionAndAnswersColumn = _buildQuestionAndAnswersColumn(
          context,
          q,
          includeMediaInline: !hasDedicatedMediaPane,
          mediaWidget: mediaWidget,
        );

        return Focus(
          focusNode: _keyboardFocusNode,
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                key: const Key('close_practice_btn'),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
              titleSpacing: 0,
              title: _LiveSessionCounterPill(
                correct: _sessionCorrect,
                wrong: _sessionWrong,
                remaining: remainingCount,
                leftLabel: s.leftLabel,
              ),
              actions: [
                _PointsPill(points: q.points, label: s.pointsBadge(q.points)),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('bookmark_question_btn'),
                  tooltip: s.bookmarkTooltip,
                  onPressed: () =>
                      widget.controller.toggleBookmark(q.questionId),
                  icon: Icon(
                    widget.controller.isBookmarked(q.questionId)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: widget.controller.isBookmarked(q.questionId)
                        ? semantic.missedBorder
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _queueIds.isEmpty
                      ? 0
                      : (_currentIndex + 1) / _queueIds.length,
                  minHeight: 3,
                ),
              ),
            ),
            body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: hasDedicatedMediaPane ? 1140 : 760,
                ),
                child: hasDedicatedMediaPane
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: mediaWidget),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 13,
                              child: SingleChildScrollView(
                                child: questionAndAnswersColumn,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: questionAndAnswersColumn,
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
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (_currentIndex > 0) ...[
                              IconButton.outlined(
                                key: const Key('prev_question_btn'),
                                tooltip: s.prevQuestion,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(48, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _goToPrevious,
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (_evaluation == null) ...[
                              IconButton.outlined(
                                key: const Key('skip_question_btn'),
                                tooltip: s.skipQuestion,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(48, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _skipCurrentQuestion,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  key: const Key('primary_practice_cta'),
                                  onPressed: _canSubmit ? _submitAnswer : null,
                                  child: Text(s.checkAnswer),
                                ),
                              ),
                            ] else ...[
                              IconButton.outlined(
                                key: const Key('retry_question_btn'),
                                tooltip: s.retryQuestion,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(48, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: _retryCurrentQuestion,
                                icon: const Icon(
                                  Icons.replay_rounded,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  key: const Key('primary_practice_cta'),
                                  onPressed: _advanceToNext,
                                  child: Text(
                                    _currentIndex + 1 >= _queueIds.length
                                        ? s.finishSession
                                        : s.nextQuestion,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isWide) ...[
                          const SizedBox(height: 6),
                          Text(
                            s.keyboardShortcutsHint,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionAndAnswersColumn(
    BuildContext context,
    Question q, {
    required bool includeMediaInline,
    required Widget mediaWidget,
  }) {
    final s = widget.controller.strings;
    final scheme = Theme.of(context).colorScheme;
    final semantic = SemanticColors.of(context);
    final eval = _evaluation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (includeMediaInline &&
            (q.mediaKind == QuestionMediaKind.staticImage ||
                q.mediaKind == QuestionMediaKind.video)) ...[
          mediaWidget,
          const SizedBox(height: 14),
        ],
        Text(
          '${q.questionId} • ${q.themeName}',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          q.questionText,
          style: TextStyle(
            fontSize: q.mediaKind == QuestionMediaKind.none ? 20 : 18,
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
              isSelected: _selectedLetters.contains(q.options[i].letter),
              strings: s,
              feedbackState: eval?.optionStates[q.options[i].letter],
              onTap: eval == null
                  ? () => _toggleOption(q.options[i].letter)
                  : null,
            ),
          ]
        else
          ErgonomicNumericKeypad(
            value: _numericValue,
            strings: s,
            isSubmitted: eval != null,
            isCorrect: eval?.isCorrect ?? false,
            expectedAnswer: q.correctNumericAnswer,
            onChanged: (val) => setState(() => _numericValue = val),
          ),
        if (eval != null && q.comment.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            key: const Key('explanation_card'),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: semantic.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      size: 19,
                      color: semantic.missedBorder,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.explanationTitle,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  q.comment,
                  style: const TextStyle(fontSize: 14.5, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _LiveSessionCounterPill extends StatelessWidget {
  const _LiveSessionCounterPill({
    required this.correct,
    required this.wrong,
    required this.remaining,
    required this.leftLabel,
  });

  final int correct;
  final int wrong;
  final int remaining;
  final String leftLabel;

  @override
  Widget build(BuildContext context) {
    final semantic = SemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('live_session_counter_pill'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: semantic.correctBorder,
          ),
          const SizedBox(width: 4),
          Text(
            '$correct',
            key: const Key('session_correct_count'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Icon(Icons.cancel_rounded, size: 15, color: semantic.wrongBorder),
          const SizedBox(width: 4),
          Text(
            '$wrong',
            key: const Key('session_wrong_count'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '$remaining $leftLabel',
              key: const Key('session_remaining_count'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PointsPill extends StatelessWidget {
  const _PointsPill({required this.points, required this.label});

  final int points;
  final String label;

  @override
  Widget build(BuildContext context) {
    final semantic = SemanticColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isFive = points >= 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: isFive
            ? semantic.missedSurface
            : scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: isFive ? Border.all(color: semantic.missedBorder) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isFive ? semantic.missedText : scheme.onSurface,
        ),
      ),
    );
  }
}

class _SessionCompleteScreen extends StatelessWidget {
  const _SessionCompleteScreen({
    required this.strings,
    required this.correctCount,
    required this.wrongCount,
    required this.mistakeIds,
    required this.canContinueSmartBatch,
    required this.onRetryMistakes,
    required this.onContinueSmartBatch,
    required this.onClose,
  });

  final AppStrings strings;
  final int correctCount;
  final int wrongCount;
  final List<String> mistakeIds;
  final bool canContinueSmartBatch;
  final VoidCallback onRetryMistakes;
  final VoidCallback onContinueSmartBatch;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final total = correctCount + wrongCount;
    final pct = total == 0 ? 100 : ((correctCount / total) * 100).round();
    final semantic = SemanticColors.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      wrongCount == 0
                          ? Icons.emoji_events_rounded
                          : Icons.fact_check_rounded,
                      size: 52,
                      color: wrongCount == 0
                          ? semantic.correctBorder
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      strings.sessionCompleteTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$pct%  •  ✓ $correctCount   ✗ $wrongCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (mistakeIds.isNotEmpty) ...[
                      FilledButton.icon(
                        key: const Key('retry_session_mistakes_btn'),
                        onPressed: onRetryMistakes,
                        icon: const Icon(Icons.replay_rounded),
                        label: Text(
                          '${strings.retrySessionMistakes} (${mistakeIds.length})',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (canContinueSmartBatch) ...[
                      FilledButton.tonal(
                        key: const Key('continue_practice_btn'),
                        onPressed: onContinueSmartBatch,
                        child: Text(strings.continueMoreQuestions),
                      ),
                      const SizedBox(height: 10),
                    ],
                    OutlinedButton(
                      key: const Key('back_to_menu_btn'),
                      onPressed: onClose,
                      child: Text(strings.backToMenu),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
