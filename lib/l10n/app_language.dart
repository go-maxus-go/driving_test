import '../models/user_progress.dart';

enum AppLanguage {
  en('en', 'EN', 'English'),
  de('de', 'DE', 'Deutsch');

  const AppLanguage(this.code, this.shortLabel, this.displayName);

  final String code;
  final String shortLabel;
  final String displayName;

  AppLanguage get opposite =>
      this == AppLanguage.en ? AppLanguage.de : AppLanguage.en;

  String get assetPath => this == AppLanguage.de
      ? 'assets/driving_theory_questions_de_b.json'
      : 'assets/driving_theory_questions_b.json';

  static AppLanguage fromCode(String? code) {
    if (code == null) return AppLanguage.en;
    final clean = code.trim().toLowerCase();
    if (clean.startsWith('de')) return AppLanguage.de;
    return AppLanguage.en;
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;
  bool get isDe => language == AppLanguage.de;

  String get appTitle =>
      isDe ? 'Führerschein Klasse B' : 'Class B Theory Trainer';
  String get navTrain => isDe ? 'Üben' : 'Train';
  String get navTopics => isDe ? 'Themen' : 'Topics';
  String get navProgress => isDe ? 'Fortschritt' : 'Progress';
  String get navFormulas => isDe ? 'Formeln & Regeln' : 'Formulas & Rules';
  String get navSettings => isDe ? 'Einstellungen' : 'Settings';
  String get navAbout => isDe ? 'Über die App' : 'About App';

  // First Launch Language Selector Modal
  String get welcomeLanguageTitle =>
      isDe ? 'Lernsprache wählen' : 'Choose your study language';
  String get welcomeLanguageSubtitle => isDe
      ? 'Englisch ist voreingestellt. Deutsch ist optional. Du kannst dies jederzeit in den Einstellungen ändern.'
      : 'English is selected by default. German is optional. You can change this anytime in Settings.';
  String get welcomeLanguageEnglish =>
      isDe ? 'Englisch (Standard)' : 'English (Default)';
  String get welcomeLanguageGerman =>
      isDe ? 'Deutsch (Optional)' : 'Deutsch (Optional)';
  String get welcomeContinue => isDe ? 'Weiter' : 'Continue';

  // Main Menu / Practice Screen
  String get examReadiness => isDe ? 'FORTSCHRITT' : 'PROGRESS';
  String readinessStatus(int percent) {
    if (percent >= 85) {
      return isDe ? 'Prüfungsreif!' : 'Exam Ready!';
    }
    if (percent >= 60) {
      return isDe ? 'Guter Fortschritt' : 'Great Progress';
    }
    return isDe ? 'Im Lernen' : 'In Progress';
  }

  String get masteredLabel => isDe ? 'Gemeistert' : 'Mastered';
  String get mistakesLabel => isDe ? 'Fehler' : 'Mistakes';
  String get unseenLabel => isDe ? 'Ungesehen' : 'Unseen';
  String get inTrainingLabel => isDe ? 'Im Training' : 'In Training';
  String get learnedLabel => isDe ? 'Gelernt' : 'Learned';
  String get leftLabel => isDe ? 'übrig' : 'left';
  String ofTotalQuestions(int total) =>
      isDe ? 'von $total Fragen gesamt' : 'of $total total questions';

  String get smartPracticeTitle => isDe ? 'Üben' : 'Practice';
  String get smartPracticeSubtitle => isDe
      ? 'Mischung aus neuen Fragen und bisherigen Fehlern'
      : 'Mix of unseen questions and previous mistakes';
  String get startLabel => isDe ? 'Starten' : 'Start';
  String get beginLabel => isDe ? 'Beginnen' : 'Begin';
  String get resumeExamBannerTitle => isDe
      ? 'Laufende Prüfungssimulation fortsetzen'
      : 'Resume Active Mock Exam';
  String get resumeAction => isDe ? 'Weiter' : 'Resume';

  String get targetedDrillsHeader =>
      isDe ? 'GEZIELTES TRAINING' : 'TARGETED DRILLS';
  String get drillMostMistakes => isDe ? 'Häufige Fehler' : 'Most Mistakes';
  String get drillMostMistakesSub =>
      isDe ? 'Fragen mit vielen Fehlern' : 'Questions with most mistakes';
  String get drillLeastAnswered => isDe ? 'Wenig geübt' : 'Least Answered';
  String get drillLeastAnsweredSub =>
      isDe ? 'Selten geübte Fragen' : 'Least practiced questions';
  String get drillFivePoint => isDe ? '5-Punkte-Fragen' : '5-Point Traps';
  String get drillFivePointSub =>
      isDe ? '2 Fehler = durchgefallen' : '2 wrong = exam fail';
  String get drillVideos => isDe ? 'Videofragen' : 'Video Questions';
  String get drillVideosSub =>
      isDe ? 'Dynamische Verkehrsszenen' : 'Traffic hazard videos';
  String get drillImages => isDe ? 'Bildfragen' : 'Image Questions';
  String get drillImagesSub =>
      isDe ? 'Verkehrssituationen im Bild' : 'Traffic scene pictures';
  String get drillSigns => isDe ? 'Verkehrszeichen' : 'Sign Questions';
  String get drillSignsSub =>
      isDe ? 'Schilder & Markierungen' : 'Road signs & markings';
  String get drillNumeric => isDe ? 'Zahlenfragen' : 'Number Input';
  String get drillNumericSub =>
      isDe ? 'Formeln & Distanzen' : 'Formulas & distances';
  String get drillSaved => isDe ? 'Gemerkt' : 'Saved';
  String get drillSavedSub => isDe ? 'Deine Merkliste' : 'Your saved questions';
  String get noQuestionsInDrill => isDe
      ? 'Keine Fragen in dieser Auswahl vorhanden!'
      : 'No questions currently in this filter!';

  String get examSimulationTitle =>
      isDe ? 'Prüfungssimulation' : 'Exam Simulation';
  String examSimulationSubtitle([String? lastSummary]) {
    final base = isDe ? '30 Fragen • 45 Min.' : '30 questions • 45 min';
    if (lastSummary == null || lastSummary.isEmpty) return base;
    return '$lastSummary • $base';
  }

  // Question Player
  String pointsBadge(int pts) => isDe ? '$pts Punkte' : '$pts Pts';
  String get checkAnswer => isDe ? 'Antwort prüfen' : 'Check Answer';
  String get nextQuestion => isDe ? 'Nächste Frage' : 'Next Question';
  String get prevQuestion => isDe ? 'Zurück' : 'Prev';
  String get retryQuestion => isDe ? 'Wiederholen' : 'Retry';
  String get finishSession => isDe ? 'Training abschließen' : 'Finish Session';
  String get skipQuestion => isDe ? 'Überspringen' : 'Skip';
  String get badgeCorrect => isDe ? 'Richtig' : 'Correct';
  String get badgeWrong => isDe ? 'Falsch' : 'Wrong';
  String get badgeMissed => isDe ? 'Fehlt!' : 'Missed!';
  String get feedbackPerfect =>
      isDe ? 'Richtig beantwortet!' : 'Correctly answered!';
  String feedbackIncorrect(int pts) => isDe
      ? 'Nicht ganz richtig — +$pts Fehlerpunkte'
      : 'Not quite right — +$pts Error Points';
  String get explanationTitle => isDe ? 'Erklärung' : 'Explanation';
  String get showExplanation => isDe ? 'Erklärung' : 'Explanation';
  String get variantNoticeTitle =>
      isDe ? 'Variierte Prüfungsfrage (-M)' : 'Exam Variation Question (-M)';
  String get variantNoticeBody => isDe
      ? 'In der echten Prüfung können Fahrzeugfarben, Fahrzeugtypen oder das Wetter variieren. Achte auf die Verkehrsregel, nicht auf Bilddetails.'
      : 'On exam day, vehicle colors, types, or weather in this scene may vary. Focus on the underlying traffic rule rather than memorizing visual details.';
  String get numericInputHint => isDe
      ? 'Zahl eingeben (z. B. 60 oder 1,6)'
      : 'Enter number (e.g. 60 or 1.6)';
  String yourNumericAnswer(String val) =>
      isDe ? 'Deine Eingabe: $val' : 'Your answer: $val';
  String correctNumericAnswer(String val) =>
      isDe ? 'Richtige Antwort: $val' : 'Correct answer: $val';
  String peekTranslationLabel(AppLanguage other) => isDe
      ? 'Englische Übersetzung (${other.shortLabel})'
      : 'German Original (${other.shortLabel})';
  String get zoomImageTooltip => isDe ? 'Bild vergrößern' : 'Zoom image';
  String get bookmarkTooltip => isDe ? 'Frage merken' : 'Save question';
  String get keyboardShortcutsHint => isDe
      ? 'Tasten: [1-3] Auswahl • [Eingabe/Leertaste] Prüfen/Weiter • [B] Merken'
      : 'Keys: [1-3] Toggle • [Enter/Space] Check/Next • [B] Save';

  // Video Controls
  String get watchVideoCarefully => isDe
      ? 'Beobachte die Verkehrsszene genau (Spiegel, Tempo, Verkehrszeichen).'
      : 'Watch the traffic scene carefully (mirrors, speed, and signs).';
  String videoPlaysRemaining(int remaining, int maxPlays) => isDe
      ? 'Verbleibende Wiedergaben: $remaining von $maxPlays'
      : 'Plays remaining: $remaining of $maxPlays';
  String watchAgainButton(int remaining) => isDe
      ? 'Video erneut abspielen ($remaining übrig)'
      : 'Watch Video Again ($remaining left)';
  String get replayVideo => isDe ? 'Video wiederholen' : 'Replay Video';
  String get showQuestionAndAnswers =>
      isDe ? 'Zur Aufgabenstellung →' : 'Show Question & Answers →';
  String get tuvVideoRuleNote => isDe
      ? 'Hinweis (TÜV-Regel): Sobald du zur Aufgabenstellung wechselst, wird nur noch das Standbild angezeigt.'
      : 'TÜV Rule: Once you open the question, only the final freeze-frame remains visible.';
  String get freezeFrameBadge => isDe ? 'Gesperrt' : 'Locked';
  String get examStyleVideoToggle =>
      isDe ? 'TÜV-Videomodus' : 'Exam Video Mode';
  String get fullScreenVideo => isDe ? 'Vollbild' : 'Full screen';

  // Session Complete
  String get sessionCompleteTitle =>
      isDe ? 'Durchgang abgeschlossen!' : 'Session Complete!';
  String get continueMoreQuestions =>
      isDe ? 'Weiter üben' : 'Continue practice';
  String get retrySessionMistakes =>
      isDe ? 'Fehler aus dieser Runde üben' : 'Retry Session Mistakes';
  String get backToMenu => isDe ? 'Zurück zum Menü' : 'Back to Menu';

  // Topics Screen
  String get topicsTitle => isDe ? 'Themen' : 'Topics';
  String get searchQuestionsHint =>
      isDe ? 'Fragen & Themen suchen...' : 'Search questions or topics...';
  String get filterAll => isDe ? 'Alle Themen' : 'All Topics';
  String get filterAllClassB => isDe ? 'Alle Themen' : 'All Topics';
  String get filterGrundstoff =>
      isDe ? 'Grundstoff (1.x)' : 'Basic Material (1.x)';
  String get filterZusatzstoff =>
      isDe ? 'Zusatzstoff B (2.x)' : 'Class B Add-on (2.x)';
  String get formulasButton => isDe ? 'Formeln & Regeln' : 'Formulas & Rules';
  String get multiSelectTopics => isDe ? 'Mehrfachauswahl' : 'Select Multiple';
  String get cancelSelection => isDe ? 'Abbrechen' : 'Cancel';
  String practiceSelectedTopics(int count, int questions) => isDe
      ? '$count Themen üben ($questions Fragen) →'
      : 'Practice $count Topics ($questions Qs) →';
  String chaptersCount(int count) =>
      isDe ? '$count Kapitel' : '$count chapters';
  String get topicScopeUnfinished =>
      isDe ? 'Offene & Fehler zuerst' : 'Unseen & Mistakes First';
  String get topicScopeAll => isDe ? 'Alle Fragen' : 'All Questions';
  String get starTopicTooltip =>
      isDe ? 'Thema favorisieren' : 'Star this topic';
  String get unstarTopicTooltip =>
      isDe ? 'Favorit entfernen' : 'Remove from starred';

  // Formulas Sheet
  String get formulasSheetTitle => isDe
      ? 'Wichtige Faustformeln & Grenzwerte'
      : 'Essential German Driving Formulas & Limits';

  // Exam Mode & Verdict
  String get submitExam => isDe ? 'Abgeben' : 'Submit';
  String get flagQuestion => isDe ? 'Markieren' : 'Flag';
  String get flaggedQuestion => isDe ? 'Markiert' : 'Flagged';
  String get finishAndGradeExam =>
      isDe ? 'Prüfung abgeben & auswerten' : 'Finish & Grade Exam';
  String get questionOverviewTitle =>
      isDe ? 'Fragenübersicht (1–30)' : 'Question Navigator (1–30)';
  String unansweredWarningTitle(int unanswered, int flagged) {
    if (unanswered > 0) {
      return isDe
          ? 'Noch $unanswered unbeantwortete Fragen!'
          : 'You have $unanswered unanswered questions!';
    }
    return isDe
        ? '$flagged markierte Fragen zur Überprüfung'
        : 'You have $flagged flagged questions to review';
  }

  String jumpToQuestion(int num) =>
      isDe ? 'Zu Frage $num springen' : 'Jump to Question $num';
  String get jumpToFirstOpen =>
      isDe ? 'Zur offenen Frage springen' : 'Jump to Question';
  String get submitAnyway => isDe ? 'Trotzdem abgeben' : 'Submit Anyway';
  String get pauseExamTitle =>
      isDe ? 'Prüfung pausieren oder beenden?' : 'Pause or Discard Exam?';
  String get pauseAndSave =>
      isDe ? 'Pausieren & später fortsetzen' : 'Pause & Save for Later';
  String get discardExam => isDe ? 'Prüfung verwerfen' : 'Discard Exam';

  String get examPassed => isDe ? 'BESTANDEN!' : 'PASSED! (BESTANDEN)';
  String get examFailed =>
      isDe ? 'NICHT BESTANDEN' : 'FAILED (NICHT BESTANDEN)';
  String errorPointsSummary(int pts) => isDe
      ? '$pts / 10 Fehlerpunkte (max. 10 erlaubt)'
      : '$pts / 10 Error Points (max 10 allowed)';
  String get examVerdictSubtitlePassed => isDe
      ? 'Herzlichen Glückwunsch! Du hast die theoretische Prüfung bestanden.'
      : 'Congratulations! You passed the theoretical Class B exam.';
  String get examVerdictSubtitleFailed => isDe
      ? 'Leider nicht bestanden. Übe deine Fehler und versuche es erneut.'
      : 'Not passed. Drill your mistakes and simulate again.';
  String practiceExamMistakes([int? count]) => isDe
      ? (count != null ? '$count Prüfungsfehler üben' : 'Prüfungsfehler üben')
      : (count != null
            ? 'Practice $count Exam Mistakes'
            : 'Practice Exam Mistakes');
  String get reviewExamQuestions =>
      isDe ? 'Alle 30 Fragen ansehen' : 'Review All 30 Questions';
  String get reviewWrongOnly =>
      isDe ? 'Nur Fehler wiederholen' : 'Review Mistakes Only';
  String get reviewAll30 => isDe ? 'Alle 30 Fragen ansehen' : 'Review All 30';
  String mistakesOnlyCheckboxLabel(int count) =>
      isDe ? 'Nur Fehler ($count)' : 'Mistakes Only ($count)';
  String get takeAnotherExam =>
      isDe ? 'Neue Prüfung starten' : 'Start New Exam';
  String get newExamButton => isDe ? 'Neue Prüfung' : 'New Exam';
  String get twoFivePointFailWarning => isDe
      ? '2 oder mehr 5-Punkte-Fragen falsch beantwortet (automatisch durchgefallen)'
      : '2 or more 5-point questions answered incorrectly (automatic exam fail)';
  String get fivePointRuleOk => isDe
      ? 'Höchstens eine 5-Punkte-Frage falsch'
      : 'At most one 5-point question incorrect';

  // Progress Screen
  String get progressAnalyticsTitle =>
      isDe ? 'Fortschritt & Statistik' : 'Progress & Analytics';
  String get mockExamHistoryTitle =>
      isDe ? 'Prüfungshistorie' : 'Mock Exam History';
  String get viewMockExamHistory =>
      isDe ? 'Prüfungshistorie anzeigen' : 'View Mock Exam History';
  String get noMockExamsYet =>
      isDe ? 'Noch keine Prüfung absolviert' : 'No mock exams taken yet';
  String get topicsNeedingTraining =>
      isDe ? 'Themen mit Nachholbedarf' : 'Topics Needing Training';
  String get allTopicsInGoodShape => isDe
      ? 'Hervorragend! Keine auffälligen Schwachstellen.'
      : 'Great job! No weak topics detected yet.';
  String get questionExposureTitle =>
      isDe ? 'Lernstatus der Fragen' : 'Question Learning Status';
  String get questionExposureExplanation => isDe
      ? 'Eine Frage gilt als "Gelernt", wenn du sie 2-mal hintereinander richtig beantwortet hast.'
      : 'A question is considered "Learned" once answered correctly 2 times in a row.';
  String get unseenBucketTitle => isDe ? 'Ungesehen' : 'Unseen';
  String get inTrainingBucketTitle => isDe ? 'Im Training' : 'In Training';
  String get learnedBucketTitle => isDe ? 'Gelernt' : 'Learned';
  String get neverAnsweredBucketTitle => isDe ? 'Ungesehen' : 'Unseen';
  String get answeredOnceBucketTitle => isDe ? 'Im Training' : 'In Training';
  String get practicedMultipleBucketTitle => isDe ? 'Gelernt' : 'Learned';
  String bucketDescription(QuestionExposureBucket bucket) {
    switch (bucket) {
      case QuestionExposureBucket.neverAnswered:
        return isDe ? 'Noch nie geübt' : 'Never attempted';
      case QuestionExposureBucket.answeredOnce:
        return isDe
            ? 'In Übung (noch nicht gefestigt)'
            : 'Attempted, not yet mastered';
      case QuestionExposureBucket.practicedMultiple:
        return isDe
            ? 'Zuletzt 2x in Folge richtig'
            : 'Last 2 consecutive times correct';
    }
  }

  String get backupAndResetHeader =>
      isDe ? 'DATEN & FORTSCHRITT' : 'DATA & PROGRESS';
  String get exportProgressBackup =>
      isDe ? 'Fortschritt sichern (JSON)' : 'Export Backup (JSON)';
  String get exportProgressTitle =>
      isDe ? 'Fortschritt sichern (JSON)' : 'Export Backup (JSON)';
  String get copyToClipboard =>
      isDe ? 'In Zwischenablage kopieren' : 'Copy to Clipboard';
  String get importProgressBackup =>
      isDe ? 'Backup wiederherstellen' : 'Import Backup (JSON)';
  String get importProgressTitle =>
      isDe ? 'Backup wiederherstellen' : 'Import Backup (JSON)';
  String get importButton => isDe ? 'Wiederherstellen' : 'Restore';
  String get backupExportImport =>
      isDe ? 'Sichern / Wiederherstellen' : 'Backup & Restore';
  String get resetProgressTitle =>
      isDe ? 'Fortschritt zurücksetzen' : 'Reset All Progress';
  String get resetConfirmBody => isDe
      ? 'Möchtest du wirklich deinen gesamten Lernfortschritt, Fehlerhistorie und Prüfungsergebnisse unwiderruflich löschen?'
      : 'Are you sure you want to permanently erase all question progress, mistake history, and mock exam results?';
  String get resetConfirmAction =>
      isDe ? 'Ja, alles löschen' : 'Yes, Reset Everything';
  String get cancelAction => isDe ? 'Abbrechen' : 'Cancel';
  String get saveAction => isDe ? 'Speichern' : 'Save';
  String get progressResetSuccess => isDe
      ? 'Dein Fortschritt wurde erfolgreich zurückgesetzt.'
      : 'All study progress was successfully reset.';
  String get backupExportSuccess => isDe
      ? 'Backup erfolgreich in die Zwischenablage kopiert!'
      : 'Backup copied to clipboard!';
  String get backupImportSuccess => isDe
      ? 'Backup erfolgreich wiederhergestellt!'
      : 'Backup restored successfully!';
  String get backupImportError =>
      isDe ? 'Ungültiges Backup-Format.' : 'Invalid backup JSON file or text.';
  String get weakTopicsHeader =>
      isDe ? 'THEMEN MIT NACHHOLBEDARF' : 'TOPICS NEEDING TRAINING';
  String get noWeakTopicsYet =>
      isDe ? 'Keine Schwachstellen erkannt' : 'No weak topics detected';
  String get mockExamHistoryHeader =>
      isDe ? 'PRÜFUNGSHISTORIE' : 'MOCK EXAM HISTORY';
  String get exposureHeader =>
      isDe ? 'LERNSTATUS DER FRAGEN' : 'QUESTION EXPOSURE';
  String get exposureZero => isDe ? 'Ungesehen' : 'Unseen';
  String get exposureOne => isDe ? 'Im Training' : 'In Training';
  String get exposureTwoPlus => isDe ? 'Gelernt' : 'Learned';
  String get catalogCoverageHeader =>
      isDe ? 'KATALOG-ABDECKUNG' : 'CATALOG COVERAGE';
  String overallAccuracy(int pct, [int? totalAttempts]) =>
      isDe ? 'Gesamtgenauigkeit: $pct%' : 'Overall Accuracy: $pct%';
  String errorRateBadge(int pct) => isDe ? '$pct% Fehler' : '$pct% error rate';
  String get noExamsTakenYet =>
      isDe ? 'Noch keine Prüfungen absolviert' : 'No mock exams taken yet';

  // Settings Screen
  String get settingsLanguageHeader =>
      isDe ? 'LERNERSPRACHE' : 'STUDY LANGUAGE';
  String get settingsPracticeHeader =>
      isDe ? 'ÜBUNGSRUNDE' : 'PRACTICE SESSION';
  String get settingsBatchSizeTitle =>
      isDe ? 'Fragen pro Durchgang' : 'Questions per session';
  String get settingsBatchSizeSubtitle => isDe
      ? 'Standard: 30 (wie in der echten Prüfung)'
      : 'Default: 30 (matches real exam length)';
  String settingsCustomBatchSizeLabel([int? customValue]) => isDe
      ? (customValue != null ? 'Eigene ($customValue)' : 'Eigene...')
      : (customValue != null ? 'Custom ($customValue)' : 'Custom...');
  String get settingsCustomBatchDialogTitle =>
      isDe ? 'Fragen pro Durchgang' : 'Questions per session';
  String get settingsCustomBatchDialogHint =>
      isDe ? 'Anzahl (1–200)' : 'Number of questions (1–200)';
  String get settingsOfflineHeader => isDe ? 'OFFLINE-MODUS' : 'OFFLINE ACCESS';
  String get settingsMakeAvailableOffline =>
      isDe ? 'Offline verfügbar machen' : 'Make available offline';
  String get settingsAvailableOffline =>
      isDe ? 'Offline verfügbar' : 'Available offline';
  String settingsOfflineSubtitle(int cached, int total) => isDe
      ? '$cached von $total Bildern & Videos geladen'
      : '$cached of $total images & videos downloaded';
  String settingsOfflineDownloading(int cached, int total) => isDe
      ? 'Wird heruntergeladen ($cached / $total)...'
      : 'Downloading ($cached / $total)...';
  String settingsOfflineAllDownloaded(int total) => isDe
      ? 'Alle $total Bilder und Videos sind offline gespeichert'
      : 'All $total images and videos are saved offline';
  String get settingsOfflineError => isDe
      ? 'Einige Dateien konnten nicht geladen werden. Tippe zum Wiederholen.'
      : 'Some files could not be downloaded. Tap to retry.';
  String get settingsThemeHeader => isDe ? 'ERSCHEINUNGSBILD' : 'APPEARANCE';
  String get settingsDarkMode => isDe ? 'Dunkelmodus' : 'Dark Mode';
  String get settingsResetHeader => isDe ? 'DATEN' : 'DATA';

  // About Screen
  String get aboutAppHeader =>
      isDe ? 'Über Führerschein Klasse B' : 'About Class B Theory Trainer';
  String get aboutAppBody => isDe
      ? 'Diese App bereitet dich gezielt und ergonomisch auf die offizielle theoretische Führerscheinprüfung der Klasse B bei TÜV und DEKRA in Deutschland vor.\n\n'
            '• Vollständiger amtlicher Fragenkatalog mit allen 1.592 Fragen\n'
            '• Zweisprachig: Vollständig auf Deutsch und Englisch verfügbar\n'
            '• Offizielle Prüfungsregeln: 30 Fragen, 45 Minuten Zeitlimit, max. 10 Fehlerpunkte (oder max. 1 Frage mit 5 Wertungspunkten)\n'
            '• Alle Daten bleiben lokal auf deinem Gerät gespeichert — keine Registrierung notwendig.'
      : 'This application prepares you efficiently and ergonomically for the official German Class B theoretical driving license examination at TÜV and DEKRA.\n\n'
            '• Complete official catalog with all 1,592 questions\n'
            '• Fully bilingual: study seamlessly in English or German\n'
            '• Official exam simulation rules: 30 questions, 45 minutes, max 10 error points (or max 1 five-point question wrong)\n'
            '• Zero registration: your progress is saved 100% locally and privately on your device.';
}
