import 'dart:math' as math; // min, max

import 'package:camera/camera.dart'; // CameraPreview
import 'package:flutter/material.dart'; // Flutter UI
import 'package:flutter_animate/flutter_animate.dart'; // fade animation

import '../core/app_theme.dart'; // ألوان
import '../domain/face_lips_result.dart'; // نتيجة الكشف
import 'glass_card.dart'; // بطاقة زجاجية

class MouthBoxPainter extends CustomPainter { // يرسم مربع حول الفم على المعاينة
  MouthBoxPainter({ // مُنشئ
    required this.minX, //
    required this.minY, //
    required this.maxX, //
    required this.maxY, //
    required this.imageWidth, //
    required this.imageHeight, //
    required this.isFrontCamera, //
    required this.active, // أخضر عند lipsing
  }); //

  final double minX; // حدود نسبية 0-1
  final double minY; //
  final double maxX; //
  final double maxY; //
  final int imageWidth; //
  final int imageHeight; //
  final bool isFrontCamera; //
  final bool active; //

  @override // paint
  void paint(Canvas canvas, Size size) { // رسم على Canvas
    final imageIsLandscape = // هل الإطار أفقي؟
        imageWidth > 0 && imageHeight > 0 && imageWidth > imageHeight; //
    final widgetIsPortrait = size.height > size.width; // هل الودجت عمودي؟
    final swapAxes = imageIsLandscape && widgetIsPortrait; // تبديل محاور؟

    Offset mapPoint(double nx, double ny) { // تحويل نقطة نسبية إلى بكسل الشاشة
      var x = nx; //
      var y = ny; //
      if (swapAxes) { // تبديل إذا لزم
        final sx = x; //
        x = y; //
        y = 1.0 - sx; //
      } //
      if (isFrontCamera) { // مرآة للكاميرا الأمامية
        x = 1.0 - x; //
      } //
      return Offset(x * size.width, y * size.height); //
    } //

    final p1 = mapPoint(minX, minY); // زاوية 1
    final p2 = mapPoint(maxX, maxY); // زاوية 2
    var left = math.min(p1.dx, p2.dx); //
    var top = math.min(p1.dy, p2.dy); //
    var right = math.max(p1.dx, p2.dx); //
    var bottom = math.max(p1.dy, p2.dy); //

    var w = right - left; // العرض
    var h = bottom - top; // الارتفاع

    if (h > w) { // إذا المربع طويل — اجعله أفقي أكثر
      final cx = (left + right) / 2; //
      final cy = (top + bottom) / 2; //
      final tmp = w; //
      w = h; //
      h = tmp; //
      left = cx - w / 2; //
      right = cx + w / 2; //
      top = cy - h / 2; //
      bottom = cy + h / 2; //
    } //

    final minH = w * 0.22; // حد أدنى للارتفاع
    final maxH = w * 0.48; // حد أقصى
    if (h < minH || h > maxH) { // تقييد الارتفاع
      final cy = (top + bottom) / 2; //
      h = h.clamp(minH, maxH); //
      top = cy - h / 2; //
      bottom = cy + h / 2; //
    } //

    final rect = Rect.fromLTRB(left, top, right, bottom); // مستطيل الفم
    final paint = Paint() // فرشاة الحدود
      ..style = PaintingStyle.stroke //
      ..strokeWidth = 2.5 //
      ..color = active ? const Color(0xFF4ADE80) : AppTheme.brandTeal; //
    canvas.drawRRect( // رسم مستطيل دائري الزوايا
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(8)), //
      paint, //
    ); //
  } // نهاية paint

  @override // shouldRepaint
  bool shouldRepaint(covariant MouthBoxPainter oldDelegate) { // هل نعيد الرسم؟
    return oldDelegate.minX != minX || //
        oldDelegate.minY != minY || //
        oldDelegate.maxX != maxX || //
        oldDelegate.maxY != maxY || //
        oldDelegate.imageWidth != imageWidth || //
        oldDelegate.imageHeight != imageHeight || //
        oldDelegate.isFrontCamera != isFrontCamera || //
        oldDelegate.active != active; //
  } // نهاية shouldRepaint
} // نهاية MouthBoxPainter

class LipsCameraPreview extends StatelessWidget { // معاينة الكاميرا + مربع الفم
  const LipsCameraPreview({ // مُنشئ
    super.key, //
    required this.controller, //
    required this.result, //
    required this.frameImageWidth, //
    required this.frameImageHeight, //
    required this.isFrontCamera, //
    required this.lipsing, //
  }); //

  final CameraController controller; //
  final FaceLipsResult result; //
  final int frameImageWidth; //
  final int frameImageHeight; //
  final bool isFrontCamera; //
  final bool lipsing; //

  @override // build
  Widget build(BuildContext context) { //
    final previewSize = controller.value.previewSize; // حجم المعاينة
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait; //

    final double displayAspect; // نسبة العرض/الارتفاع للعرض
    if (previewSize != null) { //
      displayAspect = isPortrait //
          ? previewSize.height / previewSize.width //
          : previewSize.width / previewSize.height; //
    } else { //
      final controllerAspect = controller.value.aspectRatio; //
      displayAspect = isPortrait //
          ? (controllerAspect > 0 ? 1 / controllerAspect : 9 / 16) //
          : (controllerAspect > 0 ? controllerAspect : 16 / 9); //
    } //

    final screenSize = MediaQuery.sizeOf(context); //
    final maxHeight = screenSize.height * 0.33; // أقصى ارتفاع 33% من الشاشة
    final maxWidth = screenSize.width - 28; //
    var previewWidth = maxWidth; //
    var previewHeight = previewWidth / displayAspect; //
    if (previewHeight > maxHeight) { // تقييد الارتفاع
      previewHeight = maxHeight; //
      previewWidth = previewHeight * displayAspect; //
    } //

    return GlassCard( //
      borderRadius: 22, //
      padding: const EdgeInsets.all(8), //
      child: Center( //
        child: SizedBox( //
          width: previewWidth, //
          height: previewHeight, //
          child: ClipRRect( //
            borderRadius: BorderRadius.circular(16), //
            child: Stack( // كاميرا + رسم فوقها
              fit: StackFit.expand, //
              children: [ //
                CameraPreview(controller), // فيديو الكاميرا
                if (result.hasMouthBox) // إذا لدينا مربع فم
                  CustomPaint( //
                    painter: MouthBoxPainter( //
                      minX: result.mouthMinX, //
                      minY: result.mouthMinY, //
                      maxX: result.mouthMaxX, //
                      maxY: result.mouthMaxY, //
                      imageWidth: frameImageWidth > 0 //
                          ? frameImageWidth //
                          : (previewSize?.width.toInt() ?? 0), //
                      imageHeight: frameImageHeight > 0 //
                          ? frameImageHeight //
                          : (previewSize?.height.toInt() ?? 0), //
                      isFrontCamera: isFrontCamera, //
                      active: lipsing, //
                    ), //
                  ), //
              ], //
            ), //
          ), //
        ), //
      ), //
    ).animate().fadeIn(duration: 280.ms).scale(begin: const Offset(0.98, 0.98)); //
  } // نهاية build
} // نهاية LipsCameraPreview
