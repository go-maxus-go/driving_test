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

  return CatalogRepository.fromQuestions(englishQuestions: [q1En, q2En]);
}

void main() {
  testWidgets(
    'PracticePlayer uses icon buttons for Skip (right arrow) & Retry, auto-expands explanation, keeps numeric keypad stable on input, and shows Continue practice / Back to Menu on completion',
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
              allowContinueSmartBatch: true,
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

      // Skip button is an icon button with right arrow (no text label)
      expect(find.byKey(const Key('skip_question_btn')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('skip_question_btn')),
          matching: find.byIcon(Icons.arrow_forward_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsNothing);

      // No -M badge clutter on header
      expect(find.text('-M'), findsNothing);

      // Select A (correct) and C (wrong), leaving B (correct) unselected
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('option_card_C')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      // Checkboxes remain visible
      expect(find.byIcon(Icons.check_box_rounded), findsNWidgets(2));
      expect(
        find.byIcon(Icons.check_box_outline_blank_rounded),
        findsOneWidget,
      );

      // Badges are displayed with 1-word label for wrong ('Wrong')
      expect(find.byKey(const Key('badge_correct_A')), findsOneWidget);
      expect(find.byKey(const Key('badge_missed_B')), findsOneWidget);
      expect(find.byKey(const Key('badge_wrong_C')), findsOneWidget);
      expect(find.text('Wrong'), findsOneWidget);

      // Explanation card is displayed without Exam Variation Question (-M) box
      expect(find.byKey(const Key('explanation_card')), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(
        find.text('Defensive driving means anticipating mistakes.'),
        findsOneWidget,
      );
      expect(find.textContaining('Exam Variation Question'), findsNothing);

      // Retry button is an icon button (Icons.replay_rounded) with no 'Retry' text
      expect(find.byKey(const Key('retry_question_btn')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('retry_question_btn')),
          matching: find.byIcon(Icons.replay_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);

      await tester.tap(find.byKey(const Key('retry_question_btn')));
      await tester.pump();

      expect(find.byKey(const Key('badge_wrong_C')), findsNothing);
      expect(find.text('Check Answer'), findsOneWidget);

      // Now answer correctly: select A and B -> Explanation is IMMEDIATELY expanded, Retry is still an icon button
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('option_card_B')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.byKey(const Key('badge_correct_A')), findsOneWidget);
      expect(find.byKey(const Key('badge_correct_B')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('retry_question_btn')),
          matching: find.byIcon(Icons.replay_rounded),
        ),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
      expect(find.byKey(const Key('explanation_card')), findsOneWidget);
      expect(
        find.text('Defensive driving means anticipating mistakes.'),
        findsOneWidget,
      );

      // Advance to Question 2 (Numeric Input)
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.text('Minimum tire tread depth in mm?'), findsOneWidget);

      // Previous button (back arrow) is present on Question 2
      expect(find.byKey(const Key('prev_question_btn')), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      await tester.tap(find.byKey(const Key('prev_question_btn')));
      await tester.pump();

      expect(
        find.text('What should you understand by defensive driving?'),
        findsOneWidget,
      );

      // Skip forward via right-arrow icon button to Question 2
      await tester.tap(find.byKey(const Key('skip_question_btn')));
      await tester.pump();

      // Measure display box height & numpad position BEFORE entering first digit
      final boxHeightBefore = tester
          .getSize(find.byKey(const Key('numeric_display_box')))
          .height;
      final keypadTopBefore = tester
          .getTopLeft(find.byKey(const Key('numpad_key_1')))
          .dy;

      // Enter first digit '1' -> display box height and keypad position must NOT jump!
      await tester.tap(find.byKey(const Key('numpad_key_1')));
      await tester.pump();

      final boxHeightAfter = tester
          .getSize(find.byKey(const Key('numeric_display_box')))
          .height;
      final keypadTopAfter = tester
          .getTopLeft(find.byKey(const Key('numpad_key_1')))
          .dy;
      expect(boxHeightAfter, boxHeightBefore);
      expect(keypadTopAfter, keypadTopBefore);

      // Finish entering 1.6 on custom numpad
      await tester.tap(find.byKey(const Key('numpad_key_decimal')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numpad_key_6')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      // Explanation is expanded immediately without needing an extra tap!
      expect(find.text('Minimum legal tread depth is 1.6 mm.'), findsOneWidget);

      // Finish session -> verify Continue practice & Back to Menu (never Cockpit)
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pumpAndSettle();

      expect(find.text('Session Complete!'), findsOneWidget);
      expect(find.text('Continue practice'), findsOneWidget);
      expect(find.text('Back to Menu'), findsOneWidget);
      expect(find.textContaining('25'), findsNothing);
      expect(find.textContaining('Cockpit'), findsNothing);
    },
  );
}
