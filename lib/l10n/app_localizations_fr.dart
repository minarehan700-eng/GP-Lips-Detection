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
}
