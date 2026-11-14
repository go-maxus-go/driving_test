import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:material_ui/material_ui.dart';

import 'screens/app_shell.dart';
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
  });

  final AppController controller;
  final WidgetBuilder? topicsBuilder;
  final WidgetBuilder? progressBuilder;
  final void Function(BuildContext context, dynamic request)? onOpenPractice;
  final void Function(BuildContext context)? onOpenExam;

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
              topicsBuilder: topicsBuilder,
              progressBuilder: progressBuilder,
              onOpenPractice: (req) => onOpenPractice?.call(innerContext, req),
              onOpenExam: () => onOpenExam?.call(innerContext),
            ),
          ),
        );
      },
    );
  }
}
