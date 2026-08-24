import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Turns a raw camera frame into JPEG bytes.
///
/// Why this class is needed:
/// The camera plugin hands us frames in the phone's native pixel format
/// (YUV420 on Android, BGRA on iOS). The native MediaPipe bridge expects a
/// normal image it can decode. JPEG is used because both platforms can decode
/// it out of the box, so one code path works for Android and iOS.
class CameraFrameEncoder {
  /// The two colour values (U and V) are shared by each 2×2 block of pixels,
  /// so their row and column indexes are halved. See [_encodeYuv420].
  static const int chromaSubsampleFactor = 2;

  /// Middle point of the U/V range; values below it mean one colour direction
  /// and values above it the other.
  static const int chromaNeutral = 128;

  // Standard BT.601 coefficients for converting YUV to RGB. These are fixed
  // numbers from the video standard the camera uses, not tuning values.
  static const double redFromV = 1.370705;
  static const double greenFromU = 0.337633;
  static const double greenFromV = 0.698001;
  static const double blueFromU = 1.732446;

  static const int minColorValue = 0;
  static const int maxColorValue = 255;

  /// Converts one camera frame to JPEG bytes.
  ///
  /// Input:  [image] — a frame from the camera stream.
  ///         [quality] — JPEG quality from 1 (small) to 100 (best).
  /// Output: the JPEG bytes, or null when the frame could not be converted.
  ///
  /// Returning null instead of throwing is deliberate: a single unusable frame
  /// should simply be skipped, never crash the live camera pipeline.
  Future<Uint8List?> encodeToJpeg(CameraImage image, {int quality = 80}) async {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return _encodeBgra(image, quality: quality);
      }
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _encodeYuv420(image, quality: quality);
      }
      // An unexpected format (rare, device specific) — skip this frame.
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Encodes an iOS-style BGRA frame.
  ///
  /// This is the easy case: the bytes are already one block of colour pixels,
  /// so they only need to be relabelled as an image and compressed.
  Uint8List _encodeBgra(CameraImage image, {required int quality}) {
    final plane = image.planes.first;
    final converted = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: plane.bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
    return Uint8List.fromList(img.encodeJpg(converted, quality: quality));
  }

  /// Encodes an Android-style YUV420 frame.
  ///
  /// This is the harder case. YUV420 stores a frame in three separate planes:
  ///   Y — brightness, one value per pixel;
  ///   U and V — colour, one value per 2×2 block of pixels.
  /// Every pixel therefore needs its own Y value but shares U and V with its
  /// neighbours, which is why the colour indexes below are divided by two.
  ///
  /// Output: JPEG bytes of the same width and height as the input frame.
  Uint8List _encodeYuv420(CameraImage image, {required int quality}) {
    final int width = image.width;
    final int height = image.height;
    final brightnessPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    // Colour planes are stored with the same layout, so one index serves both.
    final int chromaBytesPerPixel = uPlane.bytesPerPixel!;
    final output = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        // Step 1: find this pixel's brightness.
        // `bytesPerRow` is used instead of `width` because a row may be padded
        // to a hardware-friendly length, making it wider than the image.
        final int brightnessIndex = y * brightnessPlane.bytesPerRow + x;

        // Step 2: find the colour values, shared across each 2×2 block.
        final int chromaIndex =
            (y ~/ chromaSubsampleFactor) * uPlane.bytesPerRow +
                (x ~/ chromaSubsampleFactor) * chromaBytesPerPixel;

        final int brightness = brightnessPlane.bytes[brightnessIndex];
        final int blueDifference = uPlane.bytes[chromaIndex] - chromaNeutral;
        final int redDifference = vPlane.bytes[chromaIndex] - chromaNeutral;

        // Step 3: convert brightness + colour difference into red/green/blue,
        // clamping because the formula can overshoot the 0–255 range slightly.
        final int red = _toColorByte(brightness + redFromV * redDifference);
        final int green = _toColorByte(
          brightness - greenFromU * blueDifference - greenFromV * redDifference,
        );
        final int blue = _toColorByte(brightness + blueFromU * blueDifference);

        output.setPixelRgb(x, y, red, green, blue);
      }
    }

    return Uint8List.fromList(img.encodeJpg(output, quality: quality));
  }

  /// Rounds a computed colour into a valid 0–255 byte.
  static int _toColorByte(double value) {
    return value.clamp(minColorValue, maxColorValue).toInt();
  }
}
