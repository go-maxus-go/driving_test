import 'dart:math';

import '../models/question.dart';
import '../models/user_progress.dart';

enum PracticeFilterKind {
  smartPractice,
  mostMistakes,
  leastAnswered,
  fivePointTraps,
  videoScenes,
  numericInput,
  savedBookmarks,
  topicSelection,
  customIds,
}

class SmartQueueBuilder {
  const SmartQueueBuilder._();

  static const int defaultSmartBatchSize = 30;
  static const int minBatchSize = 1;
  static const int maxBatchSize = 200;

  /// Builds a varied Practice sprint (defaulting to 30 questions to match the
  /// official exam length) combining previously unseen questions with a fresh
  /// mix of previous mistakes, shuffled so sessions don't feel repetitive.
  static List<String> buildSmartPractice({
    required List<Question> allQuestions,
    required Map<String, QuestionProgress> progressMap,
    int batchSize = defaultSmartBatchSize,
    Random? random,
  }) {
    final rng = random ?? Random();
    final clampedBatch = batchSize.clamp(minBatchSize, maxBatchSize);
    final target = min(clampedBatch, allQuestions.length);
    if (target == 0) return const [];

    // 1. Unseen questions (0 attempts), shuffled randomly every session.
    final unseen =
        allQuestions
            .where((q) => (progressMap[q.questionId]?.attemptsCount ?? 0) == 0)
            .map((q) => q.questionId)
            .toList()
          ..shuffle(rng);

    // 2. Previous mistakes: prioritize active/unrecovered mistakes first,
    //    shuffling within each tier so the learner doesn't see the exact same
    //    ordered block every time.
    final activeMistakes = <String>[];
    final unrecoveredMistakes = <String>[];
    final olderMistakes = <String>[];
    for (final q in allQuestions) {
      final p = progressMap[q.questionId];
      if (p == null || p.wrongCount <= 0) continue;
      if (!p.lastWasCorrect) {
        activeMistakes.add(q.questionId);
      } else if (p.needsRecovery) {
        unrecoveredMistakes.add(q.questionId);
      } else {
        olderMistakes.add(q.questionId);
      }
    }
    activeMistakes.shuffle(rng);
    unrecoveredMistakes.shuffle(rng);
    olderMistakes.shuffle(rng);

    final prioritizedMistakes = <String>[
      ...activeMistakes,
      ...unrecoveredMistakes,
      ...olderMistakes,
    ];

    final chosen = <String>[];
    final chosenSet = <String>{};

    void takeFrom(Iterable<String> source, int count) {
      var added = 0;
      for (final id in source) {
        if (added >= count || chosen.length >= target) break;
        if (chosenSet.add(id)) {
          chosen.add(id);
          added++;
        }
      }
    }

    // Mix ~30% previous mistakes with ~70% unseen questions so every session
    // feels fresh while steadily reinforcing past mistakes.
    final maxMistakes = target <= 1
        ? (unseen.isEmpty ? 1 : 0)
        : (target * 0.30).round().clamp(1, target - 1);
    final mistakeQuota = min(prioritizedMistakes.length, maxMistakes);
    final unseenQuota = target - mistakeQuota;

    takeFrom(unseen, unseenQuota);
    takeFrom(prioritizedMistakes, mistakeQuota);

    // If unseen questions ran short, pull more mistakes before falling back
    // to least-answered / spaced review.
    if (chosen.length < target) {
      takeFrom(prioritizedMistakes, target - chosen.length);
    }
    if (chosen.length < target) {
      final leastAnswered = buildLeastAnswered(
        allQuestions: allQuestions,
        progressMap: progressMap,
        random: rng,
      );
      takeFrom(leastAnswered, target - chosen.length);
    }

    // Interleave unseen questions and previous mistakes throughout the session.
    chosen.shuffle(rng);
    return chosen;
  }

  /// Selects all questions with >= 1 historical mistake, ordered by:
  /// 1) Currently wrong (`!lastWasCorrect`)
  /// 2) Unrecovered (`consecutiveCorrect < 2`)
  /// 3) Highest mistake rate (`wrongCount / attemptsCount`)
  /// 4) Highest total `wrongCount`
  /// 5) Highest error point value (`5 -> 2`)
  static List<String> buildMostMistakes({
    required List<Question> allQuestions,
    required Map<String, QuestionProgress> progressMap,
  }) {
    final candidates = allQuestions
        .where((q) => (progressMap[q.questionId]?.wrongCount ?? 0) > 0)
        .toList();

    candidates.sort((a, b) {
      final pa = progressMap[a.questionId]!;
      final pb = progressMap[b.questionId]!;

      final activeWrongA = pa.lastWasCorrect ? 0 : 1;
      final activeWrongB = pb.lastWasCorrect ? 0 : 1;
      if (activeWrongA != activeWrongB) {
        return activeWrongB.compareTo(activeWrongA);
      }

      final needsRecA = pa.needsRecovery ? 1 : 0;
      final needsRecB = pb.needsRecovery ? 1 : 0;
      if (needsRecA != needsRecB) {
        return needsRecB.compareTo(needsRecA);
      }

      final rateCmp = pb.mistakeRate.compareTo(pa.mistakeRate);
      if (rateCmp != 0) return rateCmp;

      final wrongCmp = pb.wrongCount.compareTo(pa.wrongCount);
      if (wrongCmp != 0) return wrongCmp;

      return b.points.compareTo(a.points);
    });

    return candidates.map((q) => q.questionId).toList(growable: false);
  }

  /// Orders questions from fewest attempts (`0` unseen first, then `1`, `2`...)
  /// with oldest `lastAnsweredAtMs` first and shuffled tie-breaking across themes.
  static List<String> buildLeastAnswered({
    required List<Question> allQuestions,
    required Map<String, QuestionProgress> progressMap,
    int? maxAttemptsExclusive,
    Random? random,
  }) {
    final rng = random ?? Random();
    final filtered = allQuestions.where((q) {
      final attempts = progressMap[q.questionId]?.attemptsCount ?? 0;
      if (maxAttemptsExclusive != null && attempts >= maxAttemptsExclusive) {
        return false;
      }
      return true;
    }).toList();

    // Shuffle first so equal-attempt questions interleave themes naturally
    filtered.shuffle(rng);

    filtered.sort((a, b) {
      final pa = progressMap[a.questionId];
      final pb = progressMap[b.questionId];
      final attA = pa?.attemptsCount ?? 0;
      final attB = pb?.attemptsCount ?? 0;
      if (attA != attB) return attA.compareTo(attB);

      final tsA = pa?.lastAnsweredAtMs ?? 0;
      final tsB = pb?.lastAnsweredAtMs ?? 0;
      return tsA.compareTo(tsB);
    });

    return filtered.map((q) => q.questionId).toList(growable: false);
  }

  /// Builds a topic/chapter queue prioritizing active mistakes and unseen
  /// questions before already-correct questions so study time is never wasted.
  static List<String> buildTopicQueue({
    required Iterable<String> scopedQuestionIds,
    required Map<String, Question> questionsById,
    required Map<String, QuestionProgress> progressMap,
    bool unfinishedOnly = false,
  }) {
    final questions = scopedQuestionIds
        .map((id) => questionsById[id])
        .whereType<Question>()
        .where((q) {
          if (!unfinishedOnly) return true;
          final p = progressMap[q.questionId];
          return p == null || p.attemptsCount == 0 || !p.lastWasCorrect;
        })
        .toList();

    // If all questions in topic are already mastered and user asked for
    // unfinishedOnly, gracefully fall back to all questions in that topic.
    final effective = questions.isNotEmpty
        ? questions
        : scopedQuestionIds
              .map((id) => questionsById[id])
              .whereType<Question>()
              .toList();

    effective.sort((a, b) {
      final rankA = _priorityRank(progressMap[a.questionId]);
      final rankB = _priorityRank(progressMap[b.questionId]);
      if (rankA != rankB) return rankA.compareTo(rankB);
      return a.questionId.compareTo(b.questionId);
    });

    return effective.map((q) => q.questionId).toList(growable: false);
  }

  static int _priorityRank(QuestionProgress? p) {
    if (p == null) return 1; // Unseen second (right after active mistakes)
    if (p.attemptsCount == 0) return 1;
    if (!p.lastWasCorrect) return 0; // Active mistakes first!
    if (p.needsRecovery) return 2;
    return 3; // Already mastered last
  }
}
