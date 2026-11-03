import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fapcheckin_core/result/guard.dart';

/// Android ML Kit with the Latin model bundled in the APK. No upload occurs.
class TimetableOcrService {
  static const channel = MethodChannel('fapcheckin/ocr');

  Future<String> recognize(Uint8List bytes) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw ApiException(
        'OCR_UNSUPPORTED',
        'Quét ảnh offline hiện hỗ trợ Android.',
      );
    }
    try {
      return await channel.invokeMethod<String>('recognize', {
            'bytes': bytes,
          }) ??
          '';
    } on PlatformException catch (e) {
      throw ApiException(e.code, e.message ?? 'Không thể đọc ảnh.');
    } on MissingPluginException {
      throw ApiException(
        'OCR_UNAVAILABLE',
        'Hãy cài lại bản Android mới để sử dụng OCR.',
      );
    }
  }
}
