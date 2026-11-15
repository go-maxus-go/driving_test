import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:driving_exam/widgets/question_media_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'QuestionMediaStage opens zoom lightbox with double-tap support on image tap, and positions replay/fullscreen controls below video',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final imageQuestion = Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Danger Teaching',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Basic Forms',
        'question_id': '1.1.01-002',
        'question_number': '1.1.01-002',
        'points': '4 Points',
        'licenses': ['Basic material'],
        'question_text': 'What does this sign mean?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': <Map<String, dynamic>>[],
        'comment': '',
        'local_image_paths': ['assets/images/sample.png'],
        'local_video_paths': <String>[],
      });

      final videoQuestion = Question.fromJson({
        'theme_number': 'Theme 1.2.',
        'theme_name': 'Behavior',
        'chapter_number': '1.2.01 Chapter',
        'chapter_name': 'Passing',
        'question_id': '1.2.01-005',
        'question_number': '1.2.01-005',
        'points': '5 Points',
        'licenses': ['B'],
        'question_text': 'How should you react to the cyclist?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': <Map<String, dynamic>>[],
        'comment': '',
        'local_image_paths': <String>[],
        'local_video_paths': ['assets/videos/sample.mp4'],
      });

      final strings = AppStrings(AppLanguage.en);

      // 1. Image media stage: no overlay zoom icon, tapping opens lightbox
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuestionMediaStage(question: imageQuestion, strings: strings),
          ),
        ),
      );

      // No zoom icon button overlay on image
      expect(find.byIcon(Icons.zoom_in_rounded), findsNothing);

      // Tapping the image opens the full-screen zoom lightbox
      await tester.tap(find.byKey(const Key('question_image_tap_area')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_lightbox_btn')), findsOneWidget);
      expect(find.byKey(const Key('lightbox_double_tap_area')), findsOneWidget);

      // Double tap to zoom 2x
      await tester.tap(find.byKey(const Key('lightbox_double_tap_area')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('lightbox_double_tap_area')));
      await tester.pumpAndSettle();

      final interactiveViewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final matrix = interactiveViewer.transformationController!.value;
      expect(matrix.getMaxScaleOnAxis(), greaterThanOrEqualTo(2.0));

      // Close lightbox
      await tester.tap(find.byKey(const Key('close_lightbox_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close_lightbox_btn')), findsNothing);

      // 2. Video media stage: replay and fullscreen controls are below the video
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuestionMediaStage(
              question: videoQuestion,
              strings: strings,
              enableNativeVideo: false,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const Key('practice_replay_video_btn')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('video_fullscreen_btn')), findsOneWidget);

      // Tap fullscreen button to open fullscreen dialog
      await tester.tap(find.byKey(const Key('video_fullscreen_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('close_fullscreen_video_btn')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('close_fullscreen_video_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close_fullscreen_video_btn')), findsNothing);
    },
  );
}
