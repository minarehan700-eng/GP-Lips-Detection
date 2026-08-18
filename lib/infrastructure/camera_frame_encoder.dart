import 'dart:typed_data'; // استيراد Uint8List لمصفوفات البايت

import 'package:camera/camera.dart'; // استيراد CameraImage من حزمة الكاميرا
import 'package:image/image.dart' as img; // مكتبة معالجة الصور (تحويل YUV إلى JPEG)

class CameraFrameEncoder { // كلاس يحوّل إطار الكاميرا إلى JPEG
  Future<Uint8List?> encodeToJpeg(CameraImage image, {int quality = 80}) async { // تحويل الإطار إلى JPEG
    try { // محاولة التحويل
      if (image.format.group == ImageFormatGroup.bgra8888) { // إذا الصيغة BGRA
        return _encodeBgra(image, quality: quality); // استخدم دالة BGRA
      } // نهاية if BGRA
      if (image.format.group == ImageFormatGroup.yuv420) { // إذا الصيغة YUV420 (الأكثر شيوعاً)
        return _encodeYuv420(image, quality: quality); // استخدم دالة YUV
      } // نهاية if YUV
      return null; // صيغة غير مدعومة
    } catch (_) { // في حالة أي خطأ
      return null; // أرجع null بدلاً من إيقاف التطبيق
    } // نهاية try-catch
  } // نهاية encodeToJpeg

  Uint8List _encodeBgra(CameraImage image, {required int quality}) { // تحويل BGRA مباشرة إلى JPEG
    final plane = image.planes.first; // أخذ أول plane (يحمل بيانات BGRA)
    final converted = img.Image.fromBytes( // إنشاء صورة من البايتات
      width: image.width, // عرض الإطار
      height: image.height, // ارتفاع الإطار
      bytes: plane.bytes.buffer, // buffer البايتات
      order: img.ChannelOrder.bgra, // ترتيب القنوات BGRA
    ); // نهاية Image.fromBytes
    return Uint8List.fromList(img.encodeJpg(converted, quality: quality)); // ترميز JPEG وإرجاع Uint8List
  } // نهاية _encodeBgra

  Uint8List _encodeYuv420(CameraImage image, {required int quality}) { // تحويل YUV420 إلى JPEG
    final width = image.width; // عرض الصورة
    final height = image.height; // ارتفاع الصورة
    final yPlane = image.planes[0]; // plane اللuminance (Y)
    final uPlane = image.planes[1]; // plane الكروما U
    final vPlane = image.planes[2]; // plane الكروما V
    final out = img.Image(width: width, height: height); // صورة RGB فارغة للنتيجة

    for (var y = 0; y < height; y++) { // حلقة على كل صف
      for (var x = 0; x < width; x++) { // حلقة على كل عمود
        final yIndex = y * yPlane.bytesPerRow + x; // موقع قيمة Y في المصفوفة
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!; // موقع U/V (مشترك)
        final yValue = yPlane.bytes[yIndex]; // قراءة Y
        final uValue = uPlane.bytes[uvIndex]; // قراءة U
        final vValue = vPlane.bytes[uvIndex]; // قراءة V

        final r = (yValue + 1.370705 * (vValue - 128)).clamp(0, 255).toInt(); // حساب الأحمر من YUV
        final g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)) // حساب الأخضر
            .clamp(0, 255) // تقييد بين 0 و 255
            .toInt(); // تحويل لـ int
        final b = (yValue + 1.732446 * (uValue - 128)).clamp(0, 255).toInt(); // حساب الأزرق
        out.setPixelRgb(x, y, r, g, b); // وضع البكسل RGB في الصورة
      } // نهاية حلقة x
    } // نهاية حلقة y

    return Uint8List.fromList(img.encodeJpg(out, quality: quality)); // ترميز JPEG وإرجاع النتيجة
  } // نهاية _encodeYuv420
} // نهاية CameraFrameEncoder
