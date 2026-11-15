import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _sampleRepo() {
  Question q(String id, String text, int pts, {QuestionInputKind? inputKind}) =>
      Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Danger Teaching',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Basic Traffic Forms',
        'question_id': id,
        'question_number': id,
        'points': '$pts Points',
        'licenses': ['Basic material'],
        'question_text': text,
        'options': [
          {'letter': 'A.', 'text': 'Option A'},
          {'letter': 'B.', 'text': 'Option B'},
        ],
        'correct_answers': [
          {'letter': 'A.', 'text': 'Option A'},
        ],
        'comment': 'Explanation for $id',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      });

  return CatalogRepository.fromQuestions(
    englishQuestions: [
      q('1.1.01-001', 'Sample 1', 5),
      q('1.1.01-002', 'Sample 2', 4, inputKind: QuestionInputKind.numericInput),
    ],
  );
}

void main() {
  testWidgets(
    'HomeScreen has exam simulation on top, simplified progress, clean practice button, and 6 consistent drill cards',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = AppController(
        catalog: _sampleRepo(),
        storage: InMemoryProgressStorage(),
      );

      PracticeLaunchRequest? launchedRequest;
      var examStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: HomeScreen(
              controller: controller,
              onStartPractice: (req) => launchedRequest = req,
              onStartNewExam: () => examStarted = true,
              onResumeExam: () {},
              onOpenProgressTab: () {},
            ),
          ),
        ),
      );

      // 1. Exam Simulation is at the top (top offset is less than progress card)
      final examCardTop = tester
          .getTopLeft(find.byKey(const Key('start_exam_simulation_card')))
          .dy;
      final progressCardTop = tester
          .getTopLeft(find.byKey(const Key('readiness_hero_card')))
          .dy;
      final practiceButtonTop = tester
          .getTopLeft(find.byKey(const Key('smart_practice_cta')))
          .dy;

      expect(examCardTop, lessThan(progressCardTop));
      expect(progressCardTop, lessThan(practiceButtonTop));

      // Exam card text is short and crisp
      expect(find.text('Exam Simulation'), findsOneWidget);
      expect(
        find.text('30 questions • 45 min • Max 10 error points'),
        findsOneWidget,
      );

      // 2. Progress card header is simple 'PROGRESS'
      expect(find.text('PROGRESS'), findsOneWidget);
      expect(find.textContaining('Building Foundations'), findsNothing);

      // 3. Practice button has title 'Practice' and simple description
      expect(find.text('Practice'), findsOneWidget);
      expect(
        find.text('Mix of unseen questions and previous mistakes'),
        findsOneWidget,
      );

      // 4. Targeted Drills header has no "(1 TAP)"
      expect(find.text('TARGETED DRILLS'), findsOneWidget);
      expect(find.textContaining('(1 TAP)'), findsNothing);

      // 5. All 6 drills are Card widgets (not chips)
      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(const Key('drill_most_mistakes')), findsOneWidget);
      expect(find.byKey(const Key('drill_least_answered')), findsOneWidget);
      expect(find.byKey(const Key('drill_five_point')), findsOneWidget);
      expect(find.byKey(const Key('drill_videos')), findsOneWidget);
      expect(find.byKey(const Key('drill_numeric')), findsOneWidget);
      expect(find.byKey(const Key('drill_saved')), findsOneWidget);

      // Tap exam card button
      await tester.tap(find.byKey(const Key('begin_exam_button')));
      await tester.pump();
      expect(examStarted, isTrue);

      // Tap practice button
      await tester.tap(find.byKey(const Key('smart_practice_cta')));
      await tester.pump();
      expect(launchedRequest, isNotNull);
      expect(launchedRequest!.title, 'Practice');
    },
  );
}
