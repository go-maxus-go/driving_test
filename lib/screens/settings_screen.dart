import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final s = controller.strings;
        final scheme = Theme.of(context).colorScheme;
        final semantic = SemanticColors.of(context);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              s.navSettings,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  _SectionHeader(title: s.settingsLanguageHeader),
                  const SizedBox(height: 8),
                  Card(
                    child: RadioGroup<AppLanguage>(
                      groupValue: controller.language,
                      onChanged: (val) {
                        if (val != null) controller.setLanguage(val);
                      },
                      child: Column(
                        children: [
                          RadioListTile<AppLanguage>(
                            key: const Key('settings_lang_en'),
                            title: const Text(
                              'English',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(s.welcomeLanguageEnglish),
                            secondary: const Text(
                              '🇬🇧',
                              style: TextStyle(fontSize: 22),
                            ),
                            value: AppLanguage.en,
                          ),
                          const Divider(height: 1),
                          RadioListTile<AppLanguage>(
                            key: const Key('settings_lang_de'),
                            title: const Text(
                              'Deutsch',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(s.welcomeLanguageGerman),
                            secondary: const Text(
                              '🇩🇪',
                              style: TextStyle(fontSize: 22),
                            ),
                            value: AppLanguage.de,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: s.settingsThemeHeader),
                  const SizedBox(height: 8),
                  Card(
                    child: SwitchListTile(
                      key: const Key('settings_dark_mode_switch'),
                      secondary: Icon(
                        controller.isDarkMode
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        color: scheme.primary,
                      ),
                      title: Text(
                        s.settingsDarkMode,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      value: controller.isDarkMode,
                      onChanged: (_) => controller.toggleDarkMode(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SectionHeader(title: s.settingsResetHeader),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      key: const Key('settings_reset_progress_tile'),
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: semantic.wrongBorder,
                      ),
                      title: Text(
                        s.resetProgressTitle,
                        style: TextStyle(
                          color: semantic.wrongBorder,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dlgContext) => AlertDialog(
                            title: Text(s.resetProgressTitle),
                            content: Text(s.resetConfirmBody),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(dlgContext).pop(false),
                                child: Text(s.cancelAction),
                              ),
                              FilledButton(
                                key: const Key('confirm_reset_btn'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: semantic.wrongBorder,
                                ),
                                onPressed: () =>
                                    Navigator.of(dlgContext).pop(true),
                                child: Text(s.resetConfirmAction),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true) {
                          await controller.resetAllProgress();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.progressResetSuccess),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
