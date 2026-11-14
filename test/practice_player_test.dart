import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/screens/practice_player_screen.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _buildPlayerTestRepo() {
  final q1En = Question.fromJson({
    'theme_number': 'Theme 1.1.',
    'theme_name': 'Danger Teaching',
    'chapter_number': '1.1.01 Chapter',
    'chapter_name': 'Basic Forms',
    'question_id': '1.1.01-001-M',
    'question_number': '1.1.01-001-M',
    'points': '4 Points',
    'licenses': ['Basic material'],
    'question_text': 'What should you understand by defensive driving?',
    'options': [
      {'letter': 'A.', 'text': 'Not insisting on your rights'},
      {'letter': 'B.', 'text': 'Allowing for others mistakes'},
      {'letter': 'C.', 'text': 'Stopping at every crossroads'},
    ],
    'correct_answers': [
      {'letter': 'A.', 'text': 'Not insisting on your rights'},
      {'letter': 'B.', 'text': 'Allowing for others mistakes'},
    ],
    'comment': 'Defensive driving means anticipating mistakes.',
    'local_image_paths': <String>[],
    'local_video_paths': <String>[],
  });

  final q1De = Question.fromJson({
    'theme_number': 'Thema 1.1.',
    'theme_name': 'Gefahrenlehre',
    'chapter_number': '1.1.01 Kapitel',
    'chapter_name': 'Grundformen',
    'question_id': '1.1.01-001-M',
    'question_number': '1.1.01-001-M',
    'points': '4 Punkte',
    'licenses': ['Grundstoff'],
    'question_text': 'Was versteht man unter defensivem Fahren?',
    'options': [
      {'letter': 'A.', 'text': 'Nicht auf dem eigenen Recht bestehen'},
      {'letter': 'B.', 'text': 'Mit Fehlern anderer rechnen'},
      {'letter': 'C.', 'text': 'An jeder Kreuzung anhalten'},
    ],
    'correct_answers': [
      {'letter': 'A.', 'text': 'Nicht auf dem eigenen Recht bestehen'},
      {'letter': 'B.', 'text': 'Mit Fehlern anderer rechnen'},
    ],
    'comment': 'Defensives Fahren bedeutet vorausschauend fahren.',
    'local_image_paths': <String>[],
    'local_video_paths': <String>[],
  });

  final q2En = Question.fromJson({
    'theme_number': 'Theme 2.7.',
    'theme_name': 'Technology',
    'chapter_number': '2.7.01 Chapter',
    'chapter_name': 'Tires',
    'question_id': '2.7.01-010',
    'question_number': '2.7.01-010',
    'points': '3 Points',
    'licenses': ['B'],
    'question_text': 'Minimum tire tread depth in mm?',
    'options': <Map<String, dynamic>>[],
    'correct_answers': [
      {'letter': '1,6', 'text': ''},
    ],
    'comment': 'Minimum legal tread depth is 1.6 mm.',
    'local_image_paths': <String>[],
    'local_video_paths': <String>[],
  });

  final q2De = Question.fromJson({
    'theme_number': 'Thema 2.7.',
    'theme_name': 'Technik',
    'chapter_number': '2.7.01 Kapitel',
    'chapter_name': 'Reifen',
    'question_id': '2.7.01-010',
    'question_number': '2.7.01-010',
    'points': '3 Punkte',
    'licenses': ['B'],
    'question_text': 'Mindestprofiltiefe der Reifen in mm?',
    'options': <Map<String, dynamic>>[],
    'correct_answers': [
      {'letter': '1,6', 'text': ''},
    ],
    'comment': 'Die gesetzliche Mindestprofiltiefe beträgt 1,6 mm.',
    'local_image_paths': <String>[],
    'local_video_paths': <String>[],
  });

  return CatalogRepository.fromQuestions(
    englishQuestions: [q1En, q2En],
    germanQuestions: [q1De, q2De],
  );
}

void main() {
  testWidgets(
    'PracticePlayer highlights 4 option states, auto-expands explanation on error, peeks DE translation, and normalizes custom numpad',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = AppController(
        catalog: _buildPlayerTestRepo(),
        storage: InMemoryProgressStorage(),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: PracticePlayerScreen(
            controller: controller,
            enableNativeVideo: false,
            request: const PracticeLaunchRequest(
              title: 'Practice',
              questionIds: ['1.1.01-001-M', '2.7.01-010'],
            ),
          ),
        ),
      );

      // Initial live session counter: 0 right, 0 wrong, 2 left
      expect(find.byKey(const Key('session_correct_count')), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('session_remaining_count')))
            .data,
        '2 left',
      );

      // Peek German translation inline in 1 tap
      await tester.tap(find.byKey(const Key('peek_translation_btn')));
      await tester.pump();
      expect(
        find.text('Was versteht man unter defensivem Fahren?'),
        findsOneWidget,
      );

      // Select A (correct) and C (wrong), missing B (correct)
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('option_card_C')));
      await tester.pump();

      // Submit via fixed-coordinate primary CTA
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      // Verify all 3 active feedback badges & auto-expanded explanation + -M notice
      expect(find.byKey(const Key('badge_correct_A')), findsOneWidget);
      expect(find.byKey(const Key('badge_missed_B')), findsOneWidget);
      expect(find.byKey(const Key('badge_wrong_C')), findsOneWidget);
      expect(find.byKey(const Key('explanation_card')), findsOneWidget);
      expect(
        find.text('Defensive driving means anticipating mistakes.'),
        findsOneWidget,
      );
      expect(find.text('Exam Variation Question (-M)'), findsOneWidget);

      // Counter updated: 0 correct, 1 wrong, 1 left
      expect(
        tester.widget<Text>(find.byKey(const Key('session_wrong_count'))).data,
        '1',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('session_remaining_count')))
            .data,
        '1 left',
      );

      // Advance to Question 2 (Numeric Input) by tapping the same primary CTA
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.text('Minimum tire tread depth in mm?'), findsOneWidget);
      expect(find.text('Mindestprofiltiefe der Reifen in mm?'), findsOneWidget);

      // Enter 1.6 on custom ergonomic numpad (matches expected "1,6")
      await tester.tap(find.byKey(const Key('numpad_key_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numpad_key_decimal')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numpad_key_6')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.text('Correctly answered!'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const Key('session_correct_count')))
            .data,
        '1',
      );
      expect(
        tester
            .widget<Text>(find.byKey(const Key('session_remaining_count')))
            .data,
        '0 left',
      );

      // Explanation can be expanded on demand in 1 tap when answered right
      await tester.tap(find.byKey(const Key('expand_explanation_chip')));
      await tester.pump();
      expect(find.text('Minimum legal tread depth is 1.6 mm.'), findsOneWidget);
    },
  );
}
