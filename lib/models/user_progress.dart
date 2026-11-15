enum QuestionStatus { unseen, correct, wrong }

class QuestionProgress {
  const QuestionProgress({
    required this.questionId,
    this.attemptsCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.consecutiveCorrect = 0,
    this.lastAnsweredAtMs = 0,
    this.lastWasCorrect = false,
    this.isBookmarked = false,
  });

  final String questionId;
  final int attemptsCount;
  final int correctCount;
  final int wrongCount;
  final int consecutiveCorrect;
  final int lastAnsweredAtMs;
  final bool lastWasCorrect;
  final bool isBookmarked;

  QuestionStatus get status {
    if (attemptsCount == 0) return QuestionStatus.unseen;
    return lastWasCorrect ? QuestionStatus.correct : QuestionStatus.wrong;
  }

  /// True when the user answered correctly at least 2 consecutive times.
  bool get isLearned => consecutiveCorrect >= 2;

  /// True when the user has attempted the question but hasn't mastered it (2 in a row).
  bool get isInTraining => attemptsCount > 0 && !isLearned;

  /// True when never answered.
  bool get isUnseen => attemptsCount == 0;

  /// True when the learner has ever made a mistake on this question.
  bool get hasHistoricalMistake => wrongCount > 0;

  /// True when the learner got this wrong recently and hasn't yet answered it
  /// right twice in a row.
  bool get needsRecovery =>
      wrongCount > 0 && (!lastWasCorrect || consecutiveCorrect < 2);

  double get mistakeRate =>
      attemptsCount == 0 ? 0.0 : wrongCount / attemptsCount;

  QuestionProgress recordAttempt({
    required bool isCorrect,
    required int timestampMs,
  }) {
    return QuestionProgress(
      questionId: questionId,
      attemptsCount: attemptsCount + 1,
      correctCount: correctCount + (isCorrect ? 1 : 0),
      wrongCount: wrongCount + (isCorrect ? 0 : 1),
      consecutiveCorrect: isCorrect ? consecutiveCorrect + 1 : 0,
      lastAnsweredAtMs: timestampMs,
      lastWasCorrect: isCorrect,
      isBookmarked: isBookmarked,
    );
  }

  QuestionProgress toggleBookmark() {
    return QuestionProgress(
      questionId: questionId,
      attemptsCount: attemptsCount,
      correctCount: correctCount,
      wrongCount: wrongCount,
      consecutiveCorrect: consecutiveCorrect,
      lastAnsweredAtMs: lastAnsweredAtMs,
      lastWasCorrect: lastWasCorrect,
      isBookmarked: !isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': questionId,
    'a': attemptsCount,
    'c': correctCount,
    'w': wrongCount,
    'cc': consecutiveCorrect,
    'ts': lastAnsweredAtMs,
    'ok': lastWasCorrect,
    'bm': isBookmarked,
  };

  factory QuestionProgress.fromJson(Map<String, dynamic> json) {
    return QuestionProgress(
      questionId: json['id'] as String? ?? '',
      attemptsCount: json['a'] as int? ?? 0,
      correctCount: json['c'] as int? ?? 0,
      wrongCount: json['w'] as int? ?? 0,
      consecutiveCorrect: json['cc'] as int? ?? 0,
      lastAnsweredAtMs: json['ts'] as int? ?? 0,
      lastWasCorrect: json['ok'] as bool? ?? false,
      isBookmarked: json['bm'] as bool? ?? false,
    );
  }
}

class CoverageStats {
  const CoverageStats({
    required this.totalQuestions,
    required this.correctQuestions,
    required this.wrongQuestions,
    required this.unseenQuestions,
    this.learnedQuestions = 0,
    this.inTrainingQuestions = 0,
    required this.totalAttempts,
    required this.totalCorrectAttempts,
    required this.totalWrongAttempts,
  });

  final int totalQuestions;
  final int correctQuestions;
  final int wrongQuestions;
  final int unseenQuestions;
  final int learnedQuestions;
  final int inTrainingQuestions;
  final int totalAttempts;
  final int totalCorrectAttempts;
  final int totalWrongAttempts;

  double get accuracyRate =>
      totalAttempts == 0 ? 0.0 : totalCorrectAttempts / totalAttempts;

  double get errorRate =>
      totalAttempts == 0 ? 0.0 : totalWrongAttempts / totalAttempts;

  int get accuracyPercent => (accuracyRate * 100).round();
  int get errorRatePercent => (errorRate * 100).round();

  static CoverageStats compute(
    Iterable<String> questionIds,
    Map<String, QuestionProgress> progressMap,
  ) {
    var total = 0;
    var correct = 0;
    var wrong = 0;
    var unseen = 0;
    var learned = 0;
    var inTraining = 0;
    var attempts = 0;
    var correctAtt = 0;
    var wrongAtt = 0;

    for (final id in questionIds) {
      total++;
      final p = progressMap[id];
      if (p == null || p.attemptsCount == 0) {
        unseen++;
      } else {
        attempts += p.attemptsCount;
        correctAtt += p.correctCount;
        wrongAtt += p.wrongCount;
        if (p.isLearned) {
          learned++;
        } else {
          inTraining++;
        }
        if (p.lastWasCorrect) {
          correct++;
        } else {
          wrong++;
        }
      }
    }

    return CoverageStats(
      totalQuestions: total,
      correctQuestions: correct,
      wrongQuestions: wrong,
      unseenQuestions: unseen,
      learnedQuestions: learned,
      inTrainingQuestions: inTraining,
      totalAttempts: attempts,
      totalCorrectAttempts: correctAtt,
      totalWrongAttempts: wrongAtt,
    );
  }
}
