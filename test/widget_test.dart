import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/main.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/about_screen.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/screens/settings_screen.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _sampleRepo() {
  Question q(String id, String textEn, String textDe, int pts) =>
      Question.fromJson({
        'theme_number': 'Theme 1.1.',
        'theme_name': 'Danger Teaching',
        'chapter_number': '1.1.01 Chapter',
        'chapter_name': 'Basic Traffic Forms',
        'question_id': id,
        'question_number': id,
        'points': '$pts Points',
        'licenses': ['Basic material'],
        'question_text': textEn,
        'options': [
          {'letter': 'A.', 'text': 'Opt A'},
          {'letter': 'B.', 'text': 'Opt B'},
        ],
        'correct_answers': [
          {'letter': 'A.', 'text': 'Opt A'},
        ],
        'comment': 'Comment for $id',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      });

  final en = [
    q('1.1.01-001', 'English Q1', 'Deutsch F1', 5),
    q('1.1.01-002', 'English Q2', 'Deutsch F2', 3),
  ];
  final de = [
    q('1.1.01-001', 'Deutsch F1', 'Deutsch F1', 5),
    q('1.1.01-002', 'Deutsch F2', 'Deutsch F2', 3),
  ];
  return CatalogRepository.fromQuestions(
    englishQuestions: en,
    germanQuestions: de,
  );
}

void main() {
  testWidgets(
    'AppShell provides clean burger menu drawer navigation, Settings screen, and About screen without bottom navigation bar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      PracticeLaunchRequest? launchedRequest;
      final controller = AppController(
        catalog: _sampleRepo(),
        storage: InMemoryProgressStorage(),
      );

      await tester.pumpWidget(
        DrivingExamApp(
          controller: controller,
          promptFirstLaunchLanguage: false,
          onOpenPractice: (_, req) => launchedRequest = req,
        ),
      );

      // No bottom bar on screen
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const Key('burger_menu_btn')), findsOneWidget);

      // Tap Smart Practice launches batch
      await tester.tap(find.byKey(const Key('smart_practice_cta')));
      await tester.pump();
      expect(launchedRequest, isNotNull);
      expect(launchedRequest!.questionIds.length, 2);

      // Open burger menu drawer
      await tester.tap(find.byKey(const Key('burger_menu_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('app_drawer')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_train')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_topics')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_progress')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_formulas')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_settings')), findsOneWidget);
      expect(find.byKey(const Key('drawer_nav_about')), findsOneWidget);

      // Open Settings Screen from drawer
      await tester.tap(find.byKey(const Key('drawer_nav_settings')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);

      // Switch language to German in Settings
      await tester.tap(find.byKey(const Key('settings_lang_de')));
      await tester.pump();
      expect(controller.language, AppLanguage.de);

      // Toggle dark mode in Settings
      await tester.tap(find.byKey(const Key('settings_dark_mode_switch')));
      await tester.pump();
      expect(controller.isDarkMode, isTrue);

      // Pop Settings
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open burger menu drawer again and open About Screen
      await tester.tap(find.byKey(const Key('burger_menu_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drawer_nav_about')));
      await tester.pumpAndSettle();

      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open burger menu drawer and tap Topics
      await tester.tap(find.byKey(const Key('burger_menu_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drawer_nav_topics')));
      await tester.pumpAndSettle();

      expect(find.text(controller.strings.navTopics), findsOneWidget);
    },
  );
}
