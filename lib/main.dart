import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

bool get _isMobileFullscreenPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

Future<void> configureImmersiveFullscreen() async {
  if (!_isMobileFullscreenPlatform) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setSystemUIChangeCallback((
    systemOverlaysAreVisible,
  ) async {
    if (systemOverlaysAreVisible) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  });
}

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  binding.deferFirstFrame();
  await configureImmersiveFullscreen();

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

  try {
    final ctrl = await AppController.initialize();
    runApp(DrivingExamApp(controller: ctrl));
  } catch (e) {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: AppLoadingScreen(statusText: e.toString()),
      ),
    );
  } finally {
    binding.allowFirstFrame();
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
