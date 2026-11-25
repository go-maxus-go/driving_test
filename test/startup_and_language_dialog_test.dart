import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/main.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:driving_exam/widgets/app_loading_screen.dart';
import 'package:driving_exam/widgets/first_launch_language_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _buildMinimalRepo() {
  final q = Question.fromJson({
    'theme_number': 'Theme 1.1.',
    'theme_name': 'Basic Rules',
    'chapter_number': '1.1.01 Chapter',
    'chapter_name': 'Speed',
    'question_id': '1.1.01-001',
    'question_number': '1.1.01-001',
    'points': '3 Points',
    'licenses': ['Basic material'],
    'question_text': 'What is the default speed limit in built-up areas?',
    'options': [
      {'letter': 'A.', 'text': '50 km/h'},
      {'letter': 'B.', 'text': '100 km/h'},
    ],
    'correct_answers': [
      {'letter': 'A.', 'text': '50 km/h'},
    ],
    'comment': '50 km/h is the general limit.',
    'local_image_paths': <String>[],
    'local_video_paths': <String>[],
  });
  return CatalogRepository.fromQuestions(englishQuestions: [q]);
}

void main() {
  testWidgets('AppLoadingScreen displays branded icon and progress indicator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppLoadingScreen(statusText: 'Loading test...'),
      ),
    );

    expect(find.text('Führerschein Klasse B'), findsOneWidget);
    expect(find.text('German Driving Theory Trainer'), findsOneWidget);
    expect(find.text('Loading test...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'configureSystemUi keeps the system status bar visible via edgeToEdge on Android and iOS',
    (WidgetTester tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      await configureSystemUi();
      expect(
        calls.where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode'),
        isEmpty,
      );

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await configureSystemUi();
      expect(
        calls.any(
          (c) =>
              c.method == 'SystemChrome.setEnabledSystemUIMode' &&
              c.arguments == 'SystemUiMode.edgeToEdge',
        ),
        isTrue,
      );
      expect(
        calls.any((c) => c.arguments == 'SystemUiMode.immersiveSticky'),
        isFalse,
      );

      calls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await configureSystemUi();
      expect(
        calls.any(
          (c) =>
              c.method == 'SystemChrome.setEnabledSystemUIMode' &&
              c.arguments == 'SystemUiMode.edgeToEdge',
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'FirstLaunchLanguageDialog prompts on first launch with English default and German optional',
    (WidgetTester tester) async {
      final controller = AppController(
        catalog: _buildMinimalRepo(),
        storage: InMemoryProgressStorage(
          const PersistedUserData(hasChosenLanguage: false),
        ),
      );

      await tester.pumpWidget(
        DrivingExamApp(controller: controller, enableNativeVideo: false),
      );
      await tester.pumpAndSettle();

      // Dialog opens automatically
      expect(find.byType(FirstLaunchLanguageDialog), findsOneWidget);
      expect(find.text('Choose your study language'), findsOneWidget);

      // Select German
      await tester.tap(find.byKey(const Key('first_launch_lang_de')));
      await tester.pump();

      // Tap Continue
      await tester.tap(find.byKey(const Key('first_launch_continue_btn')));
      await tester.pumpAndSettle();

      // Dialog closes and German is saved
      expect(find.byType(FirstLaunchLanguageDialog), findsNothing);
      expect(controller.language, AppLanguage.de);
      expect(controller.hasChosenLanguage, isTrue);
    },
  );
}
