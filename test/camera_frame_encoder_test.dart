import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:lips_offline/infrastructure/camera_frame_encoder.dart';

/// Tests for turning a raw camera frame into an image.
///
/// This file had no tests before, and it is where the frame arrives from the
/// hardware — so the cases that matter are the awkward ones a real device
/// produces: padded rows, interleaved colour planes, and metadata the camera
/// declines to fill in.
void main() {
  /// The YUV→RGB conversion exactly as it was written before the conversion
  /// was moved off the UI isolate, transcribed here so the new code can be
  /// checked against it rather than against itself.
  ({int r, int g, int b}) referencePixel(int luma, int u, int v) {
    const neutral = CameraFrameEncoder.chromaNeutral;
    final blueDifference = u - neutral;
    final redDifference = v - neutral;
    int toByte(double value) => value.clamp(0, 255).toInt();
    return (
      r: toByte(luma + CameraFrameEncoder.redFromV * redDifference),
      g: toByte(luma -
          CameraFrameEncoder.greenFromU * blueDifference -
          CameraFrameEncoder.greenFromV * redDifference),
      b: toByte(luma + CameraFrameEncoder.blueFromU * blueDifference),
    );
  }

  /// Builds a YUV420 frame whose rows are padded, and whose colour planes are
  /// interleaved — both of which real Android devices do.
  RawCameraFrame buildYuvFrame({
    required int width,
    required int height,
    int rowPadding = 0,
    int chromaPixelStride = 2,
  }) {
    final int yStride = width + rowPadding;
    final y = Uint8List(yStride * height);
    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        y[row * yStride + col] = (row * 31 + col * 17) % 256;
      }
      for (var pad = 0; pad < rowPadding; pad++) {
        // Deliberate poison: if the conversion ignores the stride it will read
        // these bytes and the comparison below will fail.
        y[row * yStride + width + pad] = 255;
      }
    }

    final int chromaWidth = (width / 2).ceil();
    final int chromaHeight = (height / 2).ceil();
    final int chromaStride = chromaWidth * chromaPixelStride + rowPadding;
    final u = Uint8List(chromaStride * chromaHeight);
    final v = Uint8List(chromaStride * chromaHeight);
    for (var row = 0; row < chromaHeight; row++) {
      for (var col = 0; col < chromaWidth; col++) {
        final int at = row * chromaStride + col * chromaPixelStride;
        u[at] = (row * 13 + col * 7) % 256;
        v[at] = (row * 5 + col * 29) % 256;
      }
    }

    return RawCameraFrame(
      width: width,
      height: height,
      isYuv420: true,
      primaryBytes: y,
      primaryRowStride: yStride,
      chromaBlue: u,
      chromaRed: v,
      chromaRowStride: chromaStride,
      chromaPixelStride: chromaPixelStride,
    );
  }

  group('YUV420 conversion', () {
    test('every pixel matches the reference formula, with padded rows', () {
      final frame = buildYuvFrame(width: 8, height: 6, rowPadding: 4);
      final result = convertYuv420ToImage(frame);

      expect(result.width, 8);
      expect(result.height, 6);

      for (var y = 0; y < 6; y++) {
        for (var x = 0; x < 8; x++) {
          final luma = frame.primaryBytes[y * frame.primaryRowStride + x];
          final chromaAt = (y ~/ 2) * frame.chromaRowStride +
              (x ~/ 2) * frame.chromaPixelStride;
          final expected = referencePixel(
            luma,
            frame.chromaBlue![chromaAt],
            frame.chromaRed![chromaAt],
          );
          final actual = result.getPixel(x, y);
          expect(
            (r: actual.r.toInt(), g: actual.g.toInt(), b: actual.b.toInt()),
            expected,
            reason: 'pixel ($x, $y)',
          );
        }
      }
    });

    test('an unpadded frame converts identically', () {
      final frame = buildYuvFrame(width: 4, height: 4, chromaPixelStride: 1);
      final result = convertYuv420ToImage(frame);

      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final luma = frame.primaryBytes[y * frame.primaryRowStride + x];
          final chromaAt = (y ~/ 2) * frame.chromaRowStride + (x ~/ 2);
          final expected = referencePixel(
              luma, frame.chromaBlue![chromaAt], frame.chromaRed![chromaAt]);
          final actual = result.getPixel(x, y);
          expect(
            (r: actual.r.toInt(), g: actual.g.toInt(), b: actual.b.toInt()),
            expected,
          );
        }
      }
    });

    test('extreme colour differences are clamped, not wrapped', () {
      // 255/0 pushes the formula past both ends of the 0-255 range. Wrapping
      // instead of clamping would show up as bright speckle on the lips.
      final frame = RawCameraFrame(
        width: 2,
        height: 2,
        isYuv420: true,
        primaryBytes: Uint8List.fromList([255, 255, 255, 255]),
        primaryRowStride: 2,
        chromaBlue: Uint8List.fromList([255]),
        chromaRed: Uint8List.fromList([0]),
        chromaRowStride: 1,
        chromaPixelStride: 1,
      );

      final pixel = convertYuv420ToImage(frame).getPixel(0, 0);

      expect(pixel.r.toInt(), inInclusiveRange(0, 255));
      expect(pixel.g.toInt(), inInclusiveRange(0, 255));
      expect(pixel.b.toInt(), inInclusiveRange(0, 255));
      expect(pixel.b.toInt(), 255); // driven well past the top, so clamped
    });
  });

  group('BGRA conversion', () {
    test('reads from the right offset when the bytes are a view', () {
      // plane.bytes is often a window into a larger buffer. Handing over the
      // bare .buffer ignored that window and read the wrong pixels.
      const width = 2;
      const height = 2;
      const offset = 16;
      final backing = Uint8List(offset + width * height * 4);
      for (var i = 0; i < offset; i++) {
        backing[i] = 0xEE; // poison ahead of the window
      }
      final pixels = <int>[
        10, 20, 30, 255, // B G R A
        40, 50, 60, 255,
        70, 80, 90, 255,
        100, 110, 120, 255,
      ];
      backing.setRange(offset, offset + pixels.length, pixels);

      final view = Uint8List.view(backing.buffer, offset, pixels.length);
      final result = convertBgraToImage(RawCameraFrame(
        width: width,
        height: height,
        isYuv420: false,
        primaryBytes: view,
        primaryRowStride: width * 4,
      ));

      final first = result.getPixel(0, 0);
      expect(first.r.toInt(), 30);
      expect(first.g.toInt(), 20);
      expect(first.b.toInt(), 10);

      final last = result.getPixel(1, 1);
      expect(last.r.toInt(), 120);
      expect(last.g.toInt(), 110);
      expect(last.b.toInt(), 100);
    });

    test('a padded row does not shift the rows below it', () {
      const width = 2;
      const height = 2;
      const stride = 12; // 8 bytes of pixels + 4 bytes of padding
      final bytes = Uint8List(stride * height);
      bytes.setRange(0, 8, [10, 20, 30, 255, 40, 50, 60, 255]);
      bytes.setRange(8, 12, [0xEE, 0xEE, 0xEE, 0xEE]);
      bytes.setRange(12, 20, [70, 80, 90, 255, 100, 110, 120, 255]);

      final result = convertBgraToImage(RawCameraFrame(
        width: width,
        height: height,
        isYuv420: false,
        primaryBytes: bytes,
        primaryRowStride: stride,
      ));

      final secondRow = result.getPixel(0, 1);
      expect(secondRow.r.toInt(), 90);
      expect(secondRow.g.toInt(), 80);
      expect(secondRow.b.toInt(), 70);
    });
  });

  group('rejecting a frame', () {
    CameraImage imageWith({
      required ImageFormatGroup format,
      required List<CameraImagePlane> planes,
      int width = 4,
      int height = 4,
    }) {
      return CameraImage.fromPlatformInterface(CameraImageData(
        format: CameraImageFormat(format, raw: 0),
        planes: planes,
        width: width,
        height: height,
      ));
    }

    CameraImagePlane plane({int? bytesPerPixel, int bytesPerRow = 4}) {
      return CameraImagePlane(
        bytes: Uint8List(16),
        bytesPerRow: bytesPerRow,
        bytesPerPixel: bytesPerPixel,
      );
    }

    test('says so when the colour plane has no bytesPerPixel', () {
      // This used to be a `!` force-unwrap: the throw was swallowed and every
      // frame was dropped for the rest of the session with nothing reported.
      final encoder = CameraFrameEncoder();

      final described = encoder.describeFrame(imageWith(
        format: ImageFormatGroup.yuv420,
        planes: [plane(), plane(bytesPerPixel: null), plane()],
      ));

      expect(described, isNull);
      expect(encoder.lastFailureReason, contains('bytesPerPixel'));
    });

    test('says so when a YUV frame is missing planes', () {
      final encoder = CameraFrameEncoder();

      final described = encoder.describeFrame(imageWith(
        format: ImageFormatGroup.yuv420,
        planes: [plane(bytesPerPixel: 1)],
      ));

      expect(described, isNull);
      expect(encoder.lastFailureReason, contains('1 planes'));
    });

    test('says so when the format is one it cannot read', () {
      final encoder = CameraFrameEncoder();

      final described = encoder.describeFrame(imageWith(
        format: ImageFormatGroup.jpeg,
        planes: [plane()],
      ));

      expect(described, isNull);
      expect(encoder.lastFailureReason, contains('Unsupported'));
    });

    test('accepts a well-formed YUV frame and carries the strides over', () {
      final encoder = CameraFrameEncoder();

      final described = encoder.describeFrame(imageWith(
        format: ImageFormatGroup.yuv420,
        planes: [
          plane(bytesPerRow: 6),
          plane(bytesPerPixel: 2, bytesPerRow: 6),
          plane(bytesPerPixel: 2, bytesPerRow: 6),
        ],
      ));

      expect(described, isNotNull);
      expect(described!.isYuv420, isTrue);
      expect(described.primaryRowStride, 6);
      expect(described.chromaPixelStride, 2);
      expect(encoder.lastFailureReason, isNull);
    });
  });

  group('end to end', () {
    test('a frame becomes decodable JPEG bytes', () async {
      final encoder = CameraFrameEncoder();
      final image = CameraImage.fromPlatformInterface(CameraImageData(
        format: CameraImageFormat(ImageFormatGroup.yuv420, raw: 0),
        width: 8,
        height: 8,
        planes: [
          CameraImagePlane(bytes: Uint8List(64), bytesPerRow: 8),
          CameraImagePlane(
              bytes: Uint8List(32), bytesPerRow: 8, bytesPerPixel: 2),
          CameraImagePlane(
              bytes: Uint8List(32), bytesPerRow: 8, bytesPerPixel: 2),
        ],
      ));

      final bytes = await encoder.encodeToJpeg(image, quality: 90);

      expect(bytes, isNotNull);
      expect(encoder.lastFailureReason, isNull);
      final decoded = img.decodeJpg(bytes!);
      expect(decoded, isNotNull);
      expect(decoded!.width, 8);
      expect(decoded.height, 8);
    });
  });
}
