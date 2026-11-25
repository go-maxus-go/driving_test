import 'dart:convert';
import 'dart:io';

import 'package:driving_exam/data/catalog_repository.dart';
import 'package:driving_exam/l10n/app_language.dart';
import 'package:driving_exam/models/answer_evaluation.dart';
import 'package:driving_exam/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Question parsing & Bilingual CatalogRepository', () {
    late CatalogRepository repository;

    setUpAll(() async {
      final enJson = jsonDecode(
        await File('assets/driving_theory_questions_b.json').readAsString(),
      ) as List<dynamic>;
      final deJson = jsonDecode(
        await File('assets/driving_theory_questions_de_b.json').readAsString(),
      ) as List<dynamic>;

      repository = CatalogRepository.fromQuestions(
        englishQuestions: enJson
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
        germanQuestions: deJson
            .map((e) => Question.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    });

    test('loads all 1,592 aligned EN and DE questions across 14 themes & 92 chapters', () {
      final enQuestions = repository.questionsFor(AppLanguage.en);
      final deQuestions = repository.questionsFor(AppLanguage.de);

      expect(enQuestions.length, 1592);
      expect(deQuestions.length, 1592);

      final enThemes = repository.themesFor(AppLanguage.en);
      final deThemes = repository.themesFor(AppLanguage.de);
      expect(enThemes.length, 14);
      expect(deThemes.length, 14);

      final totalChapters = enThemes.fold<int>(
        0,
        (sum, t) => sum + t.chapters.length,
      );
      expect(totalChapters, 92);

      final basicCount = enQuestions.where((q) => q.isBasicMaterial).length;
      final classBCount = enQuestions.where((q) => !q.isBasicMaterial).length;
      expect(basicCount, 823);
      expect(classBCount, 769);

      // Verify canonical codes match across languages for seamless switching
      final qEn = repository.questionById('1.1.01-001', AppLanguage.en)!;
      final qDe = repository.questionById('1.1.01-001', AppLanguage.de)!;
      expect(qEn.themeCode, '1.1');
      expect(qDe.themeCode, '1.1');
      expect(qEn.chapterCode, '1.1.01');
      expect(qDe.chapterCode, '1.1.01');
      expect(qEn.points, 4);
      expect(qDe.points, 4);
      expect(qDe.questionText, contains('defensivem Fahren'));
    });

    test('detects orthogonal mediaKind and inputKind including video+numeric and 3-sign items', () {
      // Video + Numeric question 2.2.03-026-M
      final vidNumeric = repository.questionById(
        '2.2.03-026-M',
        AppLanguage.en,
      )!;
      expect(vidNumeric.mediaKind, QuestionMediaKind.video);
      expect(vidNumeric.inputKind, QuestionInputKind.numericInput);
      expect(vidNumeric.isMotherVariant, isTrue);
      expect(vidNumeric.videoAssetPath, 'assets/videos/2_2_03-026-M.mp4');
      expect(vidNumeric.primaryImageAsset, 'assets/images/2_2_03-026-M.png');

      // 3-sign option images question 1.4.40-013
      final signQuestion = repository.questionById(
        '1.4.40-013',
        AppLanguage.de,
      )!;
      expect(signQuestion.mediaKind, QuestionMediaKind.optionImages);
      expect(signQuestion.inputKind, QuestionInputKind.multipleChoice);
      expect(signQuestion.options.length, 3);
      expect(signQuestion.options.map((o) => o.imageAssetPath).toList(), [
        'assets/images/1_4_40-013_a1.png',
        'assets/images/1_4_40-013_a2.png',
        'assets/images/1_4_40-013_a3.png',
      ]);
    });
  });

  group('AnswerEvaluator 4-state & strict string numeric rules', () {
    final mcQuestion = Question.fromJson({
      'theme_number': 'Theme 1.1.',
      'theme_name': 'Danger Teaching',
      'chapter_number': '1.1.01 Chapter',
      'chapter_name': 'Basic Forms',
      'question_id': '1.1.01-001',
      'question_number': '1.1.01-001',
      'points': '5 Points',
      'licenses': ['Basic material'],
      'question_text': 'What is defensive driving?',
      'options': [
        {'letter': 'A.', 'text': 'Not insisting on rights'},
        {'letter': 'B.', 'text': 'Anticipating mistakes'},
        {'letter': 'C.', 'text': 'Stopping everywhere'},
      ],
      'correct_answers': [
        {'letter': 'A.', 'text': 'Not insisting on rights'},
        {'letter': 'B.', 'text': 'Anticipating mistakes'},
      ],
      'comment': 'Explanation text',
      'local_image_paths': <String>[],
      'local_video_paths': <String>[],
    });

    test('exact multiple-choice match awards 0 error points', () {
      final result = AnswerEvaluator.evaluate(
        mcQuestion,
        const AnswerSubmission(selectedLetters: {'A', 'B'}),
      );
      expect(result.isCorrect, isTrue);
      expect(result.errorPointsAwarded, 0);
      expect(result.hasMissingCorrectOptions, isFalse);
      expect(result.hasWrongSelections, isFalse);
      expect(result.optionStates['A'], OptionFeedbackState.selectedCorrect);
      expect(result.optionStates['B'], OptionFeedbackState.selectedCorrect);
      expect(result.optionStates['C'], OptionFeedbackState.unselectedWrong);
    });

    test('partial selection or extra wrong choice awards full error points and 4-state tags', () {
      final result = AnswerEvaluator.evaluate(
        mcQuestion,
        const AnswerSubmission(selectedLetters: {'A', 'C'}),
      );
      expect(result.isCorrect, isFalse);
      expect(result.errorPointsAwarded, 5);
      expect(result.hasMissingCorrectOptions, isTrue);
      expect(result.hasWrongSelections, isTrue);
      expect(result.optionStates['A'], OptionFeedbackState.selectedCorrect);
      expect(result.optionStates['B'], OptionFeedbackState.missedCorrect);
      expect(result.optionStates['C'], OptionFeedbackState.selectedWrong);
    });

    test('numeric input compares strictly as strings while allowing comma/dot decimal separator', () {
      final numQuestion = Question.fromJson({
        'theme_number': 'Thema 2.7.',
        'theme_name': 'Technik',
        'chapter_number': '2.7.01 Kapitel',
        'chapter_name': 'Reifen',
        'question_id': '2.7.01-101',
        'question_number': '2.7.01-101',
        'points': '3 Punkte',
        'licenses': ['B'],
        'question_text': 'Mindestprofiltiefe in mm?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': [
          {'letter': '1,6', 'text': ''},
        ],
        'comment': 'Mindestens 1,6 mm.',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      });

      final zeroQuestion = Question.fromJson({
        'theme_number': 'Thema 1.1.',
        'theme_name': 'Grundregeln',
        'chapter_number': '1.1.01 Kapitel',
        'chapter_name': 'Alkohol',
        'question_id': '1.1.01-050',
        'question_number': '1.1.01-050',
        'points': '4 Punkte',
        'licenses': ['Basic material'],
        'question_text': 'Promillegrenze in der Probezeit?',
        'options': <Map<String, dynamic>>[],
        'correct_answers': [
          {'letter': '0', 'text': ''},
        ],
        'comment': '0,0 Promille.',
        'local_image_paths': <String>[],
        'local_video_paths': <String>[],
      });

      expect(
        AnswerEvaluator.evaluate(
          numQuestion,
          const AnswerSubmission(numericText: '1,6'),
        ).isCorrect,
        isTrue,
      );
      expect(
        AnswerEvaluator.evaluate(
          numQuestion,
          const AnswerSubmission(numericText: ' 1.6 '),
        ).isCorrect,
        isTrue,
      );
      // Reject leading/trailing zero padding under strict string comparison
      expect(
        AnswerEvaluator.evaluate(
          numQuestion,
          const AnswerSubmission(numericText: '01.6'),
        ).isCorrect,
        isFalse,
      );
      expect(
        AnswerEvaluator.evaluate(
          numQuestion,
          const AnswerSubmission(numericText: '1.60'),
        ).isCorrect,
        isFalse,
      );

      // Reject '0000' for '0'
      expect(
        AnswerEvaluator.evaluate(
          zeroQuestion,
          const AnswerSubmission(numericText: '0'),
        ).isCorrect,
        isTrue,
      );
      expect(
        AnswerEvaluator.evaluate(
          zeroQuestion,
          const AnswerSubmission(numericText: '0000'),
        ).isCorrect,
        isFalse,
      );
      expect(
        AnswerEvaluator.evaluate(
          zeroQuestion,
          const AnswerSubmission(numericText: '0.0'),
        ).isCorrect,
        isFalse,
      );

      final wrong = AnswerEvaluator.evaluate(
        numQuestion,
        const AnswerSubmission(numericText: '1.5'),
      );
      expect(wrong.isCorrect, isFalse);
      expect(wrong.errorPointsAwarded, 3);

      expect(
        AnswerEvaluator.evaluate(
          numQuestion,
          const AnswerSubmission(numericText: ''),
        ).isCorrect,
        isFalse,
      );
    });
  });
}
