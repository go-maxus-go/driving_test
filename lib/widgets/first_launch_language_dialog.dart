import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../state/app_controller.dart';

class FirstLaunchLanguageDialog extends StatefulWidget {
  const FirstLaunchLanguageDialog({super.key, required this.controller});

  final AppController controller;

  static Future<void> showIfNeeded(
    BuildContext context,
    AppController controller,
  ) async {
    if (controller.hasChosenLanguage) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FirstLaunchLanguageDialog(controller: controller),
    );
  }

  @override
  State<FirstLaunchLanguageDialog> createState() =>
      _FirstLaunchLanguageDialogState();
}

class _FirstLaunchLanguageDialogState extends State<FirstLaunchLanguageDialog> {
  late AppLanguage _selected;

  @override
  void initState() {
    super.initState();
    // Default to English as requested
    _selected = widget.controller.language;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(_selected);
    final scheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      size: 32,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  s.welcomeLanguageTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.welcomeLanguageSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                _LanguageOptionTile(
                  key: const Key('first_launch_lang_en'),
                  title: 'English',
                  subtitle: s.welcomeLanguageEnglish,
                  flagEmoji: '🇬🇧',
                  isSelected: _selected == AppLanguage.en,
                  onTap: () => setState(() => _selected = AppLanguage.en),
                ),
                const SizedBox(height: 10),
                _LanguageOptionTile(
                  key: const Key('first_launch_lang_de'),
                  title: 'Deutsch',
                  subtitle: s.welcomeLanguageGerman,
                  flagEmoji: '🇩🇪',
                  isSelected: _selected == AppLanguage.de,
                  onTap: () => setState(() => _selected = AppLanguage.de),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  key: const Key('first_launch_continue_btn'),
                  onPressed: () async {
                    await widget.controller.confirmFirstLaunchLanguage(
                      _selected,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(s.welcomeContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primaryContainer.withValues(alpha: 0.5)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? scheme.primary : scheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(flagEmoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? scheme.primary : scheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
