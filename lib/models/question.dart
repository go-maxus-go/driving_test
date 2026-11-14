enum QuestionMediaKind { none, staticImage, video, optionImages }

enum QuestionInputKind { multipleChoice, numericInput }

class QuestionOption {
  const QuestionOption({
    required this.letter,
    required this.text,
    this.imageAssetPath,
  });

  /// Canonical option key without trailing dot, e.g. `"A"`, `"B"`, `"C"`,
  /// or the raw numeric string for `correct_answers` on numeric items.
  final String letter;
  final String text;
  final String? imageAssetPath;

  String get displayLetter => letter.endsWith('.') ? letter : '$letter.';

  static String normalizeLetter(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('.') && trimmed.length == 2) {
      return trimmed.substring(0, 1).toUpperCase();
    }
    return trimmed;
  }
}

class Question {
  const Question({
    required this.questionId,
    required this.questionNumber,
    required this.themeCode,
    required this.themeNumberLabel,
    required this.themeName,
    required this.chapterCode,
    required this.chapterNumberLabel,
    required this.chapterName,
    required this.points,
    required this.licenses,
    required this.questionText,
    required this.options,
    required this.correctOptionLetters,
    required this.correctNumericAnswer,
    required this.comment,
    required this.imageAssetPaths,
    required this.videoAssetPath,
    required this.mediaKind,
    required this.inputKind,
  });

  final String questionId;
  final String questionNumber;

  /// Canonical language-neutral theme code, e.g. `"1.1"` or `"2.7"`.
  final String themeCode;
  final String themeNumberLabel;
  final String themeName;

  /// Canonical language-neutral chapter code, e.g. `"1.1.01"`.
  final String chapterCode;
  final String chapterNumberLabel;
  final String chapterName;

  /// Error point weight (`2`, `3`, `4`, or `5`).
  final int points;
  final List<String> licenses;
  final String questionText;
  final List<QuestionOption> options;

  /// Canonical set of correct option letters (`{"A", "B"}`) for MC items.
  final Set<String> correctOptionLetters;

  /// Expected numeric value string (e.g. `"60"` or `"1,6"`) for numeric items.
  final String? correctNumericAnswer;

  final String comment;
  final List<String> imageAssetPaths;
  final String? videoAssetPath;
  final QuestionMediaKind mediaKind;
  final QuestionInputKind inputKind;

  /// True for Grundstoff (`1.x`), false for Zusatzstoff Class B (`2.x`).
  bool get isBasicMaterial => themeCode.startsWith('1.');

  /// Official German Mutterfrage (`-M`) subject to visual exam-day variations.
  bool get isMotherVariant => questionId.endsWith('-M');

  /// Primary static image or post-video freeze-frame (`Standbild`).
  String? get primaryImageAsset =>
      imageAssetPaths.isNotEmpty ? imageAssetPaths.first : null;

  static final RegExp _pointsRegex = RegExp(r'(\d+)');
  static final RegExp _chapterRegex = RegExp(r'(\d+\.\d+\.\d+)');
  static final RegExp _themeRegex = RegExp(r'(\d+\.\d+)');

  factory Question.fromJson(Map<String, dynamic> json) {
    final rawThemeNumber = (json['theme_number'] as String? ?? '').trim();
    final rawChapterNumber = (json['chapter_number'] as String? ?? '').trim();
    final questionId = (json['question_id'] as String? ?? '').trim();

    final themeCode =
        _themeRegex.firstMatch(rawThemeNumber)?.group(1) ??
        _themeRegex.firstMatch(questionId)?.group(1) ??
        rawThemeNumber;
    final chapterCode =
        _chapterRegex.firstMatch(rawChapterNumber)?.group(1) ??
        _chapterRegex.firstMatch(questionId)?.group(1) ??
        rawChapterNumber;

    final rawPoints = json['points']?.toString() ?? '2';
    final points =
        int.tryParse(_pointsRegex.firstMatch(rawPoints)?.group(1) ?? '') ?? 2;

    final localImgPaths =
        (json['local_image_paths'] as List<dynamic>? ?? const [])
            .map((e) => _toFlutterAssetPath(e.toString()))
            .where((p) => p.isNotEmpty)
            .toList(growable: false);

    final localVidPaths =
        (json['local_video_paths'] as List<dynamic>? ?? const [])
            .map((e) => _toFlutterAssetPath(e.toString()))
            .where((p) => p.isNotEmpty)
            .toList(growable: false);

    final rawOptions = json['options'] as List<dynamic>? ?? const [];
    final rawCorrect = json['correct_answers'] as List<dynamic>? ?? const [];

    final isNumeric = rawOptions.isEmpty;
    final inputKind = isNumeric
        ? QuestionInputKind.numericInput
        : QuestionInputKind.multipleChoice;

    final hasEmptyOptionText =
        !isNumeric &&
        rawOptions.every(
          (o) => ((o as Map<String, dynamic>)['text'] as String? ?? '')
              .trim()
              .isEmpty,
        );

    final bool isOptionImages =
        hasEmptyOptionText && localImgPaths.length >= rawOptions.length;

    final QuestionMediaKind mediaKind;
    if (localVidPaths.isNotEmpty) {
      mediaKind = QuestionMediaKind.video;
    } else if (isOptionImages) {
      mediaKind = QuestionMediaKind.optionImages;
    } else if (localImgPaths.isNotEmpty) {
      mediaKind = QuestionMediaKind.staticImage;
    } else {
      mediaKind = QuestionMediaKind.none;
    }

    final options = <QuestionOption>[];
    for (var i = 0; i < rawOptions.length; i++) {
      final map = rawOptions[i] as Map<String, dynamic>;
      final letter = QuestionOption.normalizeLetter(
        map['letter']?.toString() ?? '',
      );
      final text = (map['text'] as String? ?? '').trim();
      options.add(
        QuestionOption(
          letter: letter,
          text: text,
          imageAssetPath: isOptionImages ? localImgPaths[i] : null,
        ),
      );
    }

    final correctLetters = <String>{};
    String? correctNumeric;
    if (isNumeric) {
      if (rawCorrect.isNotEmpty) {
        final first = rawCorrect.first as Map<String, dynamic>;
        correctNumeric = (first['letter']?.toString() ?? '').trim();
      } else {
        correctNumeric = '';
      }
    } else {
      for (final item in rawCorrect) {
        final map = item as Map<String, dynamic>;
        correctLetters.add(
          QuestionOption.normalizeLetter(map['letter']?.toString() ?? ''),
        );
      }
    }

    return Question(
      questionId: questionId,
      questionNumber: (json['question_number'] as String? ?? questionId).trim(),
      themeCode: themeCode,
      themeNumberLabel: rawThemeNumber,
      themeName: (json['theme_name'] as String? ?? '').trim(),
      chapterCode: chapterCode,
      chapterNumberLabel: rawChapterNumber,
      chapterName: (json['chapter_name'] as String? ?? '').trim(),
      points: points,
      licenses: (json['licenses'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      questionText: (json['question_text'] as String? ?? '').trim(),
      options: List.unmodifiable(options),
      correctOptionLetters: Set.unmodifiable(correctLetters),
      correctNumericAnswer: correctNumeric,
      comment: (json['comment'] as String? ?? '').trim(),
      imageAssetPaths: List.unmodifiable(localImgPaths),
      videoAssetPath: localVidPaths.isNotEmpty ? localVidPaths.first : null,
      mediaKind: mediaKind,
      inputKind: inputKind,
    );
  }

  static String _toFlutterAssetPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.startsWith('assets/')) return trimmed;
    return 'assets/$trimmed';
  }
}

class ChapterInfo {
  const ChapterInfo({
    required this.chapterCode,
    required this.themeCode,
    required this.chapterNumberLabel,
    required this.chapterName,
    required this.questionIds,
  });

  final String chapterCode;
  final String themeCode;
  final String chapterNumberLabel;
  final String chapterName;
  final List<String> questionIds;
}

class ThemeInfo {
  const ThemeInfo({
    required this.themeCode,
    required this.themeNumberLabel,
    required this.themeName,
    required this.isBasicMaterial,
    required this.questionIds,
    required this.chapters,
  });

  final String themeCode;
  final String themeNumberLabel;
  final String themeName;
  final bool isBasicMaterial;
  final List<String> questionIds;
  final List<ChapterInfo> chapters;
}
