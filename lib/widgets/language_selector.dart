import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';

class LanguageSelectorPill extends StatelessWidget {
  const LanguageSelectorPill({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppLanguage current;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('language_selector_pill'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final lang in [AppLanguage.de, AppLanguage.en])
            _LangSegment(
              key: Key('lang_btn_${lang.code}'),
              language: lang,
              selected: current == lang,
              onTap: () => onChanged(lang),
            ),
        ],
      ),
    );
  }
}

class _LangSegment extends StatelessWidget {
  const _LangSegment({
    super.key,
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            language.shortLabel,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
