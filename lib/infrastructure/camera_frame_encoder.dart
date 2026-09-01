import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// The parts of one camera frame that the conversion actually needs, copied
/// out as plain numbers and byte lists.
///
/// Why this exists:
/// A [CameraImage] cannot be sent to a background isolate — it holds platform
/// handles. The pixel conversion is the most expensive thing the app does per
/// frame, so it has to run off the UI isolate, and this is the sendable shape
/// it is given.
@immutable
class RawCameraFrame {
  const RawCameraFrame({
    required this.width,
    required this.height,
    required this.isYuv420,
    required this.primaryBytes,
    required this.primaryRowStride,
    this.chromaBlue,
    this.chromaRed,
    this.chromaRowStride = 0,
    this.chromaPixelStride = 1,
  });

  final int width;
  final int height;

  /// True for Android's three-plane YUV420, false for iOS's single-plane BGRA.
  final bool isYuv420;

  /// Y plane on Android, the whole BGRA image on iOS.
  final Uint8List primaryBytes;

  /// Bytes per row of [primaryBytes]. A row can be padded to a
  /// hardware-friendly length, making it wider than [width].
  final int primaryRowStride;

  final Uint8List? chromaBlue;
  final Uint8List? chromaRed;
  final int chromaRowStride;
  final int chromaPixelStride;
}

/// Turns a raw camera frame into JPEG bytes.
///
/// Why this class is needed:
/// The camera plugin hands us frames in the phone's native pixel format
/// (YUV420 on Android, BGRA on iOS). The native MediaPipe bridge expects a
/// normal image it can decode. JPEG is used because both platforms can decode
/// it out of the box, so one code path works for Android and iOS.
class CameraFrameEncoder {
  /// The two colour values (U and V) are shared by each 2×2 block of pixels,
  /// so their row and column indexes are halved. See [convertYuv420ToImage].
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

  /// Why the last frame could not be converted, or null if the last one was
  /// fine.
  ///
  /// Every failure used to be swallowed by one catch-all that returned null,
  /// which made a device-specific problem indistinguishable from "no face in
  /// shot": the app would show "Not detected" forever with nothing to go on.
  /// The reason is recorded here instead of being logged, because the app
  /// deliberately prints nothing at runtime.
  String? lastFailureReason;

  /// Converts one camera frame to JPEG bytes.
  ///
  /// Input:  [image] — a frame from the camera stream.
  ///         [quality] — JPEG quality from 1 (small) to 100 (best).
  /// Output: the JPEG bytes, or null when the frame could not be converted,
  ///         with [lastFailureReason] set.
  ///
  /// Returning null instead of throwing is deliberate: a single unusable frame
  /// should simply be skipped, never crash the live camera pipeline.
  ///
  /// The frame is validated here, on the calling isolate, so the reason for a
  /// rejection is available immediately. Only the per-pixel work is handed to
  /// a background isolate.
  Future<Uint8List?> encodeToJpeg(CameraImage image, {int quality = 80}) async {
    final RawCameraFrame? frame = describeFrame(image);
    if (frame == null) {
      return null;
    }
    try {
      final Uint8List bytes =
          await compute(encodeRawFrame, EncodeRequest(frame, quality));
      lastFailureReason = null;
      return bytes;
    } catch (error) {
      lastFailureReason = 'Converting the frame failed: $error';
      return null;
    }
  }

  /// Copies the metadata and bytes needed for conversion out of [image].
  ///
  /// Output: null when this frame cannot be used, with [lastFailureReason]
  /// naming which check failed rather than leaving it a mystery.
  RawCameraFrame? describeFrame(CameraImage image) {
    if (image.width <= 0 || image.height <= 0) {
      lastFailureReason =
          'Frame has no size (${image.width}×${image.height}).';
      return null;
    }

    if (image.format.group == ImageFormatGroup.bgra8888) {
      if (image.planes.isEmpty) {
        lastFailureReason = 'BGRA frame arrived with no planes.';
        return null;
      }
      final plane = image.planes.first;
      return RawCameraFrame(
        width: image.width,
        height: image.height,
        isYuv420: false,
        primaryBytes: plane.bytes,
        primaryRowStride: plane.bytesPerRow,
      );
    }

    if (image.format.group == ImageFormatGroup.yuv420) {
      if (image.planes.length < 3) {
        lastFailureReason =
            'YUV frame has ${image.planes.length} planes, expected 3.';
        return null;
      }
      final uPlane = image.planes[1];
      // Previously a `!` force-unwrap. On a device that reports no value the
      // throw was caught by the outer catch-all and every frame was dropped
      // silently, forever.
      final int? chromaPixelStride = uPlane.bytesPerPixel;
      if (chromaPixelStride == null) {
        lastFailureReason =
            'The camera did not report bytesPerPixel for the colour plane.';
        return null;
      }
      return RawCameraFrame(
        width: image.width,
        height: image.height,
        isYuv420: true,
        primaryBytes: image.planes[0].bytes,
        primaryRowStride: image.planes[0].bytesPerRow,
        chromaBlue: uPlane.bytes,
        chromaRed: image.planes[2].bytes,
        chromaRowStride: uPlane.bytesPerRow,
        chromaPixelStride: chromaPixelStride,
      );
    }

    lastFailureReason =
        'Unsupported frame format: ${image.format.group}.';
    return null;
  }

  /// Rounds a computed colour into a valid 0–255 byte.
  static int toColorByte(double value) {
    return value.clamp(minColorValue, maxColorValue).toInt();
  }
}

/// One unit of work for the background isolate.
@immutable
class EncodeRequest {
  const EncodeRequest(this.frame, this.quality);
  final RawCameraFrame frame;
  final int quality;
}

/// Runs on a background isolate: converts the frame and compresses it.
///
/// Top-level rather than a method, because [compute] can only call a function
/// that carries no captured state.
Uint8List encodeRawFrame(EncodeRequest request) {
  final img.Image converted = request.frame.isYuv420
      ? convertYuv420ToImage(request.frame)
      : convertBgraToImage(request.frame);
  return Uint8List.fromList(
    img.encodeJpg(converted, quality: request.quality),
  );
}

/// Builds an image from an iOS-style BGRA frame.
///
/// This is the easy case: the bytes are already one block of colour pixels,
/// so they only need to be relabelled as an image.
///
/// Both the byte offset and the row stride are passed through. `plane.bytes`
/// can be a view into a larger buffer, so handing over the bare buffer read
/// from the wrong starting point; and a padded row made every row after the
/// first drift sideways.
img.Image convertBgraToImage(RawCameraFrame frame) {
  return img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.primaryBytes.buffer,
    bytesOffset: frame.primaryBytes.offsetInBytes,
    rowStride: frame.primaryRowStride,
    order: img.ChannelOrder.bgra,
  );
}

/// Builds an image from an Android-style YUV420 frame.
///
/// YUV420 stores a frame in three separate planes:
///   Y — brightness, one value per pixel;
///   U and V — colour, one value per 2×2 block of pixels.
/// Every pixel therefore needs its own Y value but shares U and V with its
/// neighbours, which is why the colour indexes below are divided by two.
img.Image convertYuv420ToImage(RawCameraFrame frame) {
  final int width = frame.width;
  final int height = frame.height;
  final Uint8List brightness = frame.primaryBytes;
  final Uint8List blue = frame.chromaBlue!;
  final Uint8List red = frame.chromaRed!;
  final output = img.Image(width: width, height: height);

  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      // Step 1: find this pixel's brightness.
      // The row stride is used instead of the width because a row may be
      // padded to a hardware-friendly length, making it wider than the image.
      final int brightnessIndex = y * frame.primaryRowStride + x;

      // Step 2: find the colour values, shared across each 2×2 block.
      final int chromaIndex =
          (y ~/ CameraFrameEncoder.chromaSubsampleFactor) *
                  frame.chromaRowStride +
              (x ~/ CameraFrameEncoder.chromaSubsampleFactor) *
                  frame.chromaPixelStride;

      final int luma = brightness[brightnessIndex];
      final int blueDifference =
          blue[chromaIndex] - CameraFrameEncoder.chromaNeutral;
      final int redDifference =
          red[chromaIndex] - CameraFrameEncoder.chromaNeutral;

      // Step 3: convert brightness + colour difference into red/green/blue,
      // clamping because the formula can overshoot the 0–255 range slightly.
      final int r = CameraFrameEncoder.toColorByte(
        luma + CameraFrameEncoder.redFromV * redDifference,
      );
      final int g = CameraFrameEncoder.toColorByte(
        luma -
            CameraFrameEncoder.greenFromU * blueDifference -
            CameraFrameEncoder.greenFromV * redDifference,
      );
      final int b = CameraFrameEncoder.toColorByte(
        luma + CameraFrameEncoder.blueFromU * blueDifference,
      );

      output.setPixelRgb(x, y, r, g, b);
    }
  }

  return output;
}
