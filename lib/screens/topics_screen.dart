import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../models/question.dart';
import '../models/user_progress.dart';
import '../state/app_controller.dart';
import '../widgets/coverage_bar.dart';
import 'home_screen.dart';

enum _CatalogSectionFilter { all, basicOnly, classBOnly }

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
  _CatalogSectionFilter _sectionFilter = _CatalogSectionFilter.all;
  String _searchQuery = '';
  bool _unfinishedFirstOnly = false;
  bool _multiSelectMode = false;
  final Set<String> _selectedThemeCodes = <String>{};
  final Set<String> _expandedThemeCodes = <String>{};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
      unfinishedOnly: _unfinishedFirstOnly,
    );
    if (ordered.isEmpty) return;
    widget.onStartPractice(
      PracticeLaunchRequest(title: title, questionIds: ordered),
    );
  }

  void _toggleThemeSelection(String themeCode) {
    setState(() {
      if (!_selectedThemeCodes.remove(themeCode)) {
        _selectedThemeCodes.add(themeCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.controller.strings;
    final scheme = Theme.of(context).colorScheme;
    final query = _searchQuery.trim().toLowerCase();

    final themes = widget.controller.currentThemes.where((theme) {
      if (_sectionFilter == _CatalogSectionFilter.basicOnly &&
          !theme.isBasicMaterial) {
        return false;
      }
      if (_sectionFilter == _CatalogSectionFilter.classBOnly &&
          theme.isBasicMaterial) {
        return false;
      }
      if (query.isEmpty) return true;
      if (theme.themeName.toLowerCase().contains(query) ||
          theme.themeCode.toLowerCase().contains(query)) {
        return true;
      }
      if (theme.chapters.any(
        (c) =>
            c.chapterName.toLowerCase().contains(query) ||
            c.chapterCode.toLowerCase().contains(query),
      )) {
        return true;
      }
      return theme.questionIds.any((id) {
        final q = widget.controller.questionById(id);
        return q != null &&
            (q.questionId.toLowerCase().contains(query) ||
                q.questionText.toLowerCase().contains(query));
      });
    }).toList();

    final selectedQuestionIds = <String>[
      for (final t in widget.controller.currentThemes)
        if (_selectedThemeCodes.contains(t.themeCode)) ...t.questionIds,
    ];

    return Stack(
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                14,
                16,
                _multiSelectMode && _selectedThemeCodes.isNotEmpty ? 92 : 28,
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('topic_search_field'),
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: s.searchQuestionsHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : null,
                          isDense: true,
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      key: const Key('open_formulas_btn'),
                      avatar: const Icon(Icons.straighten_rounded, size: 18),
                      label: Text(s.formulasButton),
                      onPressed: () => _showFormulasSheet(context, s),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ChoiceChip(
                      key: const Key('filter_all_chip'),
                      label: Text(s.filterAllClassB),
                      selected: _sectionFilter == _CatalogSectionFilter.all,
                      onSelected: (_) => setState(
                        () => _sectionFilter = _CatalogSectionFilter.all,
                      ),
                    ),
                    ChoiceChip(
                      key: const Key('filter_basic_chip'),
                      label: Text(s.filterGrundstoff),
                      selected:
                          _sectionFilter == _CatalogSectionFilter.basicOnly,
                      onSelected: (_) => setState(
                        () => _sectionFilter = _CatalogSectionFilter.basicOnly,
                      ),
                    ),
                    ChoiceChip(
                      key: const Key('filter_classb_chip'),
                      label: Text(s.filterZusatzstoff),
                      selected:
                          _sectionFilter == _CatalogSectionFilter.classBOnly,
                      onSelected: (_) => setState(
                        () => _sectionFilter = _CatalogSectionFilter.classBOnly,
                      ),
                    ),
                    FilterChip(
                      key: const Key('unfinished_only_toggle'),
                      label: Text(
                        _unfinishedFirstOnly
                            ? s.topicScopeUnfinished
                            : s.topicScopeAll,
                      ),
                      selected: _unfinishedFirstOnly,
                      onSelected: (v) =>
                          setState(() => _unfinishedFirstOnly = v),
                    ),
                    ActionChip(
                      key: const Key('multi_select_topics_btn'),
                      avatar: Icon(
                        _multiSelectMode
                            ? Icons.close_rounded
                            : Icons.checklist_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _multiSelectMode
                            ? s.cancelSelection
                            : s.multiSelectTopics,
                      ),
                      onPressed: () => setState(() {
                        _multiSelectMode = !_multiSelectMode;
                        if (!_multiSelectMode) _selectedThemeCodes.clear();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final theme in themes) ...[
                  _ThemeCatalogCard(
                    theme: theme,
                    icon: _iconForTheme(theme.themeCode),
                    stats: CoverageStats.compute(
                      theme.questionIds,
                      widget.controller.progressById,
                    ),
                    strings: s,
                    isExpanded:
                        _expandedThemeCodes.contains(theme.themeCode) ||
                        query.isNotEmpty,
                    multiSelectMode: _multiSelectMode,
                    isSelected: _selectedThemeCodes.contains(theme.themeCode),
                    progressById: widget.controller.progressById,
                    onTapCard: () {
                      if (_multiSelectMode) {
                        _toggleThemeSelection(theme.themeCode);
                      } else {
                        _launchScopedQuestions(
                          '${theme.themeCode} ${theme.themeName}',
                          theme.questionIds,
                        );
                      }
                    },
                    onLongPressCard: () {
                      if (!_multiSelectMode) {
                        setState(() {
                          _multiSelectMode = true;
                          _selectedThemeCodes.add(theme.themeCode);
                        });
                      }
                    },
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
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        if (_multiSelectMode && _selectedThemeCodes.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: FilledButton.icon(
                  key: const Key('start_multi_topics_btn'),
                  onPressed: () {
                    final count = _selectedThemeCodes.length;
                    final ids = List<String>.from(selectedQuestionIds);
                    setState(() {
                      _multiSelectMode = false;
                      _selectedThemeCodes.clear();
                    });
                    _launchScopedQuestions(
                      s.isDe ? '$count Themen' : '$count Topics',
                      ids,
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    s.practiceSelectedTopics(
                      _selectedThemeCodes.length,
                      selectedQuestionIds.length,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFormulasSheet(BuildContext context, AppStrings s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final items = s.isDe
            ? const [
                (
                  'Reaktionsweg (in m)',
                  '(Geschwindigkeit ÷ 10) × 3',
                  'Bei 50 km/h = 15 m  •  Bei 100 km/h = 30 m',
                ),
                (
                  'Normaler Bremsweg (in m)',
                  '(Geschwindigkeit ÷ 10) × (Geschwindigkeit ÷ 10)',
                  'Bei 50 km/h = 25 m  •  Bei 100 km/h = 100 m',
                ),
                (
                  'Gefahrenbremsung (in m)',
                  'Normaler Bremsweg ÷ 2',
                  'Bei 50 km/h = 12,5 m  •  Bei 100 km/h = 50 m',
                ),
                (
                  'Anhalteweg',
                  'Reaktionsweg + Bremsweg',
                  'Bei 50 km/h normal = 15 + 25 = 40 m',
                ),
                (
                  'Wichtige Grenzwerte Klasse B',
                  'Profiltiefe: mind. 1,6 mm  •  Autobahn-Bauartgeschw.: > 60 km/h',
                  'Alkohol in Probezeit / unter 21 J.: 0,0 ‰  •  Innerorts Pkw: 50 km/h, Außerorts: 100 km/h',
                ),
              ]
            : const [
                (
                  'Reaction Distance / Reaktionsweg (m)',
                  '(Speed ÷ 10) × 3',
                  'At 50 km/h = 15 m  •  At 100 km/h = 30 m',
                ),
                (
                  'Normal Braking Distance / Bremsweg (m)',
                  '(Speed ÷ 10) × (Speed ÷ 10)',
                  'At 50 km/h = 25 m  •  At 100 km/h = 100 m',
                ),
                (
                  'Emergency Braking / Gefahrenbremsung (m)',
                  'Normal Braking Distance ÷ 2',
                  'At 50 km/h = 12.5 m  •  At 100 km/h = 50 m',
                ),
                (
                  'Stopping Distance / Anhalteweg (m)',
                  'Reaction Distance + Braking Distance',
                  'At 50 km/h normal = 15 + 25 = 40 m',
                ),
                (
                  'Essential Class B Legal Numbers',
                  'Min. Tire Tread: 1.6 mm  •  Autobahn Min. Design Speed: > 60 km/h',
                  'Alcohol in Probezeit / under 21: 0.0 ‰  •  Built-up areas: 50 km/h, Rural roads: 100 km/h',
                ),
              ];

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          minChildSize: 0.45,
          builder: (_, scrollCtrl) => ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Text(
                s.formulasSheetTitle,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in items) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$3,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
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
    required this.isExpanded,
    required this.multiSelectMode,
    required this.isSelected,
    required this.progressById,
    required this.onTapCard,
    required this.onLongPressCard,
    required this.onToggleExpand,
    required this.onStartChapter,
  });

  final ThemeInfo theme;
  final IconData icon;
  final CoverageStats stats;
  final AppStrings strings;
  final bool isExpanded;
  final bool multiSelectMode;
  final bool isSelected;
  final Map<String, QuestionProgress> progressById;
  final VoidCallback onTapCard;
  final VoidCallback onLongPressCard;
  final VoidCallback onToggleExpand;
  final ValueChanged<ChapterInfo> onStartChapter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            key: Key('theme_card_${theme.themeCode}'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTapCard,
            onLongPress: onLongPressCard,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (multiSelectMode) ...[
                        Icon(
                          isSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          color: isSelected ? scheme.primary : null,
                        ),
                        const SizedBox(width: 10),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer.withValues(
                              alpha: 0.65,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 20, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${theme.themeCode} • ${theme.themeName}',
                              style: const TextStyle(
                                fontSize: 15.5,
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
                      const SizedBox(width: 8),
                      if (!multiSelectMode)
                        FilledButton.tonalIcon(
                          key: Key('start_theme_${theme.themeCode}'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 38),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          onPressed: onTapCard,
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: Text('${theme.questionIds.length}'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: StackedCoverageBar(stats: stats, height: 8),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        key: Key('expand_theme_${theme.themeCode}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: onToggleExpand,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
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
