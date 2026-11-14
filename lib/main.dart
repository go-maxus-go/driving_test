import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:material_ui/material_ui.dart';

import 'screens/app_shell.dart';
import 'screens/exam_player_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_player_screen.dart';
import 'screens/topics_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try {
      fvp.registerWith(
        options: {
          'platforms': ['linux', 'windows'],
        },
      );
    } catch (_) {
      // Safe fallback when headless or unsupported environment.
    }
  }
  final controller = await AppController.initialize();
  runApp(DrivingExamApp(controller: controller));
}

class DrivingExamApp extends StatelessWidget {
  const DrivingExamApp({
    super.key,
    required this.controller,
    this.topicsBuilder,
    this.progressBuilder,
    this.onOpenPractice,
    this.onOpenExam,
    this.enableNativeVideo = true,
  });

  final AppController controller;
  final WidgetBuilder? topicsBuilder;
  final WidgetBuilder? progressBuilder;
  final void Function(BuildContext context, PracticeLaunchRequest request)?
  onOpenPractice;
  final void Function(BuildContext context)? onOpenExam;
  final bool enableNativeVideo;

  void _defaultOpenPractice(BuildContext context, PracticeLaunchRequest req) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PracticePlayerScreen(
          controller: controller,
          request: req,
          enableNativeVideo: enableNativeVideo,
        ),
      ),
    );
  }

  void _defaultOpenExam(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExamPlayerScreen(
          controller: controller,
          onPracticeMistakes: (req) =>
              (onOpenPractice ?? _defaultOpenPractice)(context, req),
          enableNativeVideo: enableNativeVideo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: controller.strings.appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: controller.themeMode,
          home: Builder(
            builder: (innerContext) => AppShell(
              controller: controller,
              topicsBuilder:
                  topicsBuilder ??
                  (_) => TopicsScreen(
                    controller: controller,
                    onStartPractice: (req) =>
                        (onOpenPractice ?? _defaultOpenPractice)(
                          innerContext,
                          req,
                        ),
                  ),
              progressBuilder: progressBuilder,
              onOpenPractice: (req) =>
                  (onOpenPractice ?? _defaultOpenPractice)(innerContext, req),
              onOpenExam: () => (onOpenExam ?? _defaultOpenExam)(innerContext),
            ),
          ),
        );
      },
    );
  }
}
