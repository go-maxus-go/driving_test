import 'package:material_ui/material_ui.dart';

import '../l10n/app_language.dart';
import '../theme/app_theme.dart';

class ErgonomicNumericKeypad extends StatelessWidget {
  const ErgonomicNumericKeypad({
    super.key,
    required this.value,
    required this.strings,
    required this.onChanged,
    this.isSubmitted = false,
    this.isCorrect = false,
    this.expectedAnswer,
  });

  final String value;
  final AppStrings strings;
  final ValueChanged<String> onChanged;
  final bool isSubmitted;
  final bool isCorrect;
  final String? expectedAnswer;

  void _appendChar(String ch) {
    if (isSubmitted) return;
    if (ch == ',' || ch == '.') {
      if (value.contains(',') || value.contains('.')) return;
      final prefix = value.isEmpty ? '0' : value;
      onChanged('$prefix${strings.isDe ? ',' : '.'}');
      return;
    }
    if (value.length >= 6) return;
    onChanged('$value$ch');
  }

  void _backspace() {
    if (isSubmitted || value.isEmpty) return;
    onChanged(value.substring(0, value.length - 1));
  }

  void _clear() {
    if (isSubmitted || value.isEmpty) return;
    onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = SemanticColors.of(context);

    Color boxBorder = scheme.primary;
    Color boxBg = semantic.cardSurface;
    if (isSubmitted) {
      boxBorder = isCorrect ? semantic.correctBorder : semantic.wrongBorder;
      boxBg = isCorrect ? semantic.correctSurface : semantic.wrongSurface;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('numeric_display_box'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: boxBorder, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? strings.numericInputHint : value,
                  style: TextStyle(
                    fontSize: value.isEmpty ? 15 : 24,
                    fontWeight: value.isEmpty
                        ? FontWeight.w500
                        : FontWeight.w800,
                    color: value.isEmpty
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                  ),
                ),
              ),
              if (!isSubmitted && value.isNotEmpty)
                IconButton(
                  key: const Key('numeric_clear_btn'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                  icon: const Icon(Icons.clear_rounded),
                ),
              if (isSubmitted)
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCorrect
                      ? semantic.correctBorder
                      : semantic.wrongBorder,
                  size: 28,
                ),
            ],
          ),
        ),
        if (isSubmitted && !isCorrect && expectedAnswer != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: semantic.wrongSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: semantic.wrongBorder),
                ),
                child: Text(
                  strings.yourNumericAnswer(value.isEmpty ? '—' : value),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: semantic.wrongText,
                  ),
                ),
              ),
              Container(
                key: const Key('numeric_expected_answer_pill'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: semantic.correctSurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: semantic.correctBorder),
                ),
                child: Text(
                  strings.correctNumericAnswer(expectedAnswer!),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: semantic.correctText,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (!isSubmitted) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              children: [
                _buildRow(context, const ['1', '2', '3']),
                const SizedBox(height: 8),
                _buildRow(context, const ['4', '5', '6']),
                const SizedBox(height: 8),
                _buildRow(context, const ['7', '8', '9']),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _KeyBtn(
                        key: const Key('numpad_key_decimal'),
                        label: strings.isDe ? ',' : '.',
                        onTap: () => _appendChar(','),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KeyBtn(
                        key: const Key('numpad_key_0'),
                        label: '0',
                        onTap: () => _appendChar('0'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _KeyBtn(
                        key: const Key('numpad_key_backspace'),
                        icon: Icons.backspace_outlined,
                        onTap: _backspace,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      children: [
        for (var i = 0; i < digits.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _KeyBtn(
              key: Key('numpad_key_${digits[i]}'),
              label: digits[i],
              onTap: () => _appendChar(digits[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyBtn extends StatelessWidget {
  const _KeyBtn({super.key, this.label, this.icon, required this.onTap});

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 48,
          child: Center(
            child: icon != null
                ? Icon(icon, size: 20)
                : Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
