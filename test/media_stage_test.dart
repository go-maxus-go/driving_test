import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:driving_exam/widgets/question_media_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test(
    'computeDoubleTapZoomMatrix centers the tapped point inside the viewport',
    () {
      const viewport = Size(400, 800);
      const tapped = Offset(260, 500);
      final matrix = computeDoubleTapZoomMatrix(
        tapPosition: tapped,
        viewportSize: viewport,
      );

      expect(matrix.getMaxScaleOnAxis(), closeTo(2.0, 1e-6));
      final tx = matrix.getTranslation().x;
      final ty = matrix.getTranslation().y;
      // Transformed point = scale * tapped + translation == viewport center (200, 400)
      expect(2.0 * tapped.dx + tx, closeTo(viewport.width / 2, 1e-6));
      expect(2.0 * tapped.dy + ty, closeTo(viewport.height / 2, 1e-6));
    },
  );

  testWidgets(
    'QuestionMediaStage renders signs on white surface, centers double-tap zoom, and keeps fullscreen video unrotated',
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

      // 1. Image media stage: white background surface, no overlay zoom icon
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuestionMediaStage(question: imageQuestion, strings: strings),
          ),
        ),
      );

      expect(find.byIcon(Icons.zoom_in_rounded), findsNothing);
      final inlineSurface = tester.widget<Container>(
        find.byKey(const Key('question_image_surface')),
      );
      final inlineDeco = inlineSurface.decoration! as BoxDecoration;
      expect(inlineDeco.color, Colors.white);

      // Tapping the image opens the full-screen zoom lightbox
      await tester.tap(find.byKey(const Key('question_image_tap_area')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_lightbox_btn')), findsOneWidget);
      final lightboxSurface = tester.widget<Container>(
        find.byKey(const Key('lightbox_image_surface')),
      );
      expect(
        (lightboxSurface.decoration! as BoxDecoration).color,
        Colors.white,
      );

      // Double tap at an off-center coordinate (280, 540) to zoom 2x centered there
      const tapTarget = Offset(280, 540);
      await tester.tapAt(tapTarget);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(tapTarget);
      await tester.pumpAndSettle();

      final interactiveViewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final matrix = interactiveViewer.transformationController!.value;
      expect(matrix.getMaxScaleOnAxis(), closeTo(2.0, 1e-6));
      final viewerBox = tester.getSize(find.byType(InteractiveViewer));
      expect(
        2.0 * tapTarget.dx + matrix.getTranslation().x,
        closeTo(viewerBox.width / 2, 1.0),
      );
      expect(
        2.0 * tapTarget.dy + matrix.getTranslation().y,
        closeTo(viewerBox.height / 2, 1.0),
      );

      // Close lightbox via subtle outlined button
      await tester.tap(find.byKey(const Key('close_lightbox_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close_lightbox_btn')), findsNothing);

      // 2. Video media stage: fullscreen opens without RotatedBox even in portrait
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

      await tester.tap(find.byKey(const Key('video_fullscreen_btn')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('close_fullscreen_video_btn')),
        findsOneWidget,
      );
      expect(find.byType(RotatedBox), findsNothing);

      await tester.tap(find.byKey(const Key('close_fullscreen_video_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('close_fullscreen_video_btn')), findsNothing);
    },
  );
}
