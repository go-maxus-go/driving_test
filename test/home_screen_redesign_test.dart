import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _sampleRepo() {
  Question q(
    String id,
    String text,
    int pts, {
    String themeNumber = 'Theme 1.1.',
    String themeName = 'Danger Teaching',
    List<String> images = const [],
    List<String> videos = const [],
    bool numeric = false,
  }) => Question.fromJson({
    'theme_number': themeNumber,
    'theme_name': themeName,
    'chapter_number': '1.1.01 Chapter',
    'chapter_name': 'Basic Traffic Forms',
    'question_id': id,
    'question_number': id,
    'points': '$pts Points',
    'licenses': ['Basic material'],
    'question_text': text,
    'options': numeric
        ? <Map<String, dynamic>>[]
        : [
            {'letter': 'A.', 'text': 'Option A'},
            {'letter': 'B.', 'text': 'Option B'},
          ],
    'correct_answers': numeric
        ? [
            {'letter': '50', 'text': ''},
          ]
        : [
            {'letter': 'A.', 'text': 'Option A'},
          ],
    'comment': 'Explanation for $id',
    'local_image_paths': images,
    'local_video_paths': videos,
  });

  return CatalogRepository.fromQuestions(
    englishQuestions: [
      q('1.1.01-001', 'Sample 1', 5, videos: ['assets/videos/v1.mp4']),
      q('1.1.01-002', 'Sample 2', 4, numeric: true),
      q('1.2.01-003', 'Sample Image', 3, images: ['assets/images/img1.png']),
      q(
        '1.4.40-001',
        'Sample Sign',
        3,
        themeNumber: 'Theme 1.4.',
        themeName: 'Road Sign',
        images: ['assets/images/sign1.png'],
      ),
    ],
  );
}

void main() {
  testWidgets(
    'HomeScreen puts Saved in 2nd position and places Image & Sign Questions near Video Questions',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1200);
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

      // 1. Order: Progress -> Practice -> Exam Simulation
      final progressCardTop = tester
          .getTopLeft(find.byKey(const Key('readiness_hero_card')))
          .dy;
      final practiceButtonTop = tester
          .getTopLeft(find.byKey(const Key('smart_practice_cta')))
          .dy;
      final examCardTop = tester
          .getTopLeft(find.byKey(const Key('start_exam_simulation_card')))
          .dy;

      expect(progressCardTop, lessThan(practiceButtonTop));
      expect(practiceButtonTop, lessThan(examCardTop));

      // Both Practice and Exam Simulation cards share identical surface styling
      final practiceCard = tester.widget<Card>(
        find.ancestor(
          of: find.byKey(const Key('smart_practice_cta')),
          matching: find.byType(Card),
        ),
      );
      final examCard = tester.widget<Card>(
        find.ancestor(
          of: find.byKey(const Key('start_exam_simulation_card')),
          matching: find.byType(Card),
        ),
      );
      expect(practiceCard.color, equals(examCard.color));

      // Exam card text omits "Max 10 error points"
      expect(find.text('Exam Simulation'), findsOneWidget);
      expect(find.text('30 questions • 45 min'), findsOneWidget);
      expect(find.textContaining('Max 10 error points'), findsNothing);

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

      // 5. All 8 drills are Card widgets (not chips)
      expect(find.byType(ActionChip), findsNothing);
      expect(find.byKey(const Key('drill_most_mistakes')), findsOneWidget);
      expect(find.byKey(const Key('drill_saved')), findsOneWidget);
      expect(find.byKey(const Key('drill_least_answered')), findsOneWidget);
      expect(find.byKey(const Key('drill_five_point')), findsOneWidget);
      expect(find.byKey(const Key('drill_videos')), findsOneWidget);
      expect(find.byKey(const Key('drill_images')), findsOneWidget);
      expect(find.byKey(const Key('drill_signs')), findsOneWidget);
      expect(find.byKey(const Key('drill_numeric')), findsOneWidget);

      // Saved is in the 2nd position (first row, right of Most Mistakes)
      final mistakesPos = tester.getTopLeft(
        find.byKey(const Key('drill_most_mistakes')),
      );
      final savedPos = tester.getTopLeft(find.byKey(const Key('drill_saved')));
      final leastPos = tester.getTopLeft(
        find.byKey(const Key('drill_least_answered')),
      );
      expect(savedPos.dy, closeTo(mistakesPos.dy, 1.0));
      expect(savedPos.dx, greaterThan(mistakesPos.dx));
      expect(savedPos.dy, lessThan(leastPos.dy));

      // Image Questions is right beside Video Questions, and Sign Questions is directly below Video Questions
      final videosPos = tester.getTopLeft(
        find.byKey(const Key('drill_videos')),
      );
      final imagesPos = tester.getTopLeft(
        find.byKey(const Key('drill_images')),
      );
      final signsPos = tester.getTopLeft(find.byKey(const Key('drill_signs')));
      expect(imagesPos.dy, closeTo(videosPos.dy, 1.0));
      expect(imagesPos.dx, greaterThan(videosPos.dx));
      expect(signsPos.dx, closeTo(videosPos.dx, 1.0));
      expect(signsPos.dy, greaterThan(videosPos.dy));

      // Tapping Image Questions launches the 2 image questions (static scene + sign image)
      await tester.tap(find.byKey(const Key('drill_images')));
      await tester.pump();
      expect(launchedRequest?.title, 'Image Questions');
      expect(
        launchedRequest?.questionIds,
        unorderedEquals(['1.2.01-003', '1.4.40-001']),
      );

      // Tapping Sign Questions launches the road sign question
      await tester.tap(find.byKey(const Key('drill_signs')));
      await tester.pump();
      expect(launchedRequest?.title, 'Sign Questions');
      expect(launchedRequest?.questionIds, equals(['1.4.40-001']));

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
