import 'dart:math';

import '../models/answer_evaluation.dart';
import '../models/question.dart';

class ActiveExamSession {
  ActiveExamSession({
    required this.sessionId,
    required this.questionIds,
    required this.startedAtMs,
    this.remainingSeconds = defaultDurationSeconds,
    this.currentIndex = 0,
    Map<String, AnswerSubmission>? submissions,
    Set<String>? flaggedIds,
    Map<String, int>? videoPlaysUsed,
    Set<String>? videoLockedIds,
  }) : submissions = submissions ?? <String, AnswerSubmission>{},
       flaggedIds = flaggedIds ?? <String>{},
       videoPlaysUsed = videoPlaysUsed ?? <String, int>{},
       videoLockedIds = videoLockedIds ?? <String>{};

  static const int basicQuestionCount = 20;
  static const int classBQuestionCount = 10;
  static const int totalQuestionCount = 30;
  static const int defaultDurationSeconds = 45 * 60;
  static const int maxVideoPlays = 5;
  static const int maxAllowedErrorPoints = 10;

  final String sessionId;
  final List<String> questionIds;
  final int startedAtMs;
  int remainingSeconds;
  int currentIndex;
  final Map<String, AnswerSubmission> submissions;
  final Set<String> flaggedIds;
  final Map<String, int> videoPlaysUsed;
  final Set<String> videoLockedIds;

  String get currentQuestionId => questionIds[currentIndex];

  int playsUsedFor(String questionId) => videoPlaysUsed[questionId] ?? 0;

  int playsRemainingFor(String questionId) =>
      max(0, maxVideoPlays - playsUsedFor(questionId));

  bool isVideoLocked(String questionId) => videoLockedIds.contains(questionId);

  int countAnswered(Map<String, Question> questionsById) {
    var count = 0;
    for (final qid in questionIds) {
      final q = questionsById[qid];
      final sub = submissions[qid];
      if (q != null && sub != null && sub.isAnsweredFor(q)) {
        count++;
      }
    }
    return count;
  }

  List<int> unansweredIndices(Map<String, Question> questionsById) {
    final indices = <int>[];
    for (var i = 0; i < questionIds.length; i++) {
      final qid = questionIds[i];
      final q = questionsById[qid];
      final sub = submissions[qid];
      if (q == null || sub == null || !sub.isAnsweredFor(q)) {
        indices.add(i);
      }
    }
    return indices;
  }

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'questionIds': questionIds,
    'startedAtMs': startedAtMs,
    'remainingSeconds': remainingSeconds,
    'currentIndex': currentIndex,
    'submissions': {
      for (final e in submissions.entries) e.key: e.value.toJson(),
    },
    'flaggedIds': flaggedIds.toList(),
    'videoPlaysUsed': videoPlaysUsed,
    'videoLockedIds': videoLockedIds.toList(),
  };

  factory ActiveExamSession.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['submissions'] as Map<String, dynamic>? ?? const {};
    final rawPlays =
        json['videoPlaysUsed'] as Map<String, dynamic>? ?? const {};
    return ActiveExamSession(
      sessionId: json['sessionId'] as String? ?? 'exam',
      questionIds: (json['questionIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      startedAtMs: json['startedAtMs'] as int? ?? 0,
      remainingSeconds:
          json['remainingSeconds'] as int? ?? defaultDurationSeconds,
      currentIndex: json['currentIndex'] as int? ?? 0,
      submissions: {
        for (final e in rawSubs.entries)
          e.key: AnswerSubmission.fromJson(e.value as Map<String, dynamic>),
      },
      flaggedIds: (json['flaggedIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet(),
      videoPlaysUsed: {
        for (final e in rawPlays.entries) e.key: e.value as int? ?? 0,
      },
      videoLockedIds: (json['videoLockedIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toSet(),
    );
  }
}

class ExamResultRecord {
  const ExamResultRecord({
    required this.examId,
    required this.completedAtMs,
    required this.durationSeconds,
    required this.totalErrorPoints,
    required this.fivePointErrorsCount,
    required this.failedByTwoFivePointRule,
    required this.passed,
    required this.correctCount,
    required this.wrongCount,
    required this.basicCorrectCount,
    required this.basicTotalCount,
    required this.basicErrorPoints,
    required this.classBCorrectCount,
    required this.classBTotalCount,
    required this.classBErrorPoints,
    required this.questionIds,
    required this.submissions,
    required this.wrongQuestionIds,
  });

  final String examId;
  final int completedAtMs;
  final int durationSeconds;
  final int totalErrorPoints;
  final int fivePointErrorsCount;
  final bool failedByTwoFivePointRule;
  final bool passed;
  final int correctCount;
  final int wrongCount;
  final int basicCorrectCount;
  final int basicTotalCount;
  final int basicErrorPoints;
  final int classBCorrectCount;
  final int classBTotalCount;
  final int classBErrorPoints;
  final List<String> questionIds;
  final Map<String, AnswerSubmission> submissions;
  final List<String> wrongQuestionIds;

  Map<String, dynamic> toJson() => {
    'examId': examId,
    'completedAtMs': completedAtMs,
    'durationSeconds': durationSeconds,
    'totalErrorPoints': totalErrorPoints,
    'fivePointErrorsCount': fivePointErrorsCount,
    'failedByTwoFivePointRule': failedByTwoFivePointRule,
    'passed': passed,
    'correctCount': correctCount,
    'wrongCount': wrongCount,
    'basicCorrectCount': basicCorrectCount,
    'basicTotalCount': basicTotalCount,
    'basicErrorPoints': basicErrorPoints,
    'classBCorrectCount': classBCorrectCount,
    'classBTotalCount': classBTotalCount,
    'classBErrorPoints': classBErrorPoints,
    'questionIds': questionIds,
    'submissions': {
      for (final e in submissions.entries) e.key: e.value.toJson(),
    },
    'wrongQuestionIds': wrongQuestionIds,
  };

  factory ExamResultRecord.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['submissions'] as Map<String, dynamic>? ?? const {};
    return ExamResultRecord(
      examId: json['examId'] as String? ?? '',
      completedAtMs: json['completedAtMs'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      totalErrorPoints: json['totalErrorPoints'] as int? ?? 0,
      fivePointErrorsCount: json['fivePointErrorsCount'] as int? ?? 0,
      failedByTwoFivePointRule:
          json['failedByTwoFivePointRule'] as bool? ?? false,
      passed: json['passed'] as bool? ?? false,
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      basicCorrectCount: json['basicCorrectCount'] as int? ?? 0,
      basicTotalCount: json['basicTotalCount'] as int? ?? 20,
      basicErrorPoints: json['basicErrorPoints'] as int? ?? 0,
      classBCorrectCount: json['classBCorrectCount'] as int? ?? 0,
      classBTotalCount: json['classBTotalCount'] as int? ?? 10,
      classBErrorPoints: json['classBErrorPoints'] as int? ?? 0,
      questionIds: (json['questionIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      submissions: {
        for (final e in rawSubs.entries)
          e.key: AnswerSubmission.fromJson(e.value as Map<String, dynamic>),
      },
      wrongQuestionIds: (json['wrongQuestionIds'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
    );
  }
}

class ExamEngine {
  const ExamEngine._();

  /// Generates an official 30-question Class B exam:
  /// 20 Grundstoff (`1.x`) + 10 Zusatzstoff Class B (`2.x`).
  static ActiveExamSession generateSession({
    required List<Question> allQuestions,
    required int nowMs,
    Random? random,
  }) {
    final rng = random ?? Random();
    final basicPool = allQuestions.where((q) => q.isBasicMaterial).toList()
      ..shuffle(rng);
    final classBPool = allQuestions.where((q) => !q.isBasicMaterial).toList()
      ..shuffle(rng);

    final selectedBasic = basicPool
        .take(min(ActiveExamSession.basicQuestionCount, basicPool.length))
        .toList();
    final selectedClassB = classBPool
        .take(min(ActiveExamSession.classBQuestionCount, classBPool.length))
        .toList();

    var combined = <Question>[...selectedBasic, ...selectedClassB];
    // Fallback if a small synthetic test catalog has fewer than 20+10 split
    if (combined.length <
        min(ActiveExamSession.totalQuestionCount, allQuestions.length)) {
      final chosenIds = combined.map((q) => q.questionId).toSet();
      final remainder =
          allQuestions.where((q) => !chosenIds.contains(q.questionId)).toList()
            ..shuffle(rng);
      combined.addAll(
        remainder.take(ActiveExamSession.totalQuestionCount - combined.length),
      );
    }

    return ActiveExamSession(
      sessionId: 'exam_$nowMs',
      questionIds: combined.map((q) => q.questionId).toList(growable: false),
      startedAtMs: nowMs,
    );
  }

  /// Grades an exam according to official German TÜV / DEKRA Class B rules:
  /// - Max 10 Fehlerpunkte allowed
  /// - Instant fail if >= 2 five-point questions are answered wrong (even at 10 pts)
  static ExamResultRecord gradeSession({
    required ActiveExamSession session,
    required Map<String, Question> questionsById,
    required int completedAtMs,
  }) {
    var totalErrorPoints = 0;
    var fivePointErrors = 0;
    var correctCount = 0;
    var wrongCount = 0;
    var basicCorrect = 0;
    var basicTotal = 0;
    var basicErrorPts = 0;
    var classBCorrect = 0;
    var classBTotal = 0;
    var classBErrorPts = 0;
    final wrongIds = <String>[];

    for (final qid in session.questionIds) {
      final question = questionsById[qid];
      if (question == null) continue;

      final submission = session.submissions[qid] ?? const AnswerSubmission();
      final eval = AnswerEvaluator.evaluate(question, submission);

      if (question.isBasicMaterial) {
        basicTotal++;
      } else {
        classBTotal++;
      }

      if (eval.isCorrect) {
        correctCount++;
        if (question.isBasicMaterial) {
          basicCorrect++;
        } else {
          classBCorrect++;
        }
      } else {
        wrongCount++;
        wrongIds.add(qid);
        totalErrorPoints += eval.errorPointsAwarded;
        if (question.points == 5) {
          fivePointErrors++;
        }
        if (question.isBasicMaterial) {
          basicErrorPts += eval.errorPointsAwarded;
        } else {
          classBErrorPts += eval.errorPointsAwarded;
        }
      }
    }

    final twoFivePointFail = fivePointErrors >= 2;
    final passed =
        totalErrorPoints <= ActiveExamSession.maxAllowedErrorPoints &&
        !twoFivePointFail;
    final elapsed = max(
      0,
      ActiveExamSession.defaultDurationSeconds - session.remainingSeconds,
    );

    return ExamResultRecord(
      examId: session.sessionId,
      completedAtMs: completedAtMs,
      durationSeconds: elapsed,
      totalErrorPoints: totalErrorPoints,
      fivePointErrorsCount: fivePointErrors,
      failedByTwoFivePointRule: twoFivePointFail,
      passed: passed,
      correctCount: correctCount,
      wrongCount: wrongCount,
      basicCorrectCount: basicCorrect,
      basicTotalCount: basicTotal,
      basicErrorPoints: basicErrorPts,
      classBCorrectCount: classBCorrect,
      classBTotalCount: classBTotal,
      classBErrorPoints: classBErrorPts,
      questionIds: List.unmodifiable(session.questionIds),
      submissions: Map.unmodifiable(session.submissions),
      wrongQuestionIds: List.unmodifiable(wrongIds),
    );
  }
}
