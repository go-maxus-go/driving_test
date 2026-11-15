import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/services/media_cache_service.dart';
import 'package:driving_exam/services/media_store.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:driving_exam/widgets/answer_option_card.dart';
import 'package:driving_exam/widgets/media_cache_scope.dart';
import 'package:driving_exam/widgets/question_media_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

final Uint8List _kOneByOnePng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

class _FakeVideoPlayerController extends VideoPlayerController {
  _FakeVideoPlayerController() : super.asset('assets/videos/sample.mp4');

  int playCalls = 0;
  int pauseCalls = 0;
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
  Future<void> pause() async {
    pauseCalls++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    if (position == Duration.zero) {
      seekZeroCalls++;
    }
    value = value.copyWith(position: position, isCompleted: false);
  }

  void simulateProgress(Duration position) {
    value = value.copyWith(
      position: position,
      isPlaying: true,
      isCompleted: false,
    );
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
      expect(find.byType(VideoProgressIndicator), findsNothing);

      // Initial autoplay started once (after initial seekTo(Duration.zero))
      expect(fakeVideoCtrl.playCalls, 1);
      final baselineSeekZero = fakeVideoCtrl.seekZeroCalls;

      // Tapping while video is STILL playing does NOT restart the clip
      await tester.tap(find.byKey(const Key('question_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.playCalls, 1);
      expect(fakeVideoCtrl.seekZeroCalls, baselineSeekZero);

      // Once video stops at the end, tapping on the video plays it again
      fakeVideoCtrl.simulateEnded();
      await tester.pump();
      await tester.tap(find.byKey(const Key('question_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.seekZeroCalls, baselineSeekZero + 1);
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
      expect(fakeVideoCtrl.seekZeroCalls, baselineSeekZero + 2);
      expect(fakeVideoCtrl.playCalls, 3);

      // Tapping fullscreen video surface when ended also replays the video
      fakeVideoCtrl.simulateEnded();
      await tester.pump();
      await tester.tap(find.byKey(const Key('fullscreen_video_tap_area')));
      await tester.pump();
      expect(fakeVideoCtrl.seekZeroCalls, baselineSeekZero + 3);
      expect(fakeVideoCtrl.playCalls, 4);

      await tester.tap(closeFinder);
      await tester.pumpAndSettle();
      expect(closeFinder, findsNothing);
    },
  );

  testWidgets(
    'Uncached question images, sign options, and videos show loading indicators while downloading and render once loaded',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final imageCompleter = Completer<Uint8List>();
      final signCompleter = Completer<Uint8List>();
      final videoCompleter = Completer<Uint8List>();

      final cache = MediaCacheService(
        store: InMemoryMediaStore(),
        fetcher: (uri) {
          if (uri.path.endsWith('lazy_scene.png')) {
            return imageCompleter.future;
          }
          if (uri.path.endsWith('lazy_sign.png')) {
            return signCompleter.future;
          }
          if (uri.path.endsWith('lazy_clip.mp4')) {
            return videoCompleter.future;
          }
          return Future<Uint8List>.value(_kOneByOnePng);
        },
      );
      addTearDown(cache.dispose);

      final strings = AppStrings(AppLanguage.en);
      final imageQuestion = Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Danger Teaching',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Basic Forms',
        'question_id': '1.1.01-010',
        'question_number': '1.1.01-010',
        'points': '3 Points',
        'licenses': ['Basic material'],
        'question_text': 'Which sign applies here?',
        'options': <Map<String, dynamic>>[
          {'letter': 'A.', 'text': 'Option A'},
        ],
        'correct_answers': <Map<String, dynamic>>[
          {'letter': 'A.', 'text': 'Option A'},
        ],
        'comment': '',
        'local_image_paths': ['assets/images/lazy_scene.png'],
        'local_video_paths': <String>[],
      });
      const signOption = QuestionOption(
        letter: 'A',
        text: '',
        imageAssetPath: 'assets/images/lazy_sign.png',
      );

      await tester.pumpWidget(
        MediaCacheScope(
          cache: cache,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Column(
                children: [
                  QuestionMediaStage(question: imageQuestion, strings: strings),
                  AnswerOptionCard(
                    option: signOption,
                    isSelected: false,
                    strings: strings,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Both the uncached main image and sign option show loading indicators
      expect(find.byKey(const Key('image_loading_indicator')), findsOneWidget);
      expect(find.byKey(const Key('option_sign_loading_A')), findsOneWidget);
      expect(cache.activeUrgentCount, greaterThanOrEqualTo(2));

      // Complete the downloads -> spinners disappear and MemoryImage widgets render
      imageCompleter.complete(_kOneByOnePng);
      signCompleter.complete(_kOneByOnePng);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('image_loading_indicator')), findsNothing);
      expect(find.byKey(const Key('option_sign_loading_A')), findsNothing);
      expect(find.byType(Image), findsNWidgets(2));
      expect(cache.activeUrgentCount, 0);

      // Now open an uncached video question -> shows video loading indicator
      // with urgent download priority, including inside fullscreen
      final videoQuestion = Question.fromJson({
        'theme_number': 'Theme 1.2.',
        'theme_name': 'Behavior',
        'chapter_number': '1.2.01 Chapter',
        'chapter_name': 'Passing',
        'question_id': '1.2.01-099',
        'question_number': '1.2.01-099',
        'points': '5 Points',
        'licenses': ['B'],
        'question_text': 'Watch the traffic situation.',
        'options': <Map<String, dynamic>>[],
        'correct_answers': <Map<String, dynamic>>[],
        'comment': '',
        'local_image_paths': <String>[],
        'local_video_paths': ['assets/videos/lazy_clip.mp4'],
      });

      _FakeVideoPlayerController? createdVideoCtrl;
      await tester.pumpWidget(
        MediaCacheScope(
          cache: cache,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: QuestionMediaStage(
                question: videoQuestion,
                strings: strings,
                enableNativeVideo: false,
                videoControllerBuilder: (_) {
                  createdVideoCtrl = _FakeVideoPlayerController();
                  return createdVideoCtrl!;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('video_loading_indicator')), findsOneWidget);
      expect(createdVideoCtrl, isNull);
      expect(cache.activeUrgentCount, 1);

      // Opening fullscreen while video is still downloading shows fullscreen loading indicator
      await tester.tap(find.byKey(const Key('video_fullscreen_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('fullscreen_video_loading_indicator')),
        findsOneWidget,
      );

      // Finish downloading the video -> transitions automatically to playing VideoPlayer!
      videoCompleter.complete(Uint8List.fromList([0, 0, 0, 24, 102, 116]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byKey(const Key('fullscreen_video_loading_indicator')),
        findsNothing,
      );
      expect(find.byKey(const Key('video_loading_indicator')), findsNothing);
      expect(createdVideoCtrl, isNotNull);
      expect(createdVideoCtrl!.playCalls, 1);
      expect(cache.activeUrgentCount, 0);
    },
  );

  testWidgets(
    'Answering a video question stops at the first frame without progress bar, and reopening plays from cache without re-downloading',
    (WidgetTester tester) async {
      var videoFetchCount = 0;
      final cache = MediaCacheService(
        store: InMemoryMediaStore(),
        fetcher: (uri) async {
          if (uri.path.endsWith('cached_once.mp4')) {
            videoFetchCount++;
          }
          return Uint8List.fromList([0, 0, 0, 24, 102, 116, 121, 112]);
        },
      );
      addTearDown(cache.dispose);

      final strings = AppStrings(AppLanguage.en);
      final videoQuestion = Question.fromJson({
        'theme_number': 'Theme 1.2.',
        'theme_name': 'Behavior',
        'chapter_number': '1.2.01 Chapter',
        'chapter_name': 'Passing',
        'question_id': '1.2.01-077',
        'question_number': '1.2.01-077',
        'points': '5 Points',
        'licenses': ['B'],
        'question_text': 'What should you expect?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': <Map<String, dynamic>>[],
        'comment': '',
        'local_image_paths': <String>[],
        'local_video_paths': ['assets/videos/cached_once.mp4'],
      });
      final textQuestion = Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Rules',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Basics',
        'question_id': '1.1.01-001',
        'question_number': '1.1.01-001',
        'points': '2 Points',
        'licenses': ['Basic material'],
        'question_text': 'Text only question?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': <Map<String, dynamic>>[],
        'comment': '',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      });

      late _FakeVideoPlayerController activeCtrl;
      Widget buildHost({required Question q, required bool isAnswered}) {
        return MediaCacheScope(
          cache: cache,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: QuestionMediaStage(
                question: q,
                strings: strings,
                isAnswered: isAnswered,
                enableNativeVideo: false,
                videoControllerBuilder: (_) {
                  activeCtrl = _FakeVideoPlayerController();
                  return activeCtrl;
                },
              ),
            ),
          ),
        );
      }

      // 1. Open video question first time -> downloads once and starts playing
      await tester.pumpWidget(buildHost(q: videoQuestion, isAnswered: false));
      await tester.pumpAndSettle();

      expect(videoFetchCount, 1);
      expect(activeCtrl.playCalls, 1);
      expect(activeCtrl.value.isPlaying, isTrue);
      expect(find.byType(VideoProgressIndicator), findsNothing);

      // Simulate playback mid-stream, then answer the question
      activeCtrl.simulateProgress(const Duration(seconds: 4));
      await tester.pumpWidget(buildHost(q: videoQuestion, isAnswered: true));
      await tester.pumpAndSettle();

      // Video stops at the first frame (Duration.zero) and shows NO horizontal progress bar
      expect(activeCtrl.pauseCalls, 1);
      expect(activeCtrl.value.isPlaying, isFalse);
      expect(activeCtrl.value.position, Duration.zero);
      expect(find.byType(VideoProgressIndicator), findsNothing);

      // 2. Navigate to another question and come back -> plays again WITHOUT re-downloading!
      await tester.pumpWidget(buildHost(q: textQuestion, isAnswered: false));
      await tester.pumpAndSettle();

      await tester.pumpWidget(buildHost(q: videoQuestion, isAnswered: false));
      await tester.pumpAndSettle();

      expect(videoFetchCount, 1);
      expect(activeCtrl.playCalls, 1);
      expect(activeCtrl.value.isPlaying, isTrue);
      expect(find.byType(VideoProgressIndicator), findsNothing);
    },
  );
}
