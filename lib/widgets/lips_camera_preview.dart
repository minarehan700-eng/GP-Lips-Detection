import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../domain/face_lips_result.dart';
import 'glass_card.dart';

/// Draws the mouth bounding box on top of the camera preview.
class MouthBoxPainter extends CustomPainter {
  MouthBoxPainter({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
    required this.imageWidth,
    required this.imageHeight,
    required this.isFrontCamera,
    required this.active,
  });

  final double minX;
  final double minY;
  final double maxX;
  final double maxY;
  final int imageWidth;
  final int imageHeight;
  final bool isFrontCamera;
  final bool active;

  /// Maps normalized landmark coords to screen pixels, handling rotation and front-camera mirroring.
  @override
  void paint(Canvas canvas, Size size) {
    final imageIsLandscape =
        imageWidth > 0 && imageHeight > 0 && imageWidth > imageHeight;
    final widgetIsPortrait = size.height > size.width;
    final swapAxes = imageIsLandscape && widgetIsPortrait;

    Offset mapPoint(double nx, double ny) {
      var x = nx;
      var y = ny;
      if (swapAxes) {
        final sx = x;
        x = y;
        y = 1.0 - sx;
      }
      if (isFrontCamera) {
        x = 1.0 - x;
      }
      return Offset(x * size.width, y * size.height);
    }

    final p1 = mapPoint(minX, minY);
    final p2 = mapPoint(maxX, maxY);
    var left = math.min(p1.dx, p2.dx);
    var top = math.min(p1.dy, p2.dy);
    var right = math.max(p1.dx, p2.dx);
    var bottom = math.max(p1.dy, p2.dy);

    var w = right - left;
    var h = bottom - top;

    if (h > w) {
      final cx = (left + right) / 2;
      final cy = (top + bottom) / 2;
      final tmp = w;
      w = h;
      h = tmp;
      left = cx - w / 2;
      right = cx + w / 2;
      top = cy - h / 2;
      bottom = cy + h / 2;
    }

    final minH = w * 0.22;
    final maxH = w * 0.48;
    if (h < minH || h > maxH) {
      final cy = (top + bottom) / 2;
      h = h.clamp(minH, maxH);
      top = cy - h / 2;
      bottom = cy + h / 2;
    }

    final rect = Rect.fromLTRB(left, top, right, bottom);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = active ? const Color(0xFF4ADE80) : AppTheme.brandTeal;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(6), const Radius.circular(8)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant MouthBoxPainter oldDelegate) {
    return oldDelegate.minX != minX ||
        oldDelegate.minY != minY ||
        oldDelegate.maxX != maxX ||
        oldDelegate.maxY != maxY ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight ||
        oldDelegate.isFrontCamera != isFrontCamera ||
        oldDelegate.active != active;
  }
}

/// Camera preview with an optional mouth-region overlay when a face is detected.
class LipsCameraPreview extends StatelessWidget {
  const LipsCameraPreview({
    super.key,
    required this.controller,
    required this.result,
    required this.frameImageWidth,
    required this.frameImageHeight,
    required this.isFrontCamera,
    required this.lipsing,
  });

  final CameraController controller;
  final FaceLipsResult result;
  final int frameImageWidth;
  final int frameImageHeight;
  final bool isFrontCamera;
  final bool lipsing;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    final double displayAspect;
    if (previewSize != null) {
      displayAspect = isPortrait
          ? previewSize.height / previewSize.width
          : previewSize.width / previewSize.height;
    } else {
      final controllerAspect = controller.value.aspectRatio;
      displayAspect = isPortrait
          ? (controllerAspect > 0 ? 1 / controllerAspect : 9 / 16)
          : (controllerAspect > 0 ? controllerAspect : 16 / 9);
    }

    final screenSize = MediaQuery.sizeOf(context);
    final maxHeight = screenSize.height * 0.33;
    final maxWidth = screenSize.width - 28;
    var previewWidth = maxWidth;
    var previewHeight = previewWidth / displayAspect;
    if (previewHeight > maxHeight) {
      previewHeight = maxHeight;
      previewWidth = previewHeight * displayAspect;
    }

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: SizedBox(
          width: previewWidth,
          height: previewHeight,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                if (result.hasMouthBox)
                  CustomPaint(
                    painter: MouthBoxPainter(
                      minX: result.mouthMinX,
                      minY: result.mouthMinY,
                      maxX: result.mouthMaxX,
                      maxY: result.mouthMaxY,
                      imageWidth: frameImageWidth > 0
                          ? frameImageWidth
                          : (previewSize?.width.toInt() ?? 0),
                      imageHeight: frameImageHeight > 0
                          ? frameImageHeight
                          : (previewSize?.height.toInt() ?? 0),
                      isFrontCamera: isFrontCamera,
                      active: lipsing,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).scale(begin: const Offset(0.98, 0.98));
  }
}
