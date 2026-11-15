import 'package:material_ui/material_ui.dart';

import '../state/app_controller.dart';
import '../widgets/formulas_modal.dart';
import 'about_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.controller,
    this.onOpenPractice,
    this.onOpenExam,
    this.topicsBuilder,
    this.progressBuilder,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest>? onOpenPractice;
  final VoidCallback? onOpenExam;
  final WidgetBuilder? topicsBuilder;
  final WidgetBuilder? progressBuilder;

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
        final scheme = Theme.of(context).colorScheme;

        String sectionTitle;
        switch (_selectedIndex) {
          case 1:
            sectionTitle = s.navTopics;
            break;
          case 2:
            sectionTitle = s.navProgress;
            break;
          default:
            sectionTitle = s.appTitle;
        }

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
            leading: Builder(
              builder: (ctx) => IconButton(
                key: const Key('burger_menu_btn'),
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Text(
              sectionTitle,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          drawer: Drawer(
            key: const Key('app_drawer'),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Führerschein Klasse B',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        s.isDe
                            ? 'Theorieprüfung Trainer'
                            : 'Theory Exam Trainer',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  key: const Key('drawer_nav_train'),
                  leading: const Icon(Icons.bolt_rounded),
                  title: Text(
                    s.navTrain,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: _selectedIndex == 0,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _selectedIndex = 0);
                  },
                ),
                ListTile(
                  key: const Key('drawer_nav_topics'),
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(
                    s.navTopics,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: _selectedIndex == 1,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _selectedIndex = 1);
                  },
                ),
                ListTile(
                  key: const Key('drawer_nav_progress'),
                  leading: const Icon(Icons.insights_rounded),
                  title: Text(
                    s.navProgress,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  selected: _selectedIndex == 2,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _selectedIndex = 2);
                  },
                ),
                const Divider(),
                ListTile(
                  key: const Key('drawer_nav_formulas'),
                  leading: const Icon(Icons.functions_rounded),
                  title: Text(
                    s.navFormulas,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    FormulasModal.show(context, widget.controller.language);
                  },
                ),
                ListTile(
                  key: const Key('drawer_nav_settings'),
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(
                    s.navSettings,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SettingsScreen(controller: widget.controller),
                      ),
                    );
                  },
                ),
                ListTile(
                  key: const Key('drawer_nav_about'),
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(
                    s.navAbout,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AboutScreen(controller: widget.controller),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          body: SafeArea(child: body),
        );
      },
    );
  }
}
