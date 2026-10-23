import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<String> downloadHistory(
  String filename,
  String base64,
  String mimeType,
) async {
  final blob = web.Blob(
    [base64Decode(base64).toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  return 'Đã yêu cầu tải $filename';
}
