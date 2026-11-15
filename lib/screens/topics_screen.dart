import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../models/question.dart';
import '../models/user_progress.dart';
import '../state/app_controller.dart';
import '../widgets/coverage_bar.dart';
import 'home_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({
    super.key,
    required this.controller,
    required this.onStartPractice,
  });

  final AppController controller;
  final ValueChanged<PracticeLaunchRequest> onStartPractice;

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final Set<String> _expandedThemeCodes = <String>{};

  IconData _iconForTheme(String themeCode) {
    if (themeCode.endsWith('.1')) return Icons.warning_amber_rounded;
    if (themeCode.endsWith('.2')) return Icons.alt_route_rounded;
    if (themeCode.endsWith('.3')) return Icons.traffic_rounded;
    if (themeCode.endsWith('.4')) return Icons.signpost_outlined;
    if (themeCode.endsWith('.5')) return Icons.eco_outlined;
    if (themeCode.endsWith('.6')) return Icons.fact_check_outlined;
    if (themeCode.endsWith('.7')) return Icons.build_outlined;
    return Icons.badge_outlined;
  }

  void _launchScopedQuestions(String title, Iterable<String> questionIds) {
    final ordered = widget.controller.buildTopicQueue(
      questionIds,
      unfinishedOnly: false,
    );
    if (ordered.isEmpty) return;
    widget.onStartPractice(
      PracticeLaunchRequest(title: title, questionIds: ordered),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final s = widget.controller.strings;

        final themes = List<ThemeInfo>.from(widget.controller.currentThemes);
        themes.sort((a, b) {
          final aStarred = widget.controller.isThemeStarred(a.themeCode)
              ? 0
              : 1;
          final bStarred = widget.controller.isThemeStarred(b.themeCode)
              ? 0
              : 1;
          if (aStarred != bStarred) return aStarred.compareTo(bStarred);
          return a.themeCode.compareTo(b.themeCode);
        });

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                final isStarred = widget.controller.isThemeStarred(
                  theme.themeCode,
                );
                final isExpanded = _expandedThemeCodes.contains(
                  theme.themeCode,
                );
                final stats = CoverageStats.compute(
                  theme.questionIds,
                  widget.controller.progressById,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ThemeCatalogCard(
                    theme: theme,
                    icon: _iconForTheme(theme.themeCode),
                    stats: stats,
                    strings: s,
                    isStarred: isStarred,
                    isExpanded: isExpanded,
                    progressById: widget.controller.progressById,
                    onTapCard: () => _launchScopedQuestions(
                      '${theme.themeCode} ${theme.themeName}',
                      theme.questionIds,
                    ),
                    onToggleStar: () =>
                        widget.controller.toggleThemeStarred(theme.themeCode),
                    onToggleExpand: () {
                      setState(() {
                        if (!_expandedThemeCodes.remove(theme.themeCode)) {
                          _expandedThemeCodes.add(theme.themeCode);
                        }
                      });
                    },
                    onStartChapter: (chapter) => _launchScopedQuestions(
                      '${chapter.chapterCode} ${chapter.chapterName}',
                      chapter.questionIds,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ThemeCatalogCard extends StatelessWidget {
  const _ThemeCatalogCard({
    required this.theme,
    required this.icon,
    required this.stats,
    required this.strings,
    required this.isStarred,
    required this.isExpanded,
    required this.progressById,
    required this.onTapCard,
    required this.onToggleStar,
    required this.onToggleExpand,
    required this.onStartChapter,
  });

  final ThemeInfo theme;
  final IconData icon;
  final CoverageStats stats;
  final AppStrings strings;
  final bool isStarred;
  final bool isExpanded;
  final Map<String, QuestionProgress> progressById;
  final VoidCallback onTapCard;
  final VoidCallback onToggleStar;
  final VoidCallback onToggleExpand;
  final ValueChanged<ChapterInfo> onStartChapter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: Key('theme_card_${theme.themeCode}'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isStarred
              ? Colors.amber.withValues(alpha: 0.6)
              : scheme.outlineVariant.withValues(alpha: 0.4),
          width: isStarred ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: onTapCard,
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${theme.themeCode} • ${theme.themeName}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            CoverageLegendRow(
                              stats: stats,
                              strings: strings,
                              compact: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      key: Key('star_theme_${theme.themeCode}'),
                      icon: Icon(
                        isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isStarred
                            ? Colors.amber
                            : scheme.onSurfaceVariant,
                        size: 22,
                      ),
                      tooltip: isStarred
                          ? strings.unstarTopicTooltip
                          : strings.starTopicTooltip,
                      onPressed: onToggleStar,
                    ),
                    FilledButton.tonalIcon(
                      key: Key('start_theme_${theme.themeCode}'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      onPressed: onTapCard,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: Text('${theme.questionIds.length}'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: StackedCoverageBar(stats: stats, height: 7),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      key: Key('expand_theme_${theme.themeCode}'),
                      borderRadius: BorderRadius.circular(8),
                      onTap: onToggleExpand,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              strings.chaptersCount(theme.chapters.length),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: scheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            for (final ch in theme.chapters)
              _ChapterRow(
                chapter: ch,
                stats: CoverageStats.compute(ch.questionIds, progressById),
                strings: strings,
                onTap: () => onStartChapter(ch),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.chapter,
    required this.stats,
    required this.strings,
    required this.onTap,
  });

  final ChapterInfo chapter;
  final CoverageStats stats;
  final AppStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key('chapter_row_${chapter.chapterCode}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${chapter.chapterCode} • ${chapter.chapterName}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  CoverageLegendRow(
                    stats: stats,
                    strings: strings,
                    compact: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.play_circle_outline_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
