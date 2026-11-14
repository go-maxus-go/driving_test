import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../l10n/app_language.dart';
import '../models/question.dart';

class LocalizedCatalog {
  LocalizedCatalog(List<Question> orderedQuestions)
    : questions = List.unmodifiable(orderedQuestions),
      byId = Map.unmodifiable({
        for (final q in orderedQuestions) q.questionId: q,
      }),
      themes = _buildThemes(orderedQuestions);

  final List<Question> questions;
  final Map<String, Question> byId;
  final List<ThemeInfo> themes;

  static List<ThemeInfo> _buildThemes(List<Question> questions) {
    final themeBuckets = <String, List<Question>>{};
    for (final q in questions) {
      themeBuckets.putIfAbsent(q.themeCode, () => <Question>[]).add(q);
    }

    final sortedThemeCodes = themeBuckets.keys.toList()..sort(_compareCode);
    final result = <ThemeInfo>[];

    for (final themeCode in sortedThemeCodes) {
      final themeQuestions = themeBuckets[themeCode]!;
      final firstThemeQ = themeQuestions.first;

      final chapterBuckets = <String, List<Question>>{};
      for (final q in themeQuestions) {
        chapterBuckets.putIfAbsent(q.chapterCode, () => <Question>[]).add(q);
      }
      final sortedChapterCodes = chapterBuckets.keys.toList()
        ..sort(_compareCode);

      final chapters = <ChapterInfo>[
        for (final chapterCode in sortedChapterCodes)
          ChapterInfo(
            chapterCode: chapterCode,
            themeCode: themeCode,
            chapterNumberLabel:
                chapterBuckets[chapterCode]!.first.chapterNumberLabel,
            chapterName: chapterBuckets[chapterCode]!.first.chapterName,
            questionIds: List.unmodifiable(
              chapterBuckets[chapterCode]!.map((q) => q.questionId),
            ),
          ),
      ];

      result.add(
        ThemeInfo(
          themeCode: themeCode,
          themeNumberLabel: firstThemeQ.themeNumberLabel,
          themeName: firstThemeQ.themeName,
          isBasicMaterial: firstThemeQ.isBasicMaterial,
          questionIds: List.unmodifiable(
            themeQuestions.map((q) => q.questionId),
          ),
          chapters: List.unmodifiable(chapters),
        ),
      );
    }

    return List.unmodifiable(result);
  }

  static int _compareCode(String a, String b) {
    final aParts = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final bParts = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final len = aParts.length < bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < len; i++) {
      final cmp = aParts[i].compareTo(bParts[i]);
      if (cmp != 0) return cmp;
    }
    return aParts.length.compareTo(bParts.length);
  }
}

class CatalogRepository {
  CatalogRepository({required Map<AppLanguage, LocalizedCatalog> catalogs})
    : _catalogs = Map.unmodifiable(catalogs);

  final Map<AppLanguage, LocalizedCatalog> _catalogs;

  static Future<CatalogRepository> loadFromAssets({AssetBundle? bundle}) async {
    final effectiveBundle = bundle ?? rootBundle;
    final enRaw = await effectiveBundle.loadString(AppLanguage.en.assetPath);
    final deRaw = await effectiveBundle.loadString(AppLanguage.de.assetPath);

    final enList = (jsonDecode(enRaw) as List<dynamic>)
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final deList = (jsonDecode(deRaw) as List<dynamic>)
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);

    return CatalogRepository(
      catalogs: {
        AppLanguage.en: LocalizedCatalog(enList),
        AppLanguage.de: LocalizedCatalog(deList),
      },
    );
  }

  factory CatalogRepository.fromQuestions({
    required List<Question> englishQuestions,
    List<Question>? germanQuestions,
  }) {
    final enCatalog = LocalizedCatalog(englishQuestions);
    final deCatalog = LocalizedCatalog(germanQuestions ?? englishQuestions);
    return CatalogRepository(
      catalogs: {AppLanguage.en: enCatalog, AppLanguage.de: deCatalog},
    );
  }

  LocalizedCatalog forLanguage(AppLanguage language) =>
      _catalogs[language] ?? _catalogs.values.first;

  List<Question> questionsFor(AppLanguage language) =>
      forLanguage(language).questions;

  Question? questionById(String questionId, AppLanguage language) =>
      forLanguage(language).byId[questionId];

  List<ThemeInfo> themesFor(AppLanguage language) =>
      forLanguage(language).themes;

  int get totalQuestions => forLanguage(AppLanguage.en).questions.length;
}
