import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_language.dart';
import '../models/user_progress.dart';
import 'exam_engine.dart';
import 'smart_queue_builder.dart';

class PersistedUserData {
  const PersistedUserData({
    this.language = AppLanguage.en,
    this.hasChosenLanguage = false,
    this.isDarkMode = false,
    this.practiceBatchSize = SmartQueueBuilder.defaultSmartBatchSize,
    this.progressById = const <String, QuestionProgress>{},
    this.examHistory = const <ExamResultRecord>[],
    this.starredThemeCodes = const <String>{},
    this.activeExam,
  });

  final AppLanguage language;
  final bool hasChosenLanguage;
  final bool isDarkMode;
  final int practiceBatchSize;
  final Map<String, QuestionProgress> progressById;
  final List<ExamResultRecord> examHistory;
  final Set<String> starredThemeCodes;
  final ActiveExamSession? activeExam;

  Map<String, dynamic> toBackupJson() => {
    'schemaVersion': 1,
    'language': language.code,
    'hasChosenLanguage': hasChosenLanguage,
    'isDarkMode': isDarkMode,
    'practiceBatchSize': practiceBatchSize,
    'starredThemeCodes': starredThemeCodes.toList(),
    'progress': [for (final p in progressById.values) p.toJson()],
    'examHistory': [for (final e in examHistory) e.toJson()],
    if (activeExam != null) 'activeExam': activeExam!.toJson(),
  };

  factory PersistedUserData.fromBackupJson(Map<String, dynamic> json) {
    final rawProgress = json['progress'] as List<dynamic>? ?? const [];
    final progressMap = <String, QuestionProgress>{};
    for (final item in rawProgress) {
      final p = QuestionProgress.fromJson(item as Map<String, dynamic>);
      if (p.questionId.isNotEmpty) {
        progressMap[p.questionId] = p;
      }
    }

    final rawExams = json['examHistory'] as List<dynamic>? ?? const [];
    final exams = rawExams
        .map((e) => ExamResultRecord.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final rawActive = json['activeExam'] as Map<String, dynamic>?;
    final rawStarred = json['starredThemeCodes'] as List<dynamic>? ?? const [];
    final rawBatchSize = json['practiceBatchSize'] as int?;

    return PersistedUserData(
      language: AppLanguage.fromCode(json['language'] as String?),
      hasChosenLanguage: json['hasChosenLanguage'] as bool? ?? false,
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      practiceBatchSize:
          rawBatchSize?.clamp(
            SmartQueueBuilder.minBatchSize,
            SmartQueueBuilder.maxBatchSize,
          ) ??
          SmartQueueBuilder.defaultSmartBatchSize,
      progressById: progressMap,
      examHistory: exams,
      starredThemeCodes: rawStarred.map((e) => e.toString()).toSet(),
      activeExam: rawActive != null
          ? ActiveExamSession.fromJson(rawActive)
          : null,
    );
  }
}

abstract class ProgressStorage {
  Future<PersistedUserData> load();
  Future<void> save(PersistedUserData data);
  Future<void> clear();
}

class InMemoryProgressStorage implements ProgressStorage {
  InMemoryProgressStorage([PersistedUserData? initial])
    : _data = initial ?? const PersistedUserData();

  PersistedUserData _data;

  @override
  Future<PersistedUserData> load() async => _data;

  @override
  Future<void> save(PersistedUserData data) async {
    _data = data;
  }

  @override
  Future<void> clear() async {
    _data = const PersistedUserData();
  }
}

class SharedPreferencesProgressStorage implements ProgressStorage {
  static const String _storageKey = 'driving_exam_user_data_v1';

  @override
  Future<PersistedUserData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return const PersistedUserData();
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return PersistedUserData.fromBackupJson(decoded);
    } catch (_) {
      return const PersistedUserData();
    }
  }

  @override
  Future<void> save(PersistedUserData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data.toBackupJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
