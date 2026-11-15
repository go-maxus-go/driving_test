import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../data/catalog_repository.dart';
import '../l10n/app_language.dart';
import '../models/answer_evaluation.dart';
import '../models/question.dart';
import '../models/user_progress.dart';
import '../services/exam_engine.dart';
import '../services/progress_storage.dart';
import '../services/smart_queue_builder.dart';

class TopicTrainingNeed {
  const TopicTrainingNeed({required this.theme, required this.stats});

  final ThemeInfo theme;
  final CoverageStats stats;
}

class AppController extends ChangeNotifier {
  AppController({
    required this.catalog,
    required ProgressStorage storage,
    PersistedUserData? initialData,
    int Function()? clockMs,
  }) : _clockMs = clockMs ?? (() => DateTime.now().millisecondsSinceEpoch),
       _language = initialData?.language ?? AppLanguage.en,
       _hasChosenLanguage = initialData?.hasChosenLanguage ?? false,
       _isDarkMode = initialData?.isDarkMode ?? false,
       _practiceBatchSize =
           (initialData?.practiceBatchSize ??
                   SmartQueueBuilder.defaultSmartBatchSize)
               .clamp(
                 SmartQueueBuilder.minBatchSize,
                 SmartQueueBuilder.maxBatchSize,
               ),
       _progressById = Map<String, QuestionProgress>.from(
         initialData?.progressById ?? const {},
       ),
       _examHistory = List<ExamResultRecord>.from(
         initialData?.examHistory ?? const [],
       ),
       _starredThemeCodes = Set<String>.from(
         initialData?.starredThemeCodes ?? const <String>{},
       ),
       _activeExam = initialData?.activeExam {
    _storage = storage;
  }

  final CatalogRepository catalog;
  late final ProgressStorage _storage;
  final int Function() _clockMs;

  AppLanguage _language;
  bool _hasChosenLanguage;
  bool _isDarkMode;
  int _practiceBatchSize;
  final Map<String, QuestionProgress> _progressById;
  final List<ExamResultRecord> _examHistory;
  final Set<String> _starredThemeCodes;
  ActiveExamSession? _activeExam;

  static Future<AppController> initialize({
    CatalogRepository? catalogRepository,
    ProgressStorage? storage,
  }) async {
    final repo = catalogRepository ?? await CatalogRepository.loadFromAssets();
    final store = storage ?? SharedPreferencesProgressStorage();
    final persisted = await store.load();
    return AppController(catalog: repo, storage: store, initialData: persisted);
  }

  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);
  bool get hasChosenLanguage => _hasChosenLanguage;
  bool get isDarkMode => _isDarkMode;
  int get practiceBatchSize => _practiceBatchSize;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Map<String, QuestionProgress> get progressById =>
      Map.unmodifiable(_progressById);
  List<ExamResultRecord> get examHistory => List.unmodifiable(_examHistory);
  Set<String> get starredThemeCodes => Set.unmodifiable(_starredThemeCodes);
  ActiveExamSession? get activeExam => _activeExam;

  List<Question> get currentQuestions => catalog.questionsFor(_language);
  Map<String, Question> get currentQuestionsById =>
      catalog.forLanguage(_language).byId;
  List<ThemeInfo> get currentThemes => catalog.themesFor(_language);

  Question? questionById(String id, {AppLanguage? inLanguage}) =>
      catalog.questionById(id, inLanguage ?? _language);

  QuestionProgress progressFor(String questionId) =>
      _progressById[questionId] ?? QuestionProgress(questionId: questionId);

  bool isBookmarked(String questionId) =>
      _progressById[questionId]?.isBookmarked ?? false;

  bool isThemeStarred(String themeCode) =>
      _starredThemeCodes.contains(themeCode);

  CoverageStats get globalStats => CoverageStats.compute(
    currentQuestions.map((q) => q.questionId),
    _progressById,
  );

  int get learnedQuestionsCount =>
      currentQuestions.where((q) => progressFor(q.questionId).isLearned).length;

  int get inTrainingQuestionsCount => currentQuestions
      .where((q) => progressFor(q.questionId).isInTraining)
      .length;

  int get unseenQuestionsCount =>
      currentQuestions.where((q) => progressFor(q.questionId).isUnseen).length;

  /// Composite Exam Readiness percentage (0..100):
  /// - Up to 65 points from catalog mastery coverage
  /// - Up to 35 points from recent mock exam performance (or scaled accuracy
  ///   when no mock exams have been taken yet)
  int get readinessPercent {
    final stats = globalStats;
    if (stats.totalQuestions == 0) return 0;

    final masteryRatio = stats.correctQuestions / stats.totalQuestions;
    final coverageComponent = masteryRatio * 65.0;

    double examComponent;
    if (_examHistory.isEmpty) {
      examComponent = masteryRatio * stats.accuracyRate * 35.0;
    } else {
      final recent = _examHistory.take(3).toList();
      final passRatio = recent.where((e) => e.passed).length / recent.length;
      final avgPointsScore =
          recent.fold<double>(
            0.0,
            (sum, e) => sum + max(0.0, (15.0 - e.totalErrorPoints) / 15.0),
          ) /
          recent.length;
      examComponent = ((passRatio * 0.7) + (avgPointsScore * 0.3)) * 35.0;
    }

    return (coverageComponent + examComponent).round().clamp(0, 100);
  }

  // --- Language, First Launch, Practice Size & Theme Preferences ---

  Future<void> setLanguage(AppLanguage newLanguage) async {
    if (_language == newLanguage) return;
    _language = newLanguage;
    notifyListeners();
    await _persist();
  }

  Future<void> confirmFirstLaunchLanguage(AppLanguage chosenLanguage) async {
    _language = chosenLanguage;
    _hasChosenLanguage = true;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _persist();
  }

  Future<void> setPracticeBatchSize(int size) async {
    final clamped = size.clamp(
      SmartQueueBuilder.minBatchSize,
      SmartQueueBuilder.maxBatchSize,
    );
    if (_practiceBatchSize == clamped) return;
    _practiceBatchSize = clamped;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleThemeStarred(String themeCode) async {
    if (!_starredThemeCodes.remove(themeCode)) {
      _starredThemeCodes.add(themeCode);
    }
    notifyListeners();
    await _persist();
  }

  // --- Question Answering & Bookmarking ---

  Future<AnswerEvaluation> recordPracticeAnswer({
    required Question question,
    required AnswerSubmission submission,
  }) async {
    final evaluation = AnswerEvaluator.evaluate(question, submission);
    final existing = progressFor(question.questionId);
    _progressById[question.questionId] = existing.recordAttempt(
      isCorrect: evaluation.isCorrect,
      timestampMs: _clockMs(),
    );
    notifyListeners();
    await _persist();
    return evaluation;
  }

  Future<void> toggleBookmark(String questionId) async {
    final existing = progressFor(questionId);
    _progressById[questionId] = existing.toggleBookmark();
    notifyListeners();
    await _persist();
  }

  // --- Smart Queue Builders & Counts ---

  List<String> buildSmartPracticeQueue({int? batchSize, Random? random}) =>
      SmartQueueBuilder.buildSmartPractice(
        allQuestions: currentQuestions,
        progressMap: _progressById,
        batchSize: batchSize ?? _practiceBatchSize,
        random: random,
      );

  List<String> buildMostMistakesQueue() => SmartQueueBuilder.buildMostMistakes(
    allQuestions: currentQuestions,
    progressMap: _progressById,
  );

  List<String> buildLeastAnsweredQueue({
    int? maxAttemptsExclusive,
    Random? random,
  }) => SmartQueueBuilder.buildLeastAnswered(
    allQuestions: currentQuestions,
    progressMap: _progressById,
    maxAttemptsExclusive: maxAttemptsExclusive,
    random: random,
  );

  int get mostMistakesCount => buildMostMistakesQueue().length;

  /// Count displayed on the "Least Answered" card: unseen (`0x`) if any remain,
  /// otherwise questions answered only once (`1x`), otherwise total catalog.
  int get leastAnsweredBadgeCount {
    final unseen = globalStats.unseenQuestions;
    if (unseen > 0) return unseen;
    final once = exposureCountFor(exactAttempts: 1);
    if (once > 0) return once;
    return currentQuestions.length;
  }

  List<String> buildFivePointQueue() => SmartQueueBuilder.buildTopicQueue(
    scopedQuestionIds: currentQuestions
        .where((q) => q.points == 5)
        .map((q) => q.questionId),
    questionsById: currentQuestionsById,
    progressMap: _progressById,
  );

  List<String> buildVideoQueue() => SmartQueueBuilder.buildTopicQueue(
    scopedQuestionIds: currentQuestions
        .where((q) => q.mediaKind == QuestionMediaKind.video)
        .map((q) => q.questionId),
    questionsById: currentQuestionsById,
    progressMap: _progressById,
  );

  List<String> buildNumericQueue() => SmartQueueBuilder.buildTopicQueue(
    scopedQuestionIds: currentQuestions
        .where((q) => q.inputKind == QuestionInputKind.numericInput)
        .map((q) => q.questionId),
    questionsById: currentQuestionsById,
    progressMap: _progressById,
  );

  List<String> buildSavedQueue() => currentQuestions
      .where((q) => isBookmarked(q.questionId))
      .map((q) => q.questionId)
      .toList(growable: false);

  List<String> buildTopicQueue(
    Iterable<String> questionIds, {
    bool unfinishedOnly = true,
  }) => SmartQueueBuilder.buildTopicQueue(
    scopedQuestionIds: questionIds,
    questionsById: currentQuestionsById,
    progressMap: _progressById,
    unfinishedOnly: unfinishedOnly,
  );

  int exposureCountFor({int? exactAttempts, int? minAttempts}) {
    var count = 0;
    for (final q in currentQuestions) {
      final att = _progressById[q.questionId]?.attemptsCount ?? 0;
      if (exactAttempts != null && att == exactAttempts) count++;
      if (minAttempts != null && att >= minAttempts) count++;
    }
    return count;
  }

  List<TopicTrainingNeed> get rankedWeakTopics {
    final items = <TopicTrainingNeed>[];
    for (final theme in currentThemes) {
      final stats = CoverageStats.compute(theme.questionIds, _progressById);
      if (stats.totalAttempts > 0) {
        items.add(TopicTrainingNeed(theme: theme, stats: stats));
      }
    }
    items.sort((a, b) {
      final wrongCmp = b.stats.wrongQuestions.compareTo(a.stats.wrongQuestions);
      if (b.stats.errorRate != a.stats.errorRate) {
        return b.stats.errorRate.compareTo(a.stats.errorRate);
      }
      return wrongCmp;
    });
    return items;
  }

  // --- Official Exam Simulation Lifecycle ---

  Future<ActiveExamSession> startNewExam({Random? random}) async {
    final session = ExamEngine.generateSession(
      allQuestions: currentQuestions,
      nowMs: _clockMs(),
      random: random,
    );
    _activeExam = session;
    notifyListeners();
    await _persist();
    return session;
  }

  Future<ActiveExamSession> retryExam(List<String> questionIds) async {
    final now = _clockMs();
    final session = ActiveExamSession(
      sessionId: 'exam_$now',
      questionIds: List<String>.from(questionIds),
      startedAtMs: now,
    );
    _activeExam = session;
    notifyListeners();
    await _persist();
    return session;
  }

  Future<void> updateExamSubmission(
    String questionId,
    AnswerSubmission submission,
  ) async {
    final exam = _activeExam;
    if (exam == null) return;
    exam.submissions[questionId] = submission;
    notifyListeners();
    await _persist();
  }

  Future<void> setExamIndex(int index) async {
    final exam = _activeExam;
    if (exam == null) return;
    if (index < 0 || index >= exam.questionIds.length) return;
    exam.currentIndex = index;
    notifyListeners();
    await _persist();
  }

  Future<void> toggleExamFlag(String questionId) async {
    final exam = _activeExam;
    if (exam == null) return;
    if (!exam.flaggedIds.remove(questionId)) {
      exam.flaggedIds.add(questionId);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> recordExamVideoPlay(String questionId) async {
    final exam = _activeExam;
    if (exam == null || exam.isVideoLocked(questionId)) return;
    final used = exam.playsUsedFor(questionId);
    if (used < ActiveExamSession.maxVideoPlays) {
      exam.videoPlaysUsed[questionId] = used + 1;
      notifyListeners();
      await _persist();
    }
  }

  Future<void> lockExamVideoAndRevealQuestion(String questionId) async {
    final exam = _activeExam;
    if (exam == null) return;
    exam.videoLockedIds.add(questionId);
    notifyListeners();
    await _persist();
  }

  void tickExamTimer(int newRemainingSeconds) {
    final exam = _activeExam;
    if (exam == null) return;
    exam.remainingSeconds = max(0, newRemainingSeconds);
    // Persist periodically on 10-second boundaries to avoid excessive disk I/O
    if (exam.remainingSeconds % 10 == 0) {
      unawaited(_persist());
    }
  }

  Future<void> discardActiveExam() async {
    _activeExam = null;
    notifyListeners();
    await _persist();
  }

  Future<ExamResultRecord> submitActiveExam() async {
    final exam = _activeExam;
    if (exam == null) {
      throw StateError('No active exam to submit.');
    }
    final now = _clockMs();
    final result = ExamEngine.gradeSession(
      session: exam,
      questionsById: currentQuestionsById,
      completedAtMs: now,
    );

    // Feed exam outcomes into unified per-question learning telemetry
    final wrongSet = result.wrongQuestionIds.toSet();
    for (final qid in exam.questionIds) {
      final existing = progressFor(qid);
      _progressById[qid] = existing.recordAttempt(
        isCorrect: !wrongSet.contains(qid),
        timestampMs: now,
      );
    }

    _examHistory.insert(0, result);
    _activeExam = null;
    notifyListeners();
    await _persist();
    return result;
  }

  // --- Backup & Reset ---

  String exportBackupJson() {
    final payload = PersistedUserData(
      language: _language,
      hasChosenLanguage: _hasChosenLanguage,
      isDarkMode: _isDarkMode,
      practiceBatchSize: _practiceBatchSize,
      progressById: _progressById,
      examHistory: _examHistory,
      starredThemeCodes: _starredThemeCodes,
      activeExam: _activeExam,
    ).toBackupJson();
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<bool> importBackupJson(String rawJson) async {
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final imported = PersistedUserData.fromBackupJson(decoded);
      _language = imported.language;
      _hasChosenLanguage = imported.hasChosenLanguage;
      _isDarkMode = imported.isDarkMode;
      _practiceBatchSize = imported.practiceBatchSize;
      _progressById
        ..clear()
        ..addAll(imported.progressById);
      _examHistory
        ..clear()
        ..addAll(imported.examHistory);
      _starredThemeCodes
        ..clear()
        ..addAll(imported.starredThemeCodes);
      _activeExam = imported.activeExam;
      notifyListeners();
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetAllProgress() async {
    _progressById.clear();
    _examHistory.clear();
    _starredThemeCodes.clear();
    _activeExam = null;
    notifyListeners();
    await _storage.clear();
    await _persist();
  }

  Future<void> _persist() async {
    await _storage.save(
      PersistedUserData(
        language: _language,
        hasChosenLanguage: _hasChosenLanguage,
        isDarkMode: _isDarkMode,
        practiceBatchSize: _practiceBatchSize,
        progressById: Map<String, QuestionProgress>.from(_progressById),
        examHistory: List<ExamResultRecord>.from(_examHistory),
        starredThemeCodes: Set<String>.from(_starredThemeCodes),
        activeExam: _activeExam,
      ),
    );
  }
}
