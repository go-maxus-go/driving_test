enum AppLanguage {
  en('en', 'EN', 'English', 'assets/driving_theory_questions_b.json'),
  de('de', 'DE', 'Deutsch', 'assets/driving_theory_questions_de_b.json');

  const AppLanguage(
    this.code,
    this.shortLabel,
    this.displayName,
    this.assetPath,
  );

  final String code;
  final String shortLabel;
  final String displayName;
  final String assetPath;

  AppLanguage get opposite =>
      this == AppLanguage.en ? AppLanguage.de : AppLanguage.en;

  static AppLanguage fromCode(String? code) {
    if (code == 'de') return AppLanguage.de;
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

  // Home Cockpit
  String get examReadiness => isDe ? 'PRÜFUNGSREIFE' : 'EXAM READINESS';
  String readinessStatus(int percent) {
    if (percent >= 85) {
      return isDe ? 'Bereit für den TÜV!' : 'Exam Ready!';
    }
    if (percent >= 60) {
      return isDe ? 'Auf gutem Weg' : 'Making Great Progress';
    }
    if (percent > 0) {
      return isDe ? 'Aufbauphase' : 'Building Foundations';
    }
    return isDe ? 'Bereit zum Start' : 'Ready to Start';
  }

  String get masteredLabel => isDe ? 'Gemeistert' : 'Mastered';
  String get mistakesLabel => isDe ? 'Fehlerfragen' : 'Mistakes';
  String get unseenLabel => isDe ? 'Offen' : 'Unseen';
  String get leftLabel => isDe ? 'übrig' : 'left';
  String ofTotalQuestions(int total) =>
      isDe ? 'von $total Fragen gesamt' : 'of $total total questions';

  String get smartPracticeTitle => isDe ? 'Smart-Training' : 'Smart Practice';
  String get smartPracticeSubtitle => isDe
      ? 'Optimaler Mix aus Fehlerfragen, neuen Fragen & Wiederholung'
      : 'Adaptive mix of mistakes, unseen items & spaced review';
  String get startLabel => isDe ? 'Starten' : 'Start';
  String get beginLabel => isDe ? 'Beginnen' : 'Begin';
  String get resumeExamBannerTitle => isDe
      ? 'Laufende Prüfungssimulation fortsetzen'
      : 'Resume Active Mock Exam';
  String get resumeAction => isDe ? 'Weiter' : 'Resume';

  String get targetedDrillsHeader =>
      isDe ? 'GEZIELTES TRAINING (1 KLICK)' : 'TARGETED DRILLS (1 TAP)';
  String get drillMostMistakes => isDe ? 'Häufige Fehler' : 'Most Mistakes';
  String get drillMostMistakesSub =>
      isDe ? 'Fragen mit hoher Fehlerquote' : 'Questions with most mistakes';
  String get drillLeastAnswered => isDe ? 'Wenig geübt' : 'Least Answered';
  String get drillLeastAnsweredSub => isDe
      ? 'Ungesehene & selten geübte Fragen'
      : 'Unseen & least practiced items';
  String get drillFivePoint => isDe ? '5-Punkte-Fallen' : '5-Point Traps';
  String get drillFivePointSub => isDe
      ? '2 Fehler = sofort durchgefallen'
      : '2 wrong = automatic exam fail';
  String get drillVideos => isDe ? 'Videofragen' : 'Video Scenes';
  String get drillVideosSub =>
      isDe ? 'Dynamische Gefahrensituationen' : 'Cockpit hazard animations';
  String get drillNumeric => isDe ? 'Zahlenfragen' : 'Number Input';
  String get drillNumericSub =>
      isDe ? 'Formeln & Distanzen' : 'Formulas & distances';
  String get drillSaved => isDe ? 'Gemerkt' : 'Saved';
  String get drillSavedSub =>
      isDe ? 'Persönliche Merkliste' : 'Your saved questions';
  String get noQuestionsInDrill => isDe
      ? 'Keine Fragen in dieser Auswahl vorhanden!'
      : 'No questions currently in this filter!';

  String get examSimulationTitle => isDe
      ? 'Prüfungssimulation (30 Fragen • 45 Min.)'
      : 'Exam Simulation (30 Qs • 45 min)';
  String examSimulationSubtitle([String? lastSummary]) {
    final base = isDe
        ? 'Offizielle TÜV/DEKRA-Regeln • Max. 10 Fehlerpunkte'
        : 'Official TÜV/DEKRA rules • Max 10 error points';
    if (lastSummary == null || lastSummary.isEmpty) return base;
    return '$base • $lastSummary';
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
  String get badgeWrong => isDe ? 'Falsch gewählt' : 'Wrong choice';
  String get badgeMissed => isDe ? 'Fehlt!' : 'Missed!';
  String get feedbackPerfect =>
      isDe ? 'Richtig beantwortet!' : 'Correctly answered!';
  String feedbackIncorrect(int pts) => isDe
      ? 'Nicht ganz richtig — +$pts Fehlerpunkte'
      : 'Not quite right — +$pts Error Points';
  String get explanationTitle => isDe ? 'Erklärung' : 'Explanation';
  String get showExplanation =>
      isDe ? 'Erklärung anzeigen' : 'Why is this right?';
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
  String get freezeFrameBadge =>
      isDe ? 'Standbild (Video beendet)' : 'Freeze-Frame (Video locked)';
  String get examStyleVideoToggle =>
      isDe ? 'TÜV-Videomodus' : 'Exam Video Mode';
  String get fullScreenVideo => isDe ? 'Vollbild' : 'Full screen';

  // Session Complete
  String get sessionCompleteTitle =>
      isDe ? 'Durchgang abgeschlossen!' : 'Session Complete!';
  String get continueMoreQuestions =>
      isDe ? 'Weitere 25 Fragen üben' : 'Practice 25 More';
  String get retrySessionMistakes =>
      isDe ? 'Fehler aus dieser Runde üben' : 'Retry Session Mistakes';
  String get backToCockpit => isDe ? 'Zurück zur Übersicht' : 'Back to Cockpit';

  // Topics Screen
  String get topicsTitle => isDe ? 'Themen & Katalog' : 'Topics & Catalog';
  String get searchQuestionsHint => isDe
      ? 'Thema, Stichwort oder Fragen-Nr. suchen...'
      : 'Search topic, keyword, or question ID...';
  String get filterAllClassB => isDe ? 'Alle Klasse B' : 'All Class B';
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
  String get twoFivePointFailWarning => isDe
      ? 'Nicht bestanden wegen der Zwei-5-Punkte-Regel: Zwei falsch beantwortete 5-Punkte-Fragen führen trotz 10 Punkten automatisch zum Nichtbestehen.'
      : 'Failed due to the Two-5-Point Rule: Answering two 5-point questions wrong triggers automatic failure under German TÜV/DEKRA rules.';
  String get fivePointRuleOk => isDe
      ? '5-Punkte-Regel erfüllt (max. 1 Fehler erlaubt)'
      : '5-Point Rule satisfied (at most 1 allowed)';
  String practiceExamMistakes(int count) => isDe
      ? 'Diese $count Fehler jetzt gezielt üben'
      : 'Practice These $count Mistakes Now';
  String get reviewWrongOnly => isDe ? 'Nur Fehler' : 'Wrong Only';
  String get reviewAll30 => isDe ? 'Alle 30 Fragen' : 'All 30 Questions';
  String get newExamButton => isDe ? 'Neue Prüfung' : 'New Exam';

  // Progress Screen
  String get catalogCoverageHeader => isDe
      ? 'KATALOG-ABDECKUNG (1.592 FRAGEN)'
      : 'CATALOG COVERAGE (1,592 QUESTIONS)';
  String overallAccuracy(int pct, int totalAnswers) => isDe
      ? 'Trefferquote: $pct% • Gegebene Antworten: $totalAnswers'
      : 'Overall Accuracy: $pct% • Total Answers: $totalAnswers';
  String get weakTopicsHeader =>
      isDe ? 'THEMEN MIT TRAININGSBEDARF' : 'TOPICS NEEDING TRAINING';
  String get noWeakTopicsYet => isDe
      ? 'Beantworte ein paar Fragen, um deine Stärken und Schwächen pro Thema zu sehen.'
      : 'Answer a few questions to see personalized weak-topic recommendations.';
  String errorRateBadge(int pct) =>
      isDe ? '$pct% Fehlerquote' : '$pct% error rate';

  String get questionsStatusLearned => isDe ? 'Gelernt' : 'Learned';
  String get questionsStatusLearnedSub => isDe
      ? '2× hintereinander richtig beantwortet'
      : 'Answered correctly 2 times in a row';
  String get questionsStatusInTraining => isDe ? 'Im Training' : 'In Training';
  String get questionsStatusInTrainingSub => isDe
      ? 'Geübt, aber noch nicht sicher'
      : 'Practiced, but not yet mastered';
  String get questionsStatusUnseen => isDe ? 'Ungesehen' : 'Unseen';
  String get questionsStatusUnseenSub =>
      isDe ? 'Noch nie beantwortet' : 'Never answered yet';

  String get mockExamHistoryHeader => isDe
      ? 'PRÜFUNGSHISTORIE (BESTEHENSGRENZE: ≤ 10 PKT.)'
      : 'MOCK EXAM HISTORY (PASS: ≤ 10 PTS)';
  String get mockExamHistoryButton =>
      isDe ? 'Prüfungshistorie' : 'Mock Exam History';
  String get mockExamHistorySubtitle => isDe
      ? 'Frühere Prüfungssimulationen und Fehler einsehen'
      : 'View past exam results and mistakes';
  String get noExamsTakenYet => isDe
      ? 'Noch keine Prüfungssimulation absolviert.'
      : 'No mock exams completed yet.';

  String get exposureHeader =>
      isDe ? 'WIE OFT WURDEN FRAGEN GEÜBT?' : 'QUESTION EXPOSURE DISTRIBUTION';
  String get exposureZero =>
      isDe ? 'Noch nie beantwortet (0×)' : 'Never answered (0×)';
  String get exposureOne =>
      isDe ? 'Einmal beantwortet (1×)' : 'Answered once (1×)';
  String get exposureTwoPlus =>
      isDe ? 'Mehrfach geübt (2+×)' : 'Practiced 2+ times (2+×)';

  String get backupExportImport => isDe ? 'Backup / Reset' : 'Backup / Reset';
  String get exportProgressTitle =>
      isDe ? 'Fortschritt sichern (JSON)' : 'Backup Progress (JSON)';
  String get importProgressTitle =>
      isDe ? 'Fortschritt wiederherstellen' : 'Import Backup JSON';
  String get resetProgressTitle =>
      isDe ? 'Gesamten Fortschritt zurücksetzen' : 'Reset All Progress';
  String get resetConfirmBody => isDe
      ? 'Möchtest du wirklich alle Antworten, Fehlerlisten und Prüfungsergebnisse unwiderruflich löschen?'
      : 'Are you sure you want to permanently clear all answered history, mistakes, and mock exam results?';
  String get resetConfirmAction => isDe ? 'Zurücksetzen' : 'Reset Everything';
  String get copyToClipboard => isDe ? 'JSON kopieren' : 'Copy JSON';
  String get importButton => isDe ? 'Importieren' : 'Import';

  // Settings Screen
  String get settingsLanguageHeader => isDe ? 'SPRACHE' : 'LANGUAGE';
  String get settingsThemeHeader => isDe ? 'DESIGN' : 'THEME';
  String get settingsDarkMode => isDe ? 'Dunkelmodus' : 'Dark Mode';
  String get settingsResetHeader => isDe ? 'FORTSCHRITT' : 'PROGRESS';
  String get cancelAction => isDe ? 'Abbrechen' : 'Cancel';
  String get progressResetSuccess => isDe
      ? 'Fortschritt erfolgreich zurückgesetzt.'
      : 'Progress reset successfully.';

  // About Screen
  String get aboutAppHeader =>
      isDe ? 'Über Führerschein Klasse B' : 'About Class B Theory Trainer';
  String get aboutAppBody => isDe
      ? 'Diese App hilft dir bei der gezielten Vorbereitung auf die theoretische Führerscheinprüfung der Klasse B in Deutschland (TÜV / DEKRA).\n\n• Offizieller Fragenkatalog mit 1.592 Fragen (Grundstoff + Zusatzstoff B)\n• Dynamische Video- und Bildfragen sowie Zahlenfragen\n• Reale Prüfungssimulation mit 30 Fragen und 45 Minuten Zeitlimit\n• 100% lokal: Kein Account, kein Login, deine Daten bleiben auf deinem Gerät.'
      : 'This app is designed to help you prepare effectively for the German Class B driving theory exam (TÜV / DEKRA).\n\n• Official catalog of 1,592 questions (Basic Material + Class B Add-on)\n• Dynamic video hazards, static scenes, and numeric formulas\n• Official 30-question mock exam simulation with 45-minute countdown\n• 100% local: No account or registration required, all progress stays on your device.';
}
