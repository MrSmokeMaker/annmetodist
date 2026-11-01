import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'web_file_helper_stub.dart'
    if (dart.library.html) 'web_file_helper_web.dart' as platform;

class WebFileHelper {
  static void downloadPdf(Uint8List bytes, String filename) {
    if (kIsWeb) {
      platform.downloadPdfFile(bytes, filename);
    }
  }

  static void previewPdf(Uint8List bytes) {
    if (kIsWeb) {
      platform.openPdfInNewTab(bytes);
    }
  }

  static void openUrl(String url) {
    if (kIsWeb) {
      platform.openUrlInNewTab(url);
    }
  }

  static void saveLessonForEditor(String title, String content) {
    if (kIsWeb) {
      platform.saveLessonToWebStorage(title, content);
    }
  }
}
