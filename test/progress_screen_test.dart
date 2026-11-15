import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/answer_evaluation.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/models/user_progress.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/screens/mock_exam_history_screen.dart';
import 'package:driving_exam/screens/progress_screen.dart';
import 'package:driving_exam/services/exam_engine.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _buildProgressRepo() {
  Question makeQ(
    String id,
    String themeCode,
    String themeName,
    String chCode,
    String chName,
  ) {
    return Question.fromJson({
      'theme_number': 'Theme $themeCode.',
      'theme_name': themeName,
      'chapter_number': '$chCode Chapter',
      'chapter_name': chName,
      'question_id': id,
      'question_number': id,
      'points': '4 Points',
      'licenses': [themeCode.startsWith('1.') ? 'Basic material' : 'B'],
      'question_text': 'Question $id about $chName',
      'options': [
        {'letter': 'A.', 'text': 'Correct option'},
        {'letter': 'B.', 'text': 'Wrong option'},
      ],
      'correct_answers': [
        {'letter': 'A.', 'text': 'Correct option'},
      ],
      'comment': 'Official rule explanation for $id.',
      'local_image_paths': <String>[],
      'local_video_paths': <String>[],
    });
  }

  final list = [
    makeQ('1.1.01-001', '1.1', 'Danger Teaching', '1.1.01', 'Hazards'),
    makeQ(
      '1.3.01-001',
      '1.3',
      'Priority & Right of Way',
      '1.3.01',
      'Crossings',
    ),
    makeQ(
      '1.3.01-002',
      '1.3',
      'Priority & Right of Way',
      '1.3.01',
      'Crossings',
    ),
    makeQ('2.7.01-001', '2.7', 'Vehicle Technology', '2.7.01', 'Brakes'),
  ];
  return CatalogRepository.fromQuestions(englishQuestions: list);
}

void main() {
  testWidgets(
    'ProgressScreen tracks coverage, ranks top 3 weak topics, links to mock exam history, and retries same exam from history',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      PracticeLaunchRequest? lastPracticeRequest;
      var examLaunchedCount = 0;

      final pastExam = ExamResultRecord(
        examId: 'exam_1',
        completedAtMs: DateTime(2026, 5, 10, 14, 30).millisecondsSinceEpoch,
        durationSeconds: 615,
        totalErrorPoints: 8,
        fivePointErrorsCount: 0,
        passed: true,
        failedByTwoFivePointRule: false,
        correctCount: 28,
        wrongCount: 2,
        basicCorrectCount: 19,
        basicTotalCount: 20,
        basicErrorPoints: 4,
        classBCorrectCount: 9,
        classBTotalCount: 10,
        classBErrorPoints: 4,
        questionIds: const ['1.1.01-001', '1.3.01-001'],
        wrongQuestionIds: const ['1.3.01-001'],
        submissions: const {
          '1.1.01-001': AnswerSubmission(selectedLetters: {'A'}),
          '1.3.01-001': AnswerSubmission(selectedLetters: {'B'}),
        },
      );

      final initialData = PersistedUserData(
        progressById: const {
          // Mastered, 2+ consecutive correct
          '1.1.01-001': QuestionProgress(
            questionId: '1.1.01-001',
            attemptsCount: 2,
            correctCount: 2,
            wrongCount: 0,
            consecutiveCorrect: 2,
            lastWasCorrect: true,
          ),
          // Mistake, 1 attempt
          '1.3.01-001': QuestionProgress(
            questionId: '1.3.01-001',
            attemptsCount: 1,
            correctCount: 0,
            wrongCount: 1,
            consecutiveCorrect: 0,
            lastWasCorrect: false,
          ),
        },
        examHistory: [pastExam],
      );

      final controller = AppController(
        catalog: _buildProgressRepo(),
        storage: InMemoryProgressStorage(),
        initialData: initialData,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ProgressScreen(
              controller: controller,
              onStartPractice: (req) => lastPracticeRequest = req,
              onStartExam: () => examLaunchedCount++,
            ),
          ),
        ),
      );

      // 1. Coverage counts: 1 mastered, 1 mistake, 2 unseen out of 4 total
      expect(
        find.descendant(
          of: find.byKey(const Key('coverage_mastered_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('coverage_mistakes_count')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('coverage_unseen_count')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );

      // 2. Top weak topics (up to 3)
      expect(
        find.textContaining('1.3  Priority & Right of Way'),
        findsOneWidget,
      );
      expect(find.text('100% error rate'), findsOneWidget);

      await tester.tap(find.byKey(const Key('drill_weak_topic_1.3')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds.toSet(), {
        '1.3.01-001',
        '1.3.01-002',
      });

      // 3. Question Learning Status with clear explanation text
      expect(
        find.text(
          'A question is considered "Learned" once answered correctly 2 times in a row.',
        ),
        findsOneWidget,
      );

      // Exposure drill: Unseen
      await tester.tap(find.byKey(const Key('exposure_drill_0')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds.toSet(), {
        '1.3.01-002',
        '2.7.01-001',
      });

      // Exposure drill: In Training
      await tester.tap(find.byKey(const Key('exposure_drill_1')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds, ['1.3.01-001']);

      // 4. No backup/reset clutter on progress screen (moved to settings)
      expect(find.byKey(const Key('open_backup_reset_btn')), findsNothing);

      // 5. Separate Mock Exam History button opens MockExamHistoryScreen
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('open_mock_exam_history_btn')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('open_mock_exam_history_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MockExamHistoryScreen), findsOneWidget);
      expect(find.byKey(const Key('past_exam_card_0')), findsOneWidget);
      expect(find.textContaining('8 / 10 Pts'), findsOneWidget);

      // Tap past exam card to open review verdict
      await tester.tap(find.byKey(const Key('past_exam_card_0')));
      await tester.pumpAndSettle();
      expect(find.text('PASSED! (BESTANDEN)'), findsOneWidget);
      expect(find.byKey(const Key('verdict_new_exam_btn')), findsNothing);
      expect(find.text('Mistakes Only (1)'), findsOneWidget);

      // Tap Retry -> restarts the exact same exam and launches ExamPlayerScreen
      await tester.tap(find.byKey(const Key('retry_exam_btn')));
      await tester.pumpAndSettle();
      expect(examLaunchedCount, 1);
      expect(controller.activeExam, isNotNull);
      expect(
        controller.activeExam!.questionIds,
        equals(['1.1.01-001', '1.3.01-001']),
      );
      expect(controller.activeExam!.submissions, isEmpty);
    },
  );
}
