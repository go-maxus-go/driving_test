import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/answer_evaluation.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/models/user_progress.dart';
import 'package:driving_exam/screens/home_screen.dart';
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
    'ProgressScreen tracks coverage, ranks weak topics, inspects past exams, drills exposure buckets, and exports/resets/imports JSON backup',
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
          // Mastered, 2+ attempts
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

      // 2. Weak topic 1.3 ranked with 100% error rate -> 1-tap Train
      expect(
        find.textContaining('1.3  Priority & Right of Way'),
        findsOneWidget,
      );
      expect(find.text('100% error rate'), findsOneWidget);
      await tester.tap(find.byKey(const Key('train_weak_topic_1.3')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds.toSet(), {
        '1.3.01-001',
        '1.3.01-002',
      });

      // 3. Past Mock Exam card -> tap opens ExamVerdictScreen -> 1-tap practice exam mistakes
      await tester.scrollUntilVisible(
        find.byKey(const Key('exam_history_item_0')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('exam_history_item_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exam_verdict_banner')), findsOneWidget);
      expect(
        find.text('Official rule explanation for 1.3.01-001.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('practice_exam_mistakes_btn')));
      await tester.pumpAndSettle();
      expect(lastPracticeRequest?.questionIds, ['1.3.01-001']);

      // 4. Exposure distribution: 2x at 0 attempts, 1x at 1 attempt, 1x at 2+ attempts
      await tester.scrollUntilVisible(
        find.byKey(const Key('exposure_row_1')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('2 / 4'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exposure_drill_0')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds.toSet(), {
        '1.3.01-002',
        '2.7.01-001',
      });

      await tester.tap(find.byKey(const Key('exposure_drill_1')));
      await tester.pump();
      expect(lastPracticeRequest?.questionIds, ['1.3.01-001']);

      // 5. Export JSON backup -> Reset All Progress -> Import JSON backup back!
      final savedBackup = controller.exportBackupJson();
      expect(savedBackup, contains('1.3.01-001'));

      await tester.scrollUntilVisible(
        find.byKey(const Key('open_backup_reset_btn')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('open_backup_reset_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('exported_backup_json_preview')),
        findsOneWidget,
      );

      // Trigger Reset All Progress
      await tester.tap(find.byKey(const Key('reset_all_progress_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm_reset_progress_btn')));
      await tester.pumpAndSettle();

      expect(controller.globalStats.unseenQuestions, 4);
      expect(controller.examHistory, isEmpty);

      // When no exams exist, starting first exam button works
      await tester.scrollUntilVisible(
        find.byKey(const Key('progress_start_first_exam_btn')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('progress_start_first_exam_btn')));
      await tester.pump();
      expect(examLaunchedCount, 1);

      // Re-open Backup/Reset sheet and paste savedBackup JSON to restore!
      await tester.scrollUntilVisible(
        find.byKey(const Key('open_backup_reset_btn')),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('open_backup_reset_btn')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('import_backup_json_input')),
        savedBackup,
      );
      await tester.tap(find.byKey(const Key('confirm_import_backup_btn')));
      await tester.pumpAndSettle();

      expect(controller.globalStats.correctQuestions, 1);
      expect(controller.globalStats.wrongQuestions, 1);
      expect(controller.examHistory.length, 1);
    },
  );
}
