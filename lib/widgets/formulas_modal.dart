import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';

class FormulasModal {
  static Future<void> show(BuildContext context, AppLanguage language) {
    final s = AppStrings(language);

    return showModalBottomSheet<void>(
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
