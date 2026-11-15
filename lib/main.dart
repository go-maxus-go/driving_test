import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:material_ui/material_ui.dart';

import 'screens/app_shell.dart';
import 'screens/exam_player_screen.dart';
import 'screens/home_screen.dart';
import 'screens/practice_player_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/topics_screen.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_loading_screen.dart';
import 'widgets/first_launch_language_dialog.dart';

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
  runApp(const DrivingExamAppLauncher());
}

class DrivingExamAppLauncher extends StatefulWidget {
  const DrivingExamAppLauncher({super.key});

  @override
  State<DrivingExamAppLauncher> createState() => _DrivingExamAppLauncherState();
}

class _DrivingExamAppLauncherState extends State<DrivingExamAppLauncher> {
  AppController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final ctrl = await AppController.initialize();
      if (mounted) {
        setState(() => _controller = ctrl);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    if (ctrl == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: AppLoadingScreen(statusText: _error),
      );
    }
    return DrivingExamApp(controller: ctrl);
  }
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
    this.promptFirstLaunchLanguage = true,
  });

  final AppController controller;
  final WidgetBuilder? topicsBuilder;
  final WidgetBuilder? progressBuilder;
  final void Function(BuildContext context, PracticeLaunchRequest request)?
  onOpenPractice;
  final void Function(BuildContext context)? onOpenExam;
  final bool enableNativeVideo;
  final bool promptFirstLaunchLanguage;

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
            builder: (innerContext) {
              if (promptFirstLaunchLanguage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (innerContext.mounted) {
                    FirstLaunchLanguageDialog.showIfNeeded(
                      innerContext,
                      controller,
                    );
                  }
                });
              }

              return AppShell(
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
                progressBuilder:
                    progressBuilder ??
                    (_) => ProgressScreen(
                      controller: controller,
                      onStartPractice: (req) =>
                          (onOpenPractice ?? _defaultOpenPractice)(
                            innerContext,
                            req,
                          ),
                      onStartExam: () =>
                          (onOpenExam ?? _defaultOpenExam)(innerContext),
                    ),
                onOpenPractice: (req) =>
                    (onOpenPractice ?? _defaultOpenPractice)(innerContext, req),
                onOpenExam: () =>
                    (onOpenExam ?? _defaultOpenExam)(innerContext),
              );
            },
          ),
        );
      },
    );
  }
}
