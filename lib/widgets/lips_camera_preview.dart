import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../core/app_theme.dart';
import '../domain/face_lips_result.dart';
import 'glass_card.dart';

/// Draws the box around the mouth on top of the camera preview.
///
/// Why this class is needed:
/// MediaPipe reports the mouth position as four numbers between 0.0 and 1.0
/// (fractions of the camera frame). The screen needs pixels. Turning one into
/// the other is not a simple multiplication, because:
///   * the camera sensor may deliver a sideways (landscape) image while the
///     phone is held upright, so the two axes must be swapped;
///   * the front camera shows a mirror image, so left and right must be
///     flipped or the box would follow the mouth the wrong way.
///
/// The geometry is kept in [computeMouthRect], a plain function with no
/// drawing in it, so it can be tested on its own.
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

  /// A mouth is a wide, flat shape. These ratios keep the drawn box looking
  /// like a mouth even when the landmark corners give an odd shape — for
  /// example when the user turns their head and the box becomes too flat.
  static const double minHeightAsWidthRatio = 0.22;
  static const double maxHeightAsWidthRatio = 0.48;

  /// Breathing room in pixels between the mouth and the drawn box.
  static const double boxPaddingPixels = 6;
  static const double boxCornerRadius = 8;
  static const double boxStrokeWidth = 2.5;

  /// Mouth corners and mid-lip points, as fractions (0.0 – 1.0) of the frame.
  final double minX;
  final double minY;
  final double maxX;
  final double maxY;

  /// Size of the analysed camera frame, used to detect a sideways image.
  final int imageWidth;
  final int imageHeight;

  /// True when the mirrored front camera is in use.
  final bool isFrontCamera;

  /// True while lipsing is detected — the box turns green instead of teal.
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect mouthRect = computeMouthRect(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      isFrontCamera: isFrontCamera,
      widgetSize: size,
    );

    final Paint boxPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = boxStrokeWidth
      ..color = active ? AppTheme.successGreen : AppTheme.brandTeal;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mouthRect.inflate(boxPaddingPixels),
        const Radius.circular(boxCornerRadius),
      ),
      boxPaint,
    );
  }

  /// Works out where to draw the mouth box, in screen pixels.
  ///
  /// Input:  [minX]–[maxY] — the mouth corners as 0.0–1.0 fractions.
  ///         [imageWidth], [imageHeight] — the analysed frame size.
  ///         [isFrontCamera] — whether the image is mirrored.
  ///         [widgetSize] — the size of the preview on screen, in pixels.
  /// Output: the rectangle to draw, before padding is added.
  ///
  /// Steps:
  ///   1. Move both mouth corners from frame space into screen pixels.
  ///   2. Build a rectangle from them (either corner may end up first once
  ///      the image is rotated or mirrored, so take min and max).
  ///   3. Force the box to be wider than it is tall — a mouth always is.
  ///   4. Keep the height within sensible mouth proportions.
  static Rect computeMouthRect({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
    required int imageWidth,
    required int imageHeight,
    required bool isFrontCamera,
    required Size widgetSize,
  }) {
    // Step 1: move both mouth corners into screen pixels.
    final bool swapAxes = _shouldSwapAxes(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      widgetSize: widgetSize,
    );

    final Offset firstCorner = _toScreenPoint(
      normalizedX: minX,
      normalizedY: minY,
      swapAxes: swapAxes,
      isFrontCamera: isFrontCamera,
      widgetSize: widgetSize,
    );
    final Offset secondCorner = _toScreenPoint(
      normalizedX: maxX,
      normalizedY: maxY,
      swapAxes: swapAxes,
      isFrontCamera: isFrontCamera,
      widgetSize: widgetSize,
    );

    // Step 2: build the four edges. Either corner may come out first once the
    // image has been rotated or mirrored, so take the smaller and larger of
    // each pair rather than assuming an order.
    double left = math.min(firstCorner.dx, secondCorner.dx);
    double top = math.min(firstCorner.dy, secondCorner.dy);
    double right = math.max(firstCorner.dx, secondCorner.dx);
    double bottom = math.max(firstCorner.dy, secondCorner.dy);

    double width = right - left;
    double height = bottom - top;

    // Step 3: a mouth is always wider than it is tall. After a rotation the
    // box can come out standing upright, so swap its two sides around the
    // same centre point — the box keeps its position, only its shape turns.
    if (height > width) {
      final double centerX = (left + right) / 2;
      final double centerY = (top + bottom) / 2;

      final double turnedWidth = height;
      final double turnedHeight = width;
      width = turnedWidth;
      height = turnedHeight;

      left = centerX - width / 2;
      right = centerX + width / 2;
      top = centerY - height / 2;
      bottom = centerY + height / 2;
    }

    // Step 4: keep the height sensible compared with the width. Too flat and
    // the box is a line across the lips; too tall and it covers the chin.
    // Only the height changes — the left and right edges stay where they are.
    final double minimumHeight = width * minHeightAsWidthRatio;
    final double maximumHeight = width * maxHeightAsWidthRatio;

    if (height < minimumHeight || height > maximumHeight) {
      final double centerY = (top + bottom) / 2;
      height = height.clamp(minimumHeight, maximumHeight);
      top = centerY - height / 2;
      bottom = centerY + height / 2;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// True when the camera frame is sideways compared with the preview.
  ///
  /// Many phone cameras always deliver a landscape image even when the phone
  /// is held upright. When that happens the X and Y axes must be exchanged
  /// before the mouth position makes sense on screen.
  static bool _shouldSwapAxes({
    required int imageWidth,
    required int imageHeight,
    required Size widgetSize,
  }) {
    final bool imageIsLandscape =
        imageWidth > 0 && imageHeight > 0 && imageWidth > imageHeight;
    final bool widgetIsPortrait = widgetSize.height > widgetSize.width;
    return imageIsLandscape && widgetIsPortrait;
  }

  /// Converts one 0.0–1.0 point from the camera frame into screen pixels.
  ///
  /// The rotation step turns the point a quarter-turn: the old Y becomes the
  /// new X, and the old X becomes the new Y measured from the other end
  /// (hence `1.0 - x`). The mirror step then flips X for the front camera.
  static Offset _toScreenPoint({
    required double normalizedX,
    required double normalizedY,
    required bool swapAxes,
    required bool isFrontCamera,
    required Size widgetSize,
  }) {
    double x = normalizedX;
    double y = normalizedY;

    if (swapAxes) {
      final double originalX = x;
      x = y;
      y = 1.0 - originalX;
    }

    if (isFrontCamera) {
      x = 1.0 - x;
    }

    return Offset(x * widgetSize.width, y * widgetSize.height);
  }

  /// Redraw only when something that affects the box has actually changed.
  /// Without this check the overlay would repaint on every screen frame.
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

/// The live camera picture, with the mouth box drawn on top of it.
///
/// The preview is sized by hand rather than left to fill the screen, so the
/// status cards and metrics below it always stay visible without scrolling.
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

  /// Share of the screen height the preview may use at most.
  static const double maxScreenHeightFraction = 0.33;

  /// Left plus right page padding to subtract from the available width.
  static const double horizontalPagePadding = 28;

  /// Fallback shapes used only when the camera has not reported its size yet.
  static const double fallbackPortraitAspect = 9 / 16;
  static const double fallbackLandscapeAspect = 16 / 9;

  final CameraController controller;
  final FaceLipsResult result;
  final int frameImageWidth;
  final int frameImageHeight;
  final bool isFrontCamera;
  final bool lipsing;

  @override
  Widget build(BuildContext context) {
    final bool isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final double aspectRatio = _previewAspectRatio(isPortrait: isPortrait);
    final Size previewSize = _fitPreview(
      screenSize: MediaQuery.sizeOf(context),
      aspectRatio: aspectRatio,
    );

    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.all(8),
      child: Center(
        child: SizedBox(
          width: previewSize.width,
          height: previewSize.height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(controller),
                if (result.hasMouthBox) _buildMouthOverlay(),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 280.ms).scale(begin: const Offset(0.98, 0.98));
  }

  /// The mouth box layer, drawn only when a usable box was detected.
  ///
  /// The frame size is normally taken from the last analysed frame. Before the
  /// first frame arrives that size is still 0, so the camera's own preview
  /// size is used instead and the box is still placed sensibly.
  Widget _buildMouthOverlay() {
    final previewSize = controller.value.previewSize;

    return CustomPaint(
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
    );
  }

  /// Width divided by height for the preview box.
  ///
  /// The camera reports its size the way the sensor sees it, which is rotated
  /// compared with an upright phone — that is why width and height are read in
  /// the opposite order in portrait.
  double _previewAspectRatio({required bool isPortrait}) {
    final previewSize = controller.value.previewSize;

    if (previewSize != null) {
      return isPortrait
          ? previewSize.height / previewSize.width
          : previewSize.width / previewSize.height;
    }

    // The size is not known yet; fall back to the controller's aspect ratio,
    // and to a standard phone shape if that is not ready either.
    final double controllerAspect = controller.value.aspectRatio;
    if (isPortrait) {
      return controllerAspect > 0 ? 1 / controllerAspect : fallbackPortraitAspect;
    }
    return controllerAspect > 0 ? controllerAspect : fallbackLandscapeAspect;
  }

  /// Picks the largest preview that fits the page without pushing the results
  /// off screen.
  ///
  /// It starts as wide as the page allows, then shrinks to match the height
  /// limit if the resulting picture would be too tall.
  static Size _fitPreview({
    required Size screenSize,
    required double aspectRatio,
  }) {
    final double maxHeight = screenSize.height * maxScreenHeightFraction;
    final double maxWidth = screenSize.width - horizontalPagePadding;

    double width = maxWidth;
    double height = width / aspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }
    return Size(width, height);
  }
}
