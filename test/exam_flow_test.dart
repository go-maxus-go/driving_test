import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/answer_evaluation.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/exam_player_screen.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/services/exam_engine.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _buildExamTestRepo() {
  final questions = <Question>[];
  for (var i = 1; i <= 20; i++) {
    final id = '1.1.01-${i.toString().padLeft(3, '0')}';
    final isFirstVideo = i == 1;
    questions.add(
      Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Danger Teaching',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Hazards',
        'question_id': id,
        'question_number': id,
        'points': i <= 2 ? '5 Points' : '3 Points',
        'licenses': ['Basic material'],
        'question_text': 'Exam Basic Question $i',
        'options': [
          {'letter': 'A.', 'text': 'Safe action'},
          {'letter': 'B.', 'text': 'Risky action'},
        ],
        'correct_answers': [
          {'letter': 'A.', 'text': 'Safe action'},
        ],
        'comment': 'Detailed explanation for $id',
        'local_image_paths': isFirstVideo
            ? ['images/1_1_02-049.png']
            : <String>[],
        'local_video_paths': isFirstVideo
            ? ['videos/1_1_02-049.mp4']
            : <String>[],
      }),
    );
  }
  for (var i = 1; i <= 10; i++) {
    final id = '2.7.01-${i.toString().padLeft(3, '0')}';
    questions.add(
      Question.fromJson({
        'theme_number': 'Theme 2.7.',
        'theme_name': 'Technology',
        'chapter_number': '2.7.01 Chapter',
        'chapter_name': 'Brakes',
        'question_id': id,
        'question_number': id,
        'points': '3 Points',
        'licenses': ['B'],
        'question_text': 'Exam Class B Question $i',
        'options': [
          {'letter': 'A.', 'text': 'Safe action'},
          {'letter': 'B.', 'text': 'Risky action'},
        ],
        'correct_answers': [
          {'letter': 'A.', 'text': 'Safe action'},
        ],
        'comment': 'Detailed explanation for $id',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      }),
    );
  }
  return CatalogRepository.fromQuestions(englishQuestions: questions);
}

void main() {
  testWidgets(
    'ExamPlayer enforces 2-phase video lock, grades 30 questions, shows PASSED verdict, and launches mistake practice in 1 tap',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = _buildExamTestRepo();
      final allIds = repo
          .questionsFor(AppLanguage.en)
          .map((q) => q.questionId)
          .toList();

      // Pre-fill Q2..Q29 right, leave Q30 wrong (3 error points -> PASSED with 3/10!)
      final prefilledSubs = <String, AnswerSubmission>{
        for (var i = 1; i < 29; i++)
          allIds[i]: const AnswerSubmission(selectedLetters: {'A'}),
        allIds[29]: const AnswerSubmission(selectedLetters: {'B'}),
      };

      final activeExam = ActiveExamSession(
        sessionId: 'exam_ui_test',
        questionIds: allIds,
        startedAtMs: 1000,
        submissions: prefilledSubs,
      );

      PracticeLaunchRequest? mistakesPracticeReq;
      final controller = AppController(
        catalog: repo,
        storage: InMemoryProgressStorage(),
        initialData: PersistedUserData(activeExam: activeExam),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: ExamPlayerScreen(
            controller: controller,
            enableNativeVideo: false,
            onPracticeMistakes: (req) => mistakesPracticeReq = req,
          ),
        ),
      );

      // Q1 is a video question -> Phase 1 hides question text & options!
      expect(find.text('Exam Basic Question 1'), findsNothing);
      expect(find.text('Plays remaining: 5 of 5'), findsOneWidget);

      // Watch video again -> decrements remaining plays to 4 of 5
      await tester.tap(find.byKey(const Key('exam_watch_video_again_btn')));
      await tester.pump();
      expect(find.text('Plays remaining: 4 of 5'), findsOneWidget);

      // Reveal question & answers -> locks video to freeze-frame and shows stem!
      await tester.tap(find.byKey(const Key('reveal_exam_video_question_btn')));
      await tester.pump();
      expect(find.text('Exam Basic Question 1'), findsOneWidget);
      expect(find.byKey(const Key('freeze_frame_badge')), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);

      // Verify points, topic name, and flag button are NOT displayed during exam
      expect(find.textContaining('Points •'), findsNothing);
      expect(find.textContaining('Grundstoff'), findsNothing);
      expect(find.byKey(const Key('flag_exam_question_btn')), findsNothing);

      // Verify Next Question button has clean label without Q suffix
      expect(find.text('Next Question'), findsOneWidget);
      expect(find.text('Next Question (Q2)'), findsNothing);

      // Attempting to submit while Q1 is unanswered prompts "Jump to Question 1"
      await tester.tap(find.byKey(const Key('header_submit_exam_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Jump to Question 1'), findsOneWidget);
      await tester.tap(find.byKey(const Key('jump_to_open_question_btn')));
      await tester.pumpAndSettle();

      // Select correct option A on Q1 -> now all 30 questions are answered!
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();

      // Submit exam directly from header
      await tester.tap(find.byKey(const Key('header_submit_exam_btn')));
      await tester.pumpAndSettle();

      // Verdict screen shows PASSED with 3 / 10 Error Points and 1 mistake!
      expect(find.text('PASSED! (BESTANDEN)'), findsOneWidget);
      expect(find.text('3 / 10 Error Points (max 10 allowed)'), findsOneWidget);
      expect(find.text('Detailed explanation for 2.7.01-010'), findsOneWidget);

      // 1 tap on "Practice These 1 Mistakes Now" launches Practice queue!
      await tester.tap(find.byKey(const Key('practice_exam_mistakes_btn')));
      await tester.pumpAndSettle();
      expect(mistakesPracticeReq, isNotNull);
      expect(mistakesPracticeReq!.questionIds, ['2.7.01-010']);
    },
  );
}
