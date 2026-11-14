import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/main.dart';
import 'package:driving_exam/models/question.dart';
import 'package:driving_exam/screens/home_screen.dart';
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
        'chapter_name': 'Basic Forms',
        'question_id': id,
        'question_number': id,
        'points': '$pts Points',
        'licenses': ['Basic material'],
        'question_text': textEn,
        'options': [
          {'letter': 'A.', 'text': 'Option A'},
          {'letter': 'B.', 'text': 'Option B'},
        ],
        'correct_answers': [
          {'letter': 'A.', 'text': 'Option A'},
        ],
        'comment': 'Comment $id',
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
    'Home Cockpit launches without login, switches DE/EN in 1 tap, and adapts mobile vs desktop nav',
    (WidgetTester tester) async {
      // Mobile browser viewport (390x844)
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
          onOpenPractice: (_, req) => launchedRequest = req,
        ),
      );

      // Mobile renders bottom NavigationBar, not NavigationRail
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Smart Practice'), findsOneWidget);
      expect(find.text('Most Mistakes'), findsOneWidget);
      expect(find.text('Least Answered'), findsOneWidget);

      // 1-tap switch to German
      await tester.tap(find.byKey(const Key('lang_btn_de')));
      await tester.pump();
      expect(find.text('Smart-Training'), findsOneWidget);
      expect(find.text('Häufige Fehler'), findsOneWidget);
      expect(find.text('Wenig geübt'), findsOneWidget);

      // 1-tap Smart Practice launches immediately
      await tester.tap(find.byKey(const Key('smart_practice_cta')));
      await tester.pump();
      expect(launchedRequest, isNotNull);
      expect(launchedRequest!.questionIds.length, 2);

      // Switch to Linux/Desktop wide viewport (1200x800) -> NavigationRail
      tester.view.physicalSize = const Size(1200, 800);
      await tester.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
}
