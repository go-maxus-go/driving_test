import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:driving_exam/widgets/question_media_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

class _FakeVideoPlayerController extends VideoPlayerController {
  _FakeVideoPlayerController() : super.asset('assets/videos/sample.mp4');

  int playCalls = 0;
  int seekZeroCalls = 0;

  @override
  Future<void> initialize() async {
    value = const VideoPlayerValue(
      duration: Duration(seconds: 10),
      size: Size(1280, 720),
      isInitialized: true,
    );
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> play() async {
    playCalls++;
    value = value.copyWith(isPlaying: true, isCompleted: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (position == Duration.zero) {
      seekZeroCalls++;
    }
    value = value.copyWith(position: position, isCompleted: false);
  }

  void simulateEnded() {
    value = value.copyWith(
      position: const Duration(seconds: 10),
      isPlaying: false,
      isCompleted: true,
    );
  }
}

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
      expect(2.0 * tapped.dx + tx, closeTo(viewport.width / 2, 1e-6));
      expect(2.0 * tapped.dy + ty, closeTo(viewport.height / 2, 1e-6));
    },
  );

  testWidgets(
    'QuestionMediaStage uses square cards, replays video on tap when stopped at end, and renders top-left fullscreen replay button',
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

      // 1. Image media stage: white square-cornered surface, no overlay zoom icon
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
      expect(inlineDeco.borderRadius, BorderRadius.zero);

      // Tapping the image opens the full-screen zoom lightbox
      await tester.tap(find.byKey(const Key('question_image_tap_area')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_lightbox_btn')), findsOneWidget);
      final lightboxSurface = tester.widget<Container>(
        find.byKey(const Key('lightbox_image_surface')),
      );
      final lightboxDeco = lightboxSurface.decoration! as BoxDecoration;
      expect(lightboxDeco.color, Colors.white);
      expect(lightboxDeco.borderRadius, BorderRadius.zero);

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

      // 2. Video media stage: square-cornered surface, tap-to-replay when stopped at end,
      //    and fullscreen top-left Replay button + top-right Close button
      late _FakeVideoPlayerController fakeVideoCtrl;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: QuestionMediaStage(
              question: videoQuestion,
              strings: strings,
              enableNativeVideo: false,
              videoControllerBuilder: (_) {
                fakeVideoCtrl = _FakeVideoPlayerController();
                return fakeVideoCtrl;
              },
            ),
          ),
        ),
      );
      await tester.pump();

      final videoSurface = tester.widget<Container>(
        find.byKey(const Key('question_video_surface')),
      );
      final videoDeco = videoSurface.decoration! as BoxDecoration;
      expect(videoDeco.borderRadius, BorderRadius.zero);

      // Initial autoplay started once
      expect(fakeVideoCtrl.playCalls, 1);
      expect(fakeVideoCtrl.seekZeroCalls, 0);

      // Tapping while video is STILL playing does NOT restart the clip
      await tester.tap(find.byKey(const Key('question_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.playCalls, 1);
      expect(fakeVideoCtrl.seekZeroCalls, 0);

      // Once video stops at the end, tapping on the video plays it again
      fakeVideoCtrl.simulateEnded();
      await tester.pump();
      await tester.tap(find.byKey(const Key('question_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.seekZeroCalls, 1);
      expect(fakeVideoCtrl.playCalls, 2);

      // Open fullscreen video
      await tester.tap(find.byKey(const Key('video_fullscreen_btn')));
      await tester.pumpAndSettle();

      // Verify top-left Replay button and top-right Close button
      final replayFinder = find.byKey(const Key('replay_fullscreen_video_btn'));
      final closeFinder = find.byKey(const Key('close_fullscreen_video_btn'));
      expect(replayFinder, findsOneWidget);
      expect(closeFinder, findsOneWidget);
      expect(find.byType(RotatedBox), findsNothing);

      final replayTopLeft = tester.getTopLeft(replayFinder);
      final closeTopRight = tester.getTopRight(closeFinder);
      expect(replayTopLeft.dx, lessThan(80));
      expect(closeTopRight.dx, greaterThan(330));
      expect(replayTopLeft.dy, closeTo(closeTopRight.dy, 1.0));

      // Tapping top-left Replay button replays the video immediately
      await tester.tap(replayFinder);
      await tester.pump();
      expect(fakeVideoCtrl.seekZeroCalls, 2);
      expect(fakeVideoCtrl.playCalls, 3);

      // Tapping fullscreen video surface when ended also replays the video
      fakeVideoCtrl.simulateEnded();
      await tester.pump();
      await tester.tap(find.byKey(const Key('fullscreen_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.seekZeroCalls, 3);
      expect(fakeVideoCtrl.playCalls, 4);

      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(closeFinder, findsNothing);
    },
  );
}
