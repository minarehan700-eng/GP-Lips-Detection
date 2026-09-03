// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Lips Offline';

  @override
  String get brandName => 'Lips';

  @override
  String get splashTagline =>
      'Détectez l’articulation silencieuse et les lettres A–E';

  @override
  String get onboardLipsingTitle =>
      'Qu’est-ce que l’articulation silencieuse ?';

  @override
  String get onboardLipsingBody =>
      'L’articulation silencieuse consiste à prononcer des mots sans voix, une pratique courante en langue des signes. Cette application observe la forme de votre bouche en temps réel et vous prévient lorsqu’elle la détecte.';

  @override
  String get onboardLipsingPoint1 =>
      'Votre visage doit être visible par la caméra';

  @override
  String get onboardLipsingPoint2 =>
      'Le cadre vert entoure la zone de la bouche';

  @override
  String get onboardLipsingPoint3 =>
      '« Articulation : Oui » signale un mouvement actif de la bouche';

  @override
  String get onboardLettersTitle => 'Lettres A – E';

  @override
  String get onboardLettersBody =>
      'MediaPipe suit les points de la bouche et associe chaque forme à une lettre visème, de A à E.';

  @override
  String get onboardLetterA => 'A — bouche grande ouverte';

  @override
  String get onboardLetterB => 'B — lèvres fermées';

  @override
  String get onboardLetterC => 'C — lèvres arrondies';

  @override
  String get onboardLetterD => 'D — légèrement ouverte';

  @override
  String get onboardLetterE => 'E — forme de sourire';

  @override
  String get onboardCameraTitle => 'Utiliser la caméra';

  @override
  String get onboardCameraBody =>
      'Tenez le téléphone à hauteur des yeux, face à la caméra avant, avec un bon éclairage.';

  @override
  String get onboardCameraPoint1 =>
      'Touchez une lettre pour la définir comme objectif';

  @override
  String get onboardCameraPoint2 =>
      'Ajustez les seuils dans les Réglages si la détection dérape';

  @override
  String get onboardCameraPoint3 =>
      'Fonctionne hors ligne : aucune connexion requise';

  @override
  String get skip => 'Passer';

  @override
  String get next => 'Suivant';

  @override
  String get getStarted => 'Commencer';

  @override
  String get homeTitle => 'Détection des lèvres';

  @override
  String get settings => 'Réglages';

  @override
  String get face => 'Visage';

  @override
  String get detected => 'Détecté';

  @override
  String get notDetected => 'Non détecté';

  @override
  String get lipsing => 'Articulation';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get letterShapeHint =>
      'Sourire=E · Arrondi=C · Fermé=B · Grand ouvert=A · Entrouvert=D';

  @override
  String get detectedLetter => 'Lettre détectée';

  @override
  String confidencePercent(int percent) {
    return '$percent % de confiance';
  }

  @override
  String get matched => 'Réussi !';

  @override
  String get practiceTarget => 'Lettre à travailler';

  @override
  String get mouthOpen => 'Ouverture de la bouche';

  @override
  String get pucker => 'Moue';

  @override
  String get smile => 'Sourire';

  @override
  String get closeShape => 'Fermeture';

  @override
  String get funnel => 'Arrondi';

  @override
  String get stretch => 'Étirement';

  @override
  String percentValue(int percent) {
    return '$percent %';
  }

  @override
  String cameraResolution(int width, int height) {
    return 'Caméra : $width×$height';
  }

  @override
  String get detectorThresholds => 'Seuils de détection';

  @override
  String get mouthOpenThreshold => 'Seuil d’ouverture';

  @override
  String get mouthOpenThresholdHelp =>
      'Plus haut = la bouche doit s’ouvrir davantage';

  @override
  String get motionThreshold => 'Seuil de mouvement';

  @override
  String get motionThresholdHelp => 'Plus bas = un petit mouvement suffit';

  @override
  String get letterMinScore => 'Score minimal de lettre';

  @override
  String get letterMinScoreHelp =>
      'Plus haut = classification A–E plus stricte';

  @override
  String get saveSettings => 'Enregistrer';

  @override
  String get settingsSaved => 'Réglages enregistrés';

  @override
  String get resetDefaults => 'Valeurs par défaut';

  @override
  String get language => 'Langue';

  @override
  String get languageSystem => 'Celle de mon appareil';

  @override
  String get errorNoCamera => 'Aucune caméra détectée sur cet appareil.';

  @override
  String get errorCameraInit =>
      'Impossible d’initialiser la caméra dans une résolution compatible.';

  @override
  String get errorLandmarkerMissing =>
      'Le modèle de repères du visage n’a pas pu être chargé. Vérifiez que face_landmarker.task se trouve dans android/app/src/main/assets (et dans le bundle iOS Runner).';

  @override
  String errorInitFailed(String error) {
    return 'Échec du démarrage :\n$error\n\nVérifiez que le modèle est inclus et que l’autorisation caméra est accordée.';
  }

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get a11yOpenSettings => 'Ouvrir les réglages';

  @override
  String get a11yCameraPreview =>
      'Aperçu en direct de la caméra. Votre bouche est suivie ici.';

  @override
  String a11yLetterChip(String letter) {
    return 'Lettre $letter. Touchez deux fois pour la travailler.';
  }

  @override
  String a11yLetterChipSelected(String letter) {
    return 'Lettre $letter, votre objectif actuel. Touchez deux fois pour arrêter.';
  }

  @override
  String a11yAnnounceLetter(String letter, int percent) {
    return 'Lettre $letter détectée, $percent pour cent de confiance';
  }

  @override
  String a11yAnnounceMatched(String letter) {
    return 'Lettre $letter réussie';
  }

  @override
  String get a11yAnnounceFaceLost => 'Le visage n’est plus visible';

  @override
  String get a11yAnnounceFaceFound => 'Visage détecté';

  @override
  String get haptics => 'Vibrer en cas de réussite';

  @override
  String get hapticsHelp =>
      'Vibre lorsque la forme de votre bouche correspond à la lettre travaillée';

  @override
  String get announceDetections => 'Annoncer les détections';

  @override
  String get announceDetectionsHelp =>
      'Transmet chaque lettre détectée à votre lecteur d’écran';

  @override
  String get practice => 'S’entraîner';

  @override
  String get practiceStart => 'Commencer une série';

  @override
  String get practiceMakeShape => 'Formez cette bouche';

  @override
  String get practiceHold => 'Tenez…';

  @override
  String get practiceGotIt => 'C’est ça !';

  @override
  String get practiceMissed => 'Manquée, on continue';

  @override
  String practiceProgress(int done, int total) {
    return '$done sur $total';
  }

  @override
  String practiceScore(int hits, int total) {
    return '$hits sur $total réussies';
  }

  @override
  String practiceBestStreak(int streak) {
    return 'Meilleure série : $streak';
  }

  @override
  String get practiceAgain => 'Recommencer';

  @override
  String get practiceDone => 'Série terminée';

  @override
  String practiceNearMiss(String letter) {
    return 'Vous étiez proche du $letter';
  }

  @override
  String get progress => 'Progression';

  @override
  String get progressNone =>
      'Aucune série pour l’instant. Terminez-en une et vos résultats s’afficheront ici.';

  @override
  String get progressPerLetter => 'Résultats par lettre';

  @override
  String progressAttempts(int hits, int attempts) {
    return '$hits/$attempts';
  }

  @override
  String get progressUntried => 'pas encore essayée';

  @override
  String progressWeakest(String letter) {
    return 'À travailler : $letter';
  }

  @override
  String progressRounds(int count) {
    return '$count séries enregistrées';
  }

  @override
  String get progressClear => 'Effacer l’historique';

  @override
  String get progressCleared => 'Historique effacé';

  @override
  String a11yPracticeTarget(String letter) {
    return 'Formez la lettre $letter';
  }

  @override
  String a11yPracticeHeld(String letter) {
    return 'Lettre $letter réussie';
  }

  @override
  String a11yPracticeMissed(String letter) {
    return 'Lettre $letter manquée';
  }

  @override
  String get chart => 'Guide des formes';

  @override
  String get chartIntro =>
      'Cinq formes couvrent tout l’alphabet. Une forme n’est pas une lettre : ce sont toutes les lettres qui se ressemblent sur les lèvres.';

  @override
  String get chartWhySame => 'Pourquoi P, B et M partagent une forme';

  @override
  String get chartWhySameBody =>
      'Elles se forment à des endroits différents dans la bouche, mais les lèvres font exactement la même chose. Aucune caméra ne peut les distinguer. La lecture labiale s’appuie sur le contexte, et c’est pourquoi les mots se lisent mieux que les lettres.';

  @override
  String get chartLetters => 'Lettres';

  @override
  String get chartTry => 'Essayez de dire';

  @override
  String get words => 'Mots';

  @override
  String get wordsIntro =>
      'Une forme seule est ambiguë. Une suite de formes l’est bien moins : c’est ainsi que fonctionne la lecture labiale.';

  @override
  String get wordsGreetings => 'Salutations';

  @override
  String get wordsNumbers => 'Nombres';

  @override
  String get wordsEmergency => 'Urgence';

  @override
  String get wordsEveryday => 'Quotidien';

  @override
  String wordShapes(int count) {
    return '$count formes';
  }

  @override
  String get wordSayIt => 'Articulez ce mot';

  @override
  String wordNextShape(String shape) {
    return 'Forme suivante : $shape';
  }

  @override
  String get wordComplete => 'Mot terminé';

  @override
  String get wordExpired => 'Temps écoulé, réessayez';

  @override
  String get wordEnglishOnly =>
      'La bibliothèque de mots est en anglais. D’autres alphabets exigent leurs propres règles de formes.';

  @override
  String get about => 'À propos';

  @override
  String get aboutWhat => 'Ce que cette application peut et ne peut pas faire';

  @override
  String get aboutCan =>
      'Elle lit cinq formes de bouche en temps réel, entièrement sur le téléphone, sans aucune connexion internet.';

  @override
  String get aboutCannot =>
      'Ce n’est pas de la reconnaissance vocale. Elle rapporte des formes, pas des mots, et ne distingue pas des lettres que les lèvres forment de façon identique.';

  @override
  String get aboutPrivacy => 'Confidentialité';

  @override
  String get aboutPrivacyBody =>
      'Aucune image ne quitte le téléphone. L’application ne contient aucun code réseau et demande une seule autorisation : la caméra.';

  @override
  String a11yWordShape(int position, int total, String shape) {
    return 'Forme $position sur $total : $shape';
  }

  @override
  String get calibrate => 'Étalonner';

  @override
  String get calibrateIntro =>
      'Les seuils livrés ont été mesurés sur quelques visages. Pas le vôtre. Quatre pauses courtes et l’application mesure votre visage au lieu de le deviner.';

  @override
  String get calibrateRest => 'Détendez le visage. Ne bougez plus.';

  @override
  String get calibrateWideOpen => 'Ouvrez grand la bouche.';

  @override
  String get calibrateRounded => 'Arrondissez les lèvres, comme « ou ».';

  @override
  String get calibrateSpread => 'Étirez les lèvres, comme « i ».';

  @override
  String get calibrateStart => 'Lancer l’étalonnage';

  @override
  String get calibrateSaved => 'Étalonné sur votre visage';

  @override
  String calibrateStepOf(int done, int total) {
    return 'Étape $done sur $total';
  }

  @override
  String get calibrateFailFew =>
      'Votre visage n’est pas resté visible assez longtemps. Réessayez avec un meilleur éclairage.';

  @override
  String get calibrateFailRange =>
      'Votre bouche au repos et ouverte ont donné la même mesure. Ouvrez davantage à la deuxième étape.';

  @override
  String get calibrateFailRestless =>
      'La caméra ou votre visage ont trop bougé. Posez le téléphone sur un support.';

  @override
  String get confusion => 'Ce que vous confondez';

  @override
  String confusionPair(String made, String meant) {
    return 'Vous faites $made au lieu de $meant';
  }

  @override
  String get confusionNone =>
      'Pas encore de tendance nette. Faites quelques séries de plus.';

  @override
  String get security => 'Verrou';

  @override
  String get securityIntro =>
      'L’historique montre votre maîtrise des formes de parole. Sur un téléphone partagé, cela mérite un code.';

  @override
  String get securityEnable => 'Exiger un code';

  @override
  String get securitySetPin => 'Choisissez un code';

  @override
  String get securityEnterPin => 'Saisissez votre code';

  @override
  String get securityWrong => 'Code incorrect';

  @override
  String get securityLockedOut => 'Trop d’essais. Patientez un instant.';

  @override
  String get securityUnlock => 'Déverrouiller';

  @override
  String get securityRemove => 'Supprimer le code';

  @override
  String securityPinTooShort(int count) {
    return 'Le code doit compter au moins $count chiffres';
  }

  @override
  String get securityScope =>
      'Ceci verrouille l’application sur ce téléphone. Ce n’est pas une connexion : ni compte ni serveur, l’application n’ayant aucun code réseau.';
}
