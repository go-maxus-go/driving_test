import 'dart:math';

import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/answer_evaluation.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/services/exam_engine.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

Question _makeMcQuestion({
  required String id,
  required String themeCode,
  required int points,
  String textEn = 'Question EN',
  bool hasVideo = false,
}) {
  return Question.fromJson({
    'theme_number': 'Theme $themeCode.',
    'theme_name': themeCode.startsWith('1.') ? 'Basic Theme' : 'Class B Theme',
    'chapter_number': '$themeCode.01 Chapter',
    'chapter_name': 'Sample Chapter',
    'question_id': id,
    'question_number': id,
    'points': '$points Points',
    'licenses': [themeCode.startsWith('1.') ? 'Basic material' : 'B'],
    'question_text': '$textEn $id',
    'options': [
      {'letter': 'A.', 'text': 'Correct option'},
      {'letter': 'B.', 'text': 'Wrong option'},
    ],
    'correct_answers': [
      {'letter': 'A.', 'text': 'Correct option'},
    ],
    'comment': 'Explanation for $id',
    'local_image_paths': hasVideo ? ['images/$id.png'] : <String>[],
    'local_video_paths': hasVideo ? ['videos/$id.mp4'] : <String>[],
  });
}

CatalogRepository _buildSyntheticCatalog() {
  final en = <Question>[];
  final de = <Question>[];

  for (var i = 1; i <= 25; i++) {
    final id = '1.1.01-${i.toString().padLeft(3, '0')}';
    final pts = (i <= 4) ? 5 : ((i % 3) + 2);
    en.add(
      _makeMcQuestion(id: id, themeCode: '1.1', points: pts, hasVideo: i == 1),
    );
    de.add(
      _makeMcQuestion(
        id: id,
        themeCode: '1.1',
        points: pts,
        textEn: 'Frage DE',
        hasVideo: i == 1,
      ),
    );
  }
  for (var i = 1; i <= 15; i++) {
    final id = '2.7.01-${i.toString().padLeft(3, '0')}';
    final pts = (i <= 2) ? 5 : 3;
    en.add(_makeMcQuestion(id: id, themeCode: '2.7', points: pts));
    de.add(
      _makeMcQuestion(
        id: id,
        themeCode: '2.7',
        points: pts,
        textEn: 'Frage DE',
      ),
    );
  }

  return CatalogRepository.fromQuestions(
    englishQuestions: en,
    germanQuestions: de,
  );
}

void main() {
  group('SmartQueueBuilder & AppController learning telemetry', () {
    test('tracks progress across language switches and orders Most Mistakes & Least Answered', () async {
      var now = 1000;
      final controller = AppController(
        catalog: _buildSyntheticCatalog(),
        storage: InMemoryProgressStorage(),
        clockMs: () => now += 100,
      );

      final q1 = controller.questionById('1.1.01-001')!; // 5 pts
      final q2 = controller.questionById('1.1.01-005')!; // 4 pts
      final q3 = controller.questionById('1.1.01-006')!; // 2 pts

      // Answer q1 wrong twice (active mistake, 5 pts)
      await controller.recordPracticeAnswer(
        question: q1,
        submission: const AnswerSubmission(selectedLetters: {'B'}),
      );
      await controller.recordPracticeAnswer(
        question: q1,
        submission: const AnswerSubmission(selectedLetters: {'B'}),
      );

      // Answer q2 wrong once, then right once (recovered once, consecutiveCorrect=1)
      await controller.recordPracticeAnswer(
        question: q2,
        submission: const AnswerSubmission(selectedLetters: {'B'}),
      );
      await controller.recordPracticeAnswer(
        question: q2,
        submission: const AnswerSubmission(selectedLetters: {'A'}),
      );

      // Answer q3 right twice (no mistakes)
      await controller.recordPracticeAnswer(
        question: q3,
        submission: const AnswerSubmission(selectedLetters: {'A'}),
      );
      await controller.recordPracticeAnswer(
        question: q3,
        submission: const AnswerSubmission(selectedLetters: {'A'}),
      );

      // Switch to German — progress must stay 100% intact!
      await controller.setLanguage(AppLanguage.de);
      expect(controller.globalStats.totalQuestions, 40);
      expect(
        controller.globalStats.correctQuestions,
        2,
      ); // q2 and q3 lastWasCorrect
      expect(controller.globalStats.wrongQuestions, 1); // q1 active wrong
      expect(controller.globalStats.unseenQuestions, 37);

      // Most Mistakes queue includes q1 and q2 (not q3), with active wrong q1 first!
      final mistakesQueue = controller.buildMostMistakesQueue();
      expect(mistakesQueue, ['1.1.01-001', '1.1.01-005']);

      // Least Answered queue puts all 37 unseen (0x) items before 2x-answered items!
      final leastQueue = controller.buildLeastAnsweredQueue(random: Random(42));
      expect(leastQueue.length, 40);
      for (final id in leastQueue.take(37)) {
        expect(controller.progressFor(id).attemptsCount, 0);
      }
      expect(leastQueue.skip(37).toSet(), {
        '1.1.01-001',
        '1.1.01-005',
        '1.1.01-006',
      });
    });

    test(
      'exports and imports backup JSON cleanly and supports full reset',
      () async {
        final controller = AppController(
          catalog: _buildSyntheticCatalog(),
          storage: InMemoryProgressStorage(),
        );
        final q1 = controller.questionById('1.1.01-001')!;
        await controller.recordPracticeAnswer(
          question: q1,
          submission: const AnswerSubmission(selectedLetters: {'A'}),
        );
        await controller.toggleBookmark(q1.questionId);
        await controller.setLanguage(AppLanguage.de);

        final exported = controller.exportBackupJson();

        await controller.resetAllProgress();
        expect(controller.globalStats.correctQuestions, 0);
        expect(controller.isBookmarked(q1.questionId), isFalse);

        final ok = await controller.importBackupJson(exported);
        expect(ok, isTrue);
        expect(controller.language, AppLanguage.de);
        expect(controller.globalStats.correctQuestions, 1);
        expect(controller.isBookmarked(q1.questionId), isTrue);
      },
    );
  });

  group('ExamEngine official German Class B rules', () {
    test(
      'generates 20 Grundstoff + 10 Zusatzstoff and enforces 5x video lock',
      () async {
        final controller = AppController(
          catalog: _buildSyntheticCatalog(),
          storage: InMemoryProgressStorage(),
        );
        final session = await controller.startNewExam(random: Random(7));
        expect(session.questionIds.length, 30);

        final basicCount = session.questionIds
            .where((id) => controller.questionById(id)!.isBasicMaterial)
            .length;
        final classBCount = session.questionIds
            .where((id) => !controller.questionById(id)!.isBasicMaterial)
            .length;
        expect(basicCount, 20);
        expect(classBCount, 10);

        // Video 5-play cap + lock behavior
        const vidId = '1.1.01-001';
        expect(session.playsRemainingFor(vidId), 5);
        for (var i = 0; i < 7; i++) {
          await controller.recordExamVideoPlay(vidId);
        }
        expect(session.playsUsedFor(vidId), 5);
        expect(session.playsRemainingFor(vidId), 0);

        await controller.lockExamVideoAndRevealQuestion(vidId);
        expect(session.isVideoLocked(vidId), isTrue);
      },
    );

    test('passes with 10 points (non-5pt pair) and FAILS on two wrong 5-point questions', () async {
      final catalog = _buildSyntheticCatalog();
      final byId = catalog.forLanguage(AppLanguage.en).byId;

      // Build deterministic 30-question exam containing two 5-pt items and three 3/4-pt items
      final thirtyIds = catalog
          .questionsFor(AppLanguage.en)
          .take(30)
          .map((q) => q.questionId)
          .toList();

      // Case 1: Answer everything right EXCEPT two 5-point questions (5 + 5 = 10 pts -> FAIL!)
      final twoFiveFailSession = ActiveExamSession(
        sessionId: 'exam_5pt_trap',
        questionIds: thirtyIds,
        startedAtMs: 1000,
        submissions: {
          for (final id in thirtyIds)
            id: AnswerSubmission(
              selectedLetters: (id == '1.1.01-001' || id == '1.1.01-002')
                  ? const {'B'} // wrong on two 5-point questions!
                  : const {'A'},
            ),
        },
      );

      final failResult = ExamEngine.gradeSession(
        session: twoFiveFailSession,
        questionsById: byId,
        completedAtMs: 5000,
      );
      expect(failResult.totalErrorPoints, 10);
      expect(failResult.fivePointErrorsCount, 2);
      expect(failResult.failedByTwoFivePointRule, isTrue);
      expect(failResult.passed, isFalse);

      // Case 2: One 5-pt wrong + one 3-pt wrong + one 2-pt wrong = 10 pts -> PASS!
      // Verify exact point weights from synthetic catalog:
      // i=1 -> 5pts, i=6 (6%3+2=2pts), i=7 (7%3+2=3pts) -> 5 + 2 + 3 = 10 pts!
      final tenPtPassSession = ActiveExamSession(
        sessionId: 'exam_10pt_pass',
        questionIds: thirtyIds,
        startedAtMs: 1000,
        submissions: {
          for (final id in thirtyIds)
            id: AnswerSubmission(
              selectedLetters:
                  (id == '1.1.01-001' ||
                      id == '1.1.01-006' ||
                      id == '1.1.01-007')
                  ? const {'B'}
                  : const {'A'},
            ),
        },
      );

      final passResult = ExamEngine.gradeSession(
        session: tenPtPassSession,
        questionsById: byId,
        completedAtMs: 5000,
      );
      expect(passResult.totalErrorPoints, 10);
      expect(passResult.fivePointErrorsCount, 1);
      expect(passResult.failedByTwoFivePointRule, isFalse);
      expect(passResult.passed, isTrue);
    });
  });
}
