import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/screens/topics_screen.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _buildTopicsRepo() {
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
      'points': '3 Points',
      'licenses': [themeCode.startsWith('1.') ? 'Basic material' : 'B'],
      'question_text': 'Question $id about $chName',
      'options': [
        {'letter': 'A.', 'text': 'Right'},
        {'letter': 'B.', 'text': 'Wrong'},
      ],
      'correct_answers': [
        {'letter': 'A.', 'text': 'Right'},
      ],
      'comment': 'Explanation',
      'local_image_paths': <String>[],
      'local_video_paths': <String>[],
    });
  }

  final list = [
    makeQ(
      '1.1.01-001',
      '1.1',
      'Danger Teaching',
      '1.1.01',
      'Basic Traffic Forms',
    ),
    makeQ('1.3.01-001', '1.3', 'Priority', '1.3.01', 'Right before Left'),
    makeQ('2.7.01-001', '2.7', 'Technology', '2.7.01', 'Braking Systems'),
  ];
  return CatalogRepository.fromQuestions(englishQuestions: list);
}

void main() {
  testWidgets(
    'TopicsScreen supports 1-tap theme start, chapter accordion, section filter, multi-select, and formulas modal',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      PracticeLaunchRequest? lastLaunch;
      final controller = AppController(
        catalog: _buildTopicsRepo(),
        storage: InMemoryProgressStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: TopicsScreen(
              controller: controller,
              onStartPractice: (req) => lastLaunch = req,
            ),
          ),
        ),
      );

      // All 3 themes visible
      expect(find.text('1.1 • Danger Teaching'), findsOneWidget);
      expect(find.text('1.3 • Priority'), findsOneWidget);
      expect(find.text('2.7 • Technology'), findsOneWidget);

      // 1-tap launch Priority theme
      await tester.tap(find.byKey(const Key('start_theme_1.3')));
      await tester.pump();
      expect(lastLaunch?.questionIds, ['1.3.01-001']);

      // Expand chapters of 1.1 and tap chapter row
      await tester.tap(find.byKey(const Key('expand_theme_1.1')));
      await tester.pump();
      expect(find.text('1.1.01 • Basic Traffic Forms'), findsOneWidget);
      await tester.tap(find.byKey(const Key('chapter_row_1.1.01')));
      await tester.pump();
      expect(lastLaunch?.questionIds, ['1.1.01-001']);

      // Filter Class B Add-on only -> hides 1.1 & 1.3, shows 2.7
      await tester.tap(find.byKey(const Key('filter_classb_chip')));
      await tester.pump();
      expect(find.text('1.3 • Priority'), findsNothing);
      expect(find.text('2.7 • Technology'), findsOneWidget);

      // Back to All + Multi-select two themes
      await tester.tap(find.byKey(const Key('filter_all_chip')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('multi_select_topics_btn')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('theme_card_1.3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('theme_card_2.7')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('start_multi_topics_btn')));
      await tester.pump();
      expect(lastLaunch?.questionIds.toSet(), {'1.3.01-001', '2.7.01-001'});

      // Open Formulas cheat-sheet modal
      await tester.tap(find.byKey(const Key('open_formulas_btn')));
      await tester.pumpAndSettle();
      expect(
        find.text('Essential German Driving Formulas & Limits'),
        findsOneWidget,
      );
    },
  );
}
