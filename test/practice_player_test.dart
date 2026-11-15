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
    'PracticePlayer highlights options with checkboxes, retry/previous navigation, and clean explanation without points clutter',
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

      // 1. Language selector is not present in practice player AppBar
      expect(find.byKey(const Key('peek_translation_btn')), findsNothing);

      // 2. Select A (correct) and C (wrong), leaving B (correct) unselected
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('option_card_C')));
      await tester.pump();

      // Submit via fixed-coordinate primary CTA
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      // 3. Checkboxes remain visible:
      // A (selected) -> check_box_rounded
      // C (selected) -> check_box_rounded
      // B (unselected) -> check_box_outline_blank_rounded
      expect(find.byIcon(Icons.check_box_rounded), findsNWidgets(2));
      expect(
        find.byIcon(Icons.check_box_outline_blank_rounded),
        findsOneWidget,
      );

      // 4. Badges are displayed with 1-word label for wrong ('Wrong')
      expect(find.byKey(const Key('badge_correct_A')), findsOneWidget);
      expect(find.byKey(const Key('badge_missed_B')), findsOneWidget);
      expect(find.byKey(const Key('badge_wrong_C')), findsOneWidget);
      expect(find.text('Wrong'), findsOneWidget);

      // 5. No "+4 Error Points" banner during practice (clean learning view)
      expect(find.textContaining('Error Points'), findsNothing);

      // 6. Explanation card is displayed with clean header 'Explanation'
      expect(find.byKey(const Key('explanation_card')), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(
        find.text('Defensive driving means anticipating mistakes.'),
        findsOneWidget,
      );
      expect(find.text('Exam Variation Question (-M)'), findsOneWidget);

      // 7. Counter updated: 0 correct, 1 wrong, 1 left
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

      // 8. Retry button is available to re-answer the same question
      expect(find.byKey(const Key('retry_question_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry_question_btn')));
      await tester.pump();

      // State is reset: submit button is back, badges gone
      expect(find.byKey(const Key('badge_wrong_C')), findsNothing);
      expect(find.text('Check Answer'), findsOneWidget);

      // Now answer correctly: select A and B
      await tester.tap(find.byKey(const Key('option_card_A')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('option_card_B')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.byKey(const Key('badge_correct_A')), findsOneWidget);
      expect(find.byKey(const Key('badge_correct_B')), findsOneWidget);

      // 9. Advance to Question 2 (Numeric Input)
      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      expect(find.text('Minimum tire tread depth in mm?'), findsOneWidget);

      // 10. Previous button is present on Question 2
      expect(find.byKey(const Key('prev_question_btn')), findsOneWidget);
      await tester.tap(find.byKey(const Key('prev_question_btn')));
      await tester.pump();

      // Back on Question 1!
      expect(
        find.text('What should you understand by defensive driving?'),
        findsOneWidget,
      );

      // Skip forward to Question 2
      await tester.tap(find.byKey(const Key('skip_question_btn')));
      await tester.pump();

      // Enter 1.6 on custom numpad (matches expected "1,6")
      await tester.tap(find.byKey(const Key('numpad_key_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numpad_key_decimal')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('numpad_key_6')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('primary_practice_cta')));
      await tester.pump();

      // Explanation can be expanded on demand in 1 tap when answered right
      await tester.tap(find.byKey(const Key('expand_explanation_chip')));
      await tester.pump();
      expect(find.text('Minimum legal tread depth is 1.6 mm.'), findsOneWidget);
    },
  );
}
