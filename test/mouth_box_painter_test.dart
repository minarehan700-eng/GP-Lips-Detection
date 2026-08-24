import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lips_offline/widgets/lips_camera_preview.dart';

/// Tests for placing the mouth box on screen.
///
/// This is the trickiest maths in the project, so it is tested directly:
/// [MouthBoxPainter.computeMouthRect] takes plain numbers and returns a plain
/// rectangle, with no drawing involved.
void main() {
  group('computeMouthRect — plain case (back camera, upright image)', () {
    // A portrait image needs no rotation, and a back camera needs no mirror,
    // so the mouth fractions map straight onto the preview.
    Rect compute({
      double minX = 0.4,
      double minY = 0.4,
      double maxX = 0.6,
      double maxY = 0.5,
    }) {
      return MouthBoxPainter.computeMouthRect(
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        imageWidth: 100,
        imageHeight: 200,
        isFrontCamera: false,
        widgetSize: const Size(200, 200),
      );
    }

    test('maps the mouth fractions onto the preview pixels', () {
      final box = compute();

      // 0.4 and 0.6 of a 200 px wide preview.
      expect(box.left, 80);
      expect(box.right, 120);
    });

    test('trims the height to keep mouth proportions', () {
      final box = compute();

      // The raw box was 40 x 20, but 20 is taller than the 48% limit,
      // so the height is pulled back to 40 * 0.48 = 19.2 around its centre.
      expect(box.width, 40);
      expect(box.height, closeTo(19.2, 0.0001));
      expect(box.center.dy, closeTo(90, 0.0001));
    });

    test('pads out a box that came back too flat', () {
      // A mouth box with no height at all still has to be drawn sensibly.
      final box = compute(minY: 0.45, maxY: 0.45);

      // Raised to the 22% minimum: 40 * 0.22 = 8.8.
      expect(box.height, closeTo(8.8, 0.0001));
      expect(box.center.dy, closeTo(90, 0.0001));
    });
  });

  group('computeMouthRect — front camera mirroring', () {
    Rect compute({required bool isFrontCamera}) {
      return MouthBoxPainter.computeMouthRect(
        minX: 0.1,
        minY: 0.4,
        maxX: 0.3,
        maxY: 0.5,
        imageWidth: 100,
        imageHeight: 200,
        isFrontCamera: isFrontCamera,
        widgetSize: const Size(200, 200),
      );
    }

    test('a mouth on the left appears on the right, and vice versa', () {
      final back = compute(isFrontCamera: false);
      final front = compute(isFrontCamera: true);

      expect(back.center.dx, closeTo(40, 0.0001));
      expect(front.center.dx, closeTo(160, 0.0001));

      // The two boxes are mirror images across the middle of the preview.
      expect(back.center.dx + front.center.dx, closeTo(200, 0.0001));
    });

    test('mirroring does not move the box up or down', () {
      final back = compute(isFrontCamera: false);
      final front = compute(isFrontCamera: true);

      expect(front.top, closeTo(back.top, 0.0001));
      expect(front.bottom, closeTo(back.bottom, 0.0001));
    });

    test('mirroring does not change the size of the box', () {
      final back = compute(isFrontCamera: false);
      final front = compute(isFrontCamera: true);

      expect(front.width, closeTo(back.width, 0.0001));
      expect(front.height, closeTo(back.height, 0.0001));
    });
  });

  group('computeMouthRect — sideways camera image', () {
    test('a landscape image in a portrait preview is rotated', () {
      const arguments = {
        'minX': 0.2,
        'minY': 0.3,
        'maxX': 0.4,
        'maxY': 0.6,
      };

      // Same mouth, but one frame is landscape (needs rotating) and the
      // other is portrait (does not).
      final rotated = MouthBoxPainter.computeMouthRect(
        minX: arguments['minX']!,
        minY: arguments['minY']!,
        maxX: arguments['maxX']!,
        maxY: arguments['maxY']!,
        imageWidth: 640,
        imageHeight: 480,
        isFrontCamera: false,
        widgetSize: const Size(200, 400),
      );
      final notRotated = MouthBoxPainter.computeMouthRect(
        minX: arguments['minX']!,
        minY: arguments['minY']!,
        maxX: arguments['maxX']!,
        maxY: arguments['maxY']!,
        imageWidth: 480,
        imageHeight: 640,
        isFrontCamera: false,
        widgetSize: const Size(200, 400),
      );

      expect(rotated, isNot(equals(notRotated)));
    });

    test('an unknown frame size is treated as needing no rotation', () {
      // Before the first frame is analysed the size is still 0.
      final unknown = MouthBoxPainter.computeMouthRect(
        minX: 0.2,
        minY: 0.3,
        maxX: 0.4,
        maxY: 0.6,
        imageWidth: 0,
        imageHeight: 0,
        isFrontCamera: false,
        widgetSize: const Size(200, 400),
      );
      final portrait = MouthBoxPainter.computeMouthRect(
        minX: 0.2,
        minY: 0.3,
        maxX: 0.4,
        maxY: 0.6,
        imageWidth: 480,
        imageHeight: 640,
        isFrontCamera: false,
        widgetSize: const Size(200, 400),
      );

      expect(unknown, portrait);
    });
  });

  group('computeMouthRect — rules that must always hold', () {
    test('the box is never taller than it is wide, whatever the input', () {
      final random = math.Random(99);

      for (var i = 0; i < 3000; i++) {
        final box = MouthBoxPainter.computeMouthRect(
          minX: random.nextDouble(),
          minY: random.nextDouble(),
          maxX: random.nextDouble(),
          maxY: random.nextDouble(),
          imageWidth: random.nextInt(2000),
          imageHeight: random.nextInt(2000),
          isFrontCamera: random.nextBool(),
          widgetSize: Size(
            1 + random.nextDouble() * 600,
            1 + random.nextDouble() * 600,
          ),
        );

        expect(box.height, lessThanOrEqualTo(box.width + 0.000001));
      }
    });

    test('the height always stays within the mouth proportions', () {
      final random = math.Random(1234);

      for (var i = 0; i < 3000; i++) {
        final box = MouthBoxPainter.computeMouthRect(
          minX: random.nextDouble(),
          minY: random.nextDouble(),
          maxX: random.nextDouble(),
          maxY: random.nextDouble(),
          imageWidth: random.nextInt(2000),
          imageHeight: random.nextInt(2000),
          isFrontCamera: random.nextBool(),
          widgetSize: Size(
            1 + random.nextDouble() * 600,
            1 + random.nextDouble() * 600,
          ),
        );

        final minimum = box.width * MouthBoxPainter.minHeightAsWidthRatio;
        final maximum = box.width * MouthBoxPainter.maxHeightAsWidthRatio;

        expect(box.height, greaterThanOrEqualTo(minimum - 0.000001));
        expect(box.height, lessThanOrEqualTo(maximum + 0.000001));
      }
    });
  });
}
