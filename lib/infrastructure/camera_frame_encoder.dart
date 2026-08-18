import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

/// Converts camera frames (YUV420 or BGRA) to JPEG for native face detection.
class CameraFrameEncoder {
  Future<Uint8List?> encodeToJpeg(CameraImage image, {int quality = 80}) async {
    try {
      if (image.format.group == ImageFormatGroup.bgra8888) {
        return _encodeBgra(image, quality: quality);
      }
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _encodeYuv420(image, quality: quality);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

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

  Uint8List _encodeYuv420(CameraImage image, {required int quality}) {
    final width = image.width;
    final height = image.height;
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final out = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;
        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt();
        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return Uint8List.fromList(img.encodeJpg(out, quality: quality));
  }
}
