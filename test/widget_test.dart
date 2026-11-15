import 'dart:async';
import 'dart:typed_data';

import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/main.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/about_screen.dart';
import 'package:driving_exam/screens/formulas_screen.dart';
import 'package:driving_exam/screens/home_screen.dart';
import 'package:driving_exam/screens/settings_screen.dart';
import 'package:driving_exam/services/media_cache_service.dart';
import 'package:driving_exam/services/media_store.dart';
import 'package:driving_exam/services/progress_storage.dart';
import 'package:driving_exam/state/app_controller.dart';
import 'package:driving_exam/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

CatalogRepository _sampleRepo({int count = 40, bool withMedia = false}) {
  Question q(int idx, String id, String textEn, int pts) => Question.fromJson({
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
    'local_image_paths': withMedia && idx <= 2
        ? <String>['assets/images/q_$idx.png']
        : <String>[],
    'local_video_paths': withMedia && idx == 3
        ? <String>['assets/videos/q_$idx.mp4']
        : <String>[],
  });

  final en = <Question>[];
  final de = <Question>[];
  for (var i = 1; i <= count; i++) {
    final id = '1.1.01-${i.toString().padLeft(3, '0')}';
    en.add(q(i, id, 'English Q$i', i == 1 ? 5 : 3));
    de.add(q(i, id, 'Deutsch F$i', i == 1 ? 5 : 3));
  }
  return CatalogRepository.fromQuestions(
    englishQuestions: en,
    germanQuestions: de,
  );
}

void main() {
  testWidgets(
    'AppShell provides clean burger menu drawer navigation, Formulas screen, Settings screen with configurable batch size (default 30), and About screen without bottom navigation bar',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      PracticeLaunchRequest? launchedRequest;
      final controller = AppController(
        catalog: _sampleRepo(count: 40),
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

      // Tap Smart Practice launches default 30-question batch (matching exam size)
      await tester.tap(find.byKey(const Key('smart_practice_cta')));
      await tester.pump();
      expect(launchedRequest, isNotNull);
      expect(launchedRequest!.questionIds.length, 30);

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

      // Open Formulas Screen as a dedicated screen from drawer
      await tester.tap(find.byKey(const Key('drawer_nav_formulas')));
      await tester.pumpAndSettle();
      expect(find.byType(FormulasScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open Settings Screen from drawer
      await tester.tap(find.byKey(const Key('burger_menu_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('drawer_nav_settings')));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(controller.practiceBatchSize, 30);

      // Select preset 15 batch size
      await tester.tap(find.byKey(const Key('settings_batch_size_15')));
      await tester.pump();
      expect(controller.practiceBatchSize, 15);

      // Select custom batch size (e.g. 22)
      await tester.tap(find.byKey(const Key('settings_batch_size_custom')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('settings_custom_batch_input')),
        '22',
      );
      await tester.tap(find.byKey(const Key('settings_custom_batch_save_btn')));
      await tester.pumpAndSettle();
      expect(controller.practiceBatchSize, 22);
      expect(find.text('Custom (22)'), findsOneWidget);

      // Switch language to German in Settings
      await tester.tap(find.byKey(const Key('settings_lang_de')));
      await tester.pump();
      expect(controller.language, AppLanguage.de);

      // Toggle dark mode in Settings
      await tester.ensureVisible(
        find.byKey(const Key('settings_dark_mode_switch')),
      );
      await tester.tap(find.byKey(const Key('settings_dark_mode_switch')));
      await tester.pump();
      expect(controller.isDarkMode, isTrue);

      // Pop Settings and verify Practice launches configured 22-question batch
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('smart_practice_cta')));
      await tester.pump();
      expect(launchedRequest!.questionIds.length, 22);

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

  testWidgets(
    'SettingsScreen Make available offline downloads all images and videos with live progress',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final completers = <String, Completer<Uint8List>>{
        'q_1.png': Completer<Uint8List>(),
        'q_2.png': Completer<Uint8List>(),
        'q_3.mp4': Completer<Uint8List>(),
      };

      final mediaCache = MediaCacheService(
        store: InMemoryMediaStore(),
        bulkConcurrency: 2,
        fetcher: (uri) {
          final fileName = uri.pathSegments.last;
          return completers[fileName]!.future;
        },
      );

      final controller = AppController(
        catalog: _sampleRepo(count: 5, withMedia: true),
        storage: InMemoryProgressStorage(),
        mediaCache: mediaCache,
      );
      addTearDown(() {
        controller.dispose();
        mediaCache.dispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: SettingsScreen(controller: controller),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const Key('settings_make_offline_tile')),
      );
      expect(find.text('Make available offline'), findsOneWidget);
      expect(find.text('0 of 3 images & videos downloaded'), findsOneWidget);

      // Tap "Make available offline" -> starts downloading and shows progress bar + Cancel
      await tester.tap(find.byKey(const Key('settings_make_offline_tile')));
      await tester.pump();

      expect(
        find.byKey(const Key('settings_offline_progress_bar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings_cancel_offline_btn')),
        findsOneWidget,
      );
      expect(find.text('Downloading (0 / 3)...'), findsOneWidget);

      // Complete first file -> live counter updates to 1 / 3
      completers['q_1.png']!.complete(Uint8List.fromList([1, 2, 3]));
      await tester.pump();
      await tester.pump();
      expect(find.text('Downloading (1 / 3)...'), findsOneWidget);

      // Complete remaining image and video -> transitions to Available offline!
      completers['q_2.png']!.complete(Uint8List.fromList([4, 5, 6]));
      completers['q_3.mp4']!.complete(Uint8List.fromList([7, 8, 9]));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('settings_offline_complete_tile')),
        findsOneWidget,
      );
      expect(find.text('Available offline'), findsOneWidget);
      expect(
        find.text('All 3 images and videos are saved offline'),
        findsOneWidget,
      );
    },
  );
}
