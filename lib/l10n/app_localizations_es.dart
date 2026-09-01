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

  @override
  String get practice => 'Practicar';

  @override
  String get practiceStart => 'Empezar una ronda';

  @override
  String get practiceMakeShape => 'Haz esta forma';

  @override
  String get practiceHold => 'Mantén…';

  @override
  String get practiceGotIt => '¡Bien!';

  @override
  String get practiceMissed => 'Fallada, seguimos';

  @override
  String practiceProgress(int done, int total) {
    return '$done de $total';
  }

  @override
  String practiceScore(int hits, int total) {
    return '$hits de $total logradas';
  }

  @override
  String practiceBestStreak(int streak) {
    return 'Mejor racha: $streak';
  }

  @override
  String get practiceAgain => 'Practicar otra vez';

  @override
  String get practiceDone => 'Ronda terminada';

  @override
  String practiceNearMiss(String letter) {
    return 'Estuviste cerca con $letter';
  }

  @override
  String get progress => 'Progreso';

  @override
  String get progressNone =>
      'Aún no hay rondas. Completa una y verás aquí tus resultados.';

  @override
  String get progressPerLetter => 'Cómo va cada letra';

  @override
  String progressAttempts(int hits, int attempts) {
    return '$hits/$attempts';
  }

  @override
  String get progressUntried => 'sin practicar';

  @override
  String progressWeakest(String letter) {
    return 'Conviene practicar: $letter';
  }

  @override
  String progressRounds(int count) {
    return '$count rondas guardadas';
  }

  @override
  String get progressClear => 'Borrar historial';

  @override
  String get progressCleared => 'Historial borrado';

  @override
  String a11yPracticeTarget(String letter) {
    return 'Haz la forma de la letra $letter';
  }

  @override
  String a11yPracticeHeld(String letter) {
    return 'Letra $letter lograda';
  }

  @override
  String a11yPracticeMissed(String letter) {
    return 'Letra $letter fallada';
  }

  @override
  String get chart => 'Guía de formas';

  @override
  String get chartIntro =>
      'Cinco formas cubren todo el alfabeto. Una forma no es una letra: son todas las letras que se ven igual en los labios.';

  @override
  String get chartWhySame => 'Por qué P, B y M comparten forma';

  @override
  String get chartWhySameBody =>
      'Se articulan en puntos distintos de la boca, pero los labios hacen exactamente lo mismo. Ninguna cámara puede separarlas. La lectura labial usa el contexto para elegir, y por eso las palabras se leen mejor que las letras.';

  @override
  String get chartLetters => 'Letras';

  @override
  String get chartTry => 'Prueba a decir';

  @override
  String get words => 'Palabras';

  @override
  String get wordsIntro =>
      'Una forma aislada es ambigua. Una secuencia de formas lo es mucho menos: así funciona realmente la lectura labial.';

  @override
  String get wordsGreetings => 'Saludos';

  @override
  String get wordsNumbers => 'Números';

  @override
  String get wordsEmergency => 'Emergencias';

  @override
  String get wordsEveryday => 'Cotidianas';

  @override
  String wordShapes(int count) {
    return '$count formas';
  }

  @override
  String get wordSayIt => 'Vocaliza esta palabra';

  @override
  String wordNextShape(String shape) {
    return 'Siguiente forma: $shape';
  }

  @override
  String get wordComplete => 'Palabra completa';

  @override
  String get wordExpired => 'Tiempo agotado, inténtalo otra vez';

  @override
  String get wordEnglishOnly =>
      'La biblioteca de palabras está en inglés. Otros alfabetos necesitan sus propias reglas de formas.';

  @override
  String get about => 'Acerca de';

  @override
  String get aboutWhat => 'Qué puede y qué no puede hacer esta app';

  @override
  String get aboutCan =>
      'Lee cinco formas de la boca en tiempo real, todo en el teléfono y sin conexión a internet.';

  @override
  String get aboutCannot =>
      'No es reconocimiento de voz. Informa de formas, no de palabras, y no distingue letras que los labios hacen igual.';

  @override
  String get aboutPrivacy => 'Privacidad';

  @override
  String get aboutPrivacyBody =>
      'Ningún fotograma sale del teléfono. La app no contiene código de red alguno y pide un solo permiso: la cámara.';

  @override
  String a11yWordShape(int position, int total, String shape) {
    return 'Forma $position de $total: $shape';
  }
}
