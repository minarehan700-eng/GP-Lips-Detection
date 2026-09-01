// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Lips Offline';

  @override
  String get brandName => 'Lips';

  @override
  String get splashTagline => 'Detecta el habla silenciosa y las letras A–E';

  @override
  String get onboardLipsingTitle => '¿Qué es el habla silenciosa?';

  @override
  String get onboardLipsingBody =>
      'El habla silenciosa consiste en articular palabras sin voz, algo habitual en la lengua de signos. Esta aplicación observa la forma de tu boca en tiempo real y te avisa cuando la detecta.';

  @override
  String get onboardLipsingPoint1 => 'Tu cara debe verse en la cámara';

  @override
  String get onboardLipsingPoint2 =>
      'El recuadro verde señala la zona de la boca';

  @override
  String get onboardLipsingPoint3 =>
      '«Habla silenciosa: Sí» indica movimiento activo de la boca';

  @override
  String get onboardLettersTitle => 'Letras A – E';

  @override
  String get onboardLettersBody =>
      'MediaPipe sigue los puntos de la boca y asigna cada forma a una letra visema, de la A a la E.';

  @override
  String get onboardLetterA => 'A — boca muy abierta';

  @override
  String get onboardLetterB => 'B — labios cerrados';

  @override
  String get onboardLetterC => 'C — labios redondeados';

  @override
  String get onboardLetterD => 'D — ligeramente abierta';

  @override
  String get onboardLetterE => 'E — forma de sonrisa';

  @override
  String get onboardCameraTitle => 'Uso de la cámara';

  @override
  String get onboardCameraBody =>
      'Sostén el teléfono a la altura de los ojos, mira a la cámara frontal y busca buena iluminación.';

  @override
  String get onboardCameraPoint1 =>
      'Toca una letra para fijarla como objetivo de práctica';

  @override
  String get onboardCameraPoint2 =>
      'Ajusta los umbrales en Ajustes si la detección falla';

  @override
  String get onboardCameraPoint3 =>
      'Funciona sin conexión: no necesita internet';

  @override
  String get skip => 'Omitir';

  @override
  String get next => 'Siguiente';

  @override
  String get getStarted => 'Empezar';

  @override
  String get homeTitle => 'Detección de labios';

  @override
  String get settings => 'Ajustes';

  @override
  String get face => 'Cara';

  @override
  String get detected => 'Detectada';

  @override
  String get notDetected => 'No detectada';

  @override
  String get lipsing => 'Habla silenciosa';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get letterShapeHint =>
      'Sonrisa=E · Redonda=C · Cerrada=B · Muy abierta=A · Poco abierta=D';

  @override
  String get detectedLetter => 'Letra detectada';

  @override
  String confidencePercent(int percent) {
    return '$percent % de confianza';
  }

  @override
  String get matched => '¡Coincide!';

  @override
  String get practiceTarget => 'Objetivo de práctica';

  @override
  String get mouthOpen => 'Apertura de la boca';

  @override
  String get pucker => 'Fruncido';

  @override
  String get smile => 'Sonrisa';

  @override
  String get closeShape => 'Cierre';

  @override
  String get funnel => 'Redondeo';

  @override
  String get stretch => 'Estiramiento';

  @override
  String percentValue(int percent) {
    return '$percent %';
  }

  @override
  String cameraResolution(int width, int height) {
    return 'Cámara: $width×$height';
  }

  @override
  String get detectorThresholds => 'Umbrales de detección';

  @override
  String get mouthOpenThreshold => 'Umbral de apertura';

  @override
  String get mouthOpenThresholdHelp =>
      'Más alto = la boca debe abrirse más para contar';

  @override
  String get motionThreshold => 'Umbral de movimiento';

  @override
  String get motionThresholdHelp =>
      'Más bajo = un movimiento pequeño ya cuenta';

  @override
  String get letterMinScore => 'Puntuación mínima de letra';

  @override
  String get letterMinScoreHelp => 'Más alto = clasificación A–E más estricta';

  @override
  String get saveSettings => 'Guardar ajustes';

  @override
  String get settingsSaved => 'Ajustes guardados';

  @override
  String get resetDefaults => 'Restablecer valores';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'El de mi dispositivo';

  @override
  String get errorNoCamera =>
      'No se ha encontrado ninguna cámara en este dispositivo.';

  @override
  String get errorCameraInit =>
      'No se ha podido iniciar la cámara en ninguna resolución compatible.';

  @override
  String get errorLandmarkerMissing =>
      'No se ha podido cargar el modelo facial. Comprueba que face_landmarker.task esté en android/app/src/main/assets (y en el paquete iOS Runner).';

  @override
  String errorInitFailed(String error) {
    return 'Error de inicio:\n$error\n\nComprueba que el modelo esté incluido y que se haya concedido el permiso de cámara.';
  }

  @override
  String get tryAgain => 'Reintentar';

  @override
  String get a11yOpenSettings => 'Abrir ajustes';

  @override
  String get a11yCameraPreview =>
      'Vista en directo de la cámara. Aquí se sigue tu boca.';

  @override
  String a11yLetterChip(String letter) {
    return 'Letra $letter. Toca dos veces para practicarla.';
  }

  @override
  String a11yLetterChipSelected(String letter) {
    return 'Letra $letter, tu objetivo actual. Toca dos veces para dejar de practicarla.';
  }

  @override
  String a11yAnnounceLetter(String letter, int percent) {
    return 'Letra $letter detectada, $percent por ciento de confianza';
  }

  @override
  String a11yAnnounceMatched(String letter) {
    return 'Letra $letter coincidente';
  }

  @override
  String get a11yAnnounceFaceLost => 'La cara ya no es visible';

  @override
  String get a11yAnnounceFaceFound => 'Cara detectada';

  @override
  String get haptics => 'Vibrar al coincidir';

  @override
  String get hapticsHelp =>
      'Vibra cuando la forma de tu boca coincide con la letra que practicas';

  @override
  String get announceDetections => 'Anunciar las detecciones';

  @override
  String get announceDetectionsHelp =>
      'Envía cada letra detectada a tu lector de pantalla';
}
