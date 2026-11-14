import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../widgets/language_selector.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
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
  final ValueChanged<PracticeLaunchRequest>? onOpenPractice;
  final VoidCallback? onOpenExam;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;
        final width = MediaQuery.sizeOf(context).width;
        final useSideRail = width >= 840;

        final body = IndexedStack(
          index: _selectedIndex,
          children: [
            HomeScreen(
              controller: widget.controller,
              onStartPractice: (req) => widget.onOpenPractice?.call(req),
              onStartNewExam: () async {
                await widget.controller.startNewExam();
                widget.onOpenExam?.call();
              },
              onResumeExam: () => widget.onOpenExam?.call(),
              onOpenProgressTab: () => setState(() => _selectedIndex = 2),
            ),
            widget.topicsBuilder?.call(context) ?? const SizedBox.shrink(),
            widget.progressBuilder?.call(context) ?? const SizedBox.shrink(),
          ],
        );

        return Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_car_filled_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    s.appTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              LanguageSelectorPill(
                current: widget.controller.language,
                onChanged: widget.controller.setLanguage,
              ),
              const SizedBox(width: 6),
              IconButton(
                key: const Key('theme_mode_toggle'),
                tooltip: widget.controller.isDarkMode ? 'Light' : 'Dark',
                onPressed: widget.controller.toggleDarkMode,
                icon: Icon(
                  widget.controller.isDarkMode
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_outlined,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: useSideRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (idx) =>
                          setState(() => _selectedIndex = idx),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.bolt_outlined),
                          selectedIcon: const Icon(Icons.bolt_rounded),
                          label: Text(s.navTrain),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.grid_view_outlined),
                          selectedIcon: const Icon(Icons.grid_view_rounded),
                          label: Text(s.navTopics),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.insights_outlined),
                          selectedIcon: const Icon(Icons.insights_rounded),
                          label: Text(s.navProgress),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: useSideRail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) =>
                      setState(() => _selectedIndex = idx),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.bolt_outlined),
                      selectedIcon: const Icon(Icons.bolt_rounded),
                      label: s.navTrain,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.grid_view_outlined),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: s.navTopics,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.insights_outlined),
                      selectedIcon: const Icon(Icons.insights_rounded),
                      label: s.navProgress,
                    ),
                  ],
                ),
        );
      },
    );
  }
}
