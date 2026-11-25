import 'question.dart';

enum OptionFeedbackState {
  /// User selected this option and it is part of the official answer.
  selectedCorrect,

  /// User selected this option, which is wrong.
  selectedWrong,

  /// User failed to select this required correct option.
  missedCorrect,

  /// User rightly left this wrong option unselected.
  unselectedWrong,
}

class AnswerSubmission {
  const AnswerSubmission({
    this.selectedLetters = const <String>{},
    this.numericText = '',
  });

  final Set<String> selectedLetters;
  final String numericText;

  bool isAnsweredFor(Question question) {
    if (question.inputKind == QuestionInputKind.numericInput) {
      return numericText.trim().isNotEmpty;
    }
    return selectedLetters.isNotEmpty;
  }

  Map<String, dynamic> toJson() => {
    'selectedLetters': selectedLetters.toList(),
    'numericText': numericText,
  };

  factory AnswerSubmission.fromJson(Map<String, dynamic> json) {
    final rawLetters = json['selectedLetters'] as List<dynamic>? ?? const [];
    return AnswerSubmission(
      selectedLetters: rawLetters.map((e) => e.toString()).toSet(),
      numericText: json['numericText'] as String? ?? '',
    );
  }
}

class AnswerEvaluation {
  const AnswerEvaluation({
    required this.isCorrect,
    required this.errorPointsAwarded,
    required this.optionStates,
    required this.hasMissingCorrectOptions,
    required this.hasWrongSelections,
  });

  final bool isCorrect;
  final int errorPointsAwarded;
  final Map<String, OptionFeedbackState> optionStates;
  final bool hasMissingCorrectOptions;
  final bool hasWrongSelections;
}

class AnswerEvaluator {
  const AnswerEvaluator._();

  static AnswerEvaluation evaluate(
    Question question,
    AnswerSubmission submission,
  ) {
    if (question.inputKind == QuestionInputKind.numericInput) {
      final isMatch = matchesNumeric(
        expected: question.correctNumericAnswer ?? '',
        actual: submission.numericText,
      );
      return AnswerEvaluation(
        isCorrect: isMatch,
        errorPointsAwarded: isMatch ? 0 : question.points,
        optionStates: const {},
        hasMissingCorrectOptions: !isMatch,
        hasWrongSelections:
            !isMatch && submission.numericText.trim().isNotEmpty,
      );
    }

    final states = <String, OptionFeedbackState>{};
    var hasMissing = false;
    var hasWrong = false;

    for (final option in question.options) {
      final letter = option.letter;
      final isSelected = submission.selectedLetters.contains(letter);
      final shouldBeSelected = question.correctOptionLetters.contains(letter);

      if (isSelected && shouldBeSelected) {
        states[letter] = OptionFeedbackState.selectedCorrect;
      } else if (isSelected && !shouldBeSelected) {
        states[letter] = OptionFeedbackState.selectedWrong;
        hasWrong = true;
      } else if (!isSelected && shouldBeSelected) {
        states[letter] = OptionFeedbackState.missedCorrect;
        hasMissing = true;
      } else {
        states[letter] = OptionFeedbackState.unselectedWrong;
      }
    }

    final isExactMatch =
        !hasMissing &&
        !hasWrong &&
        submission.selectedLetters.length ==
            question.correctOptionLetters.length;

    return AnswerEvaluation(
      isCorrect: isExactMatch,
      errorPointsAwarded: isExactMatch ? 0 : question.points,
      optionStates: Map.unmodifiable(states),
      hasMissingCorrectOptions: hasMissing,
      hasWrongSelections: hasWrong,
    );
  }

  /// Compares numeric answers as exact strings (only normalizing German commas
  /// `,` and English decimal dots `.` and outer whitespace) so padded inputs
  /// like `"0000"` or `"050"` are not accepted as `"0"` or `"50"`.
  static bool matchesNumeric({
    required String expected,
    required String actual,
  }) {
    final normExpected = _normalizeNumericString(expected);
    final normActual = _normalizeNumericString(actual);
    if (normExpected.isEmpty || normActual.isEmpty) return false;
    return normExpected == normActual;
  }

  static String _normalizeNumericString(String raw) {
    return raw.trim().replaceAll(',', '.');
  }
}
