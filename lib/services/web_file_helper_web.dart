import 'dart:html' as html;
import 'dart:typed_data';

void downloadPdfFile(Uint8List bytes, String filename) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    Future.delayed(const Duration(minutes: 1), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (e) {
    // Fallback if Blob download fails
    final base64Data = Uri.dataFromBytes(bytes, mimeType: 'application/pdf').toString();
    final anchor = html.AnchorElement(href: base64Data)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
  }
}

void openPdfInNewTab(Uint8List bytes) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(minutes: 5), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (_) {}
}

void openUrlInNewTab(String url) {
  try {
    html.window.open(url, '_blank');
  } catch (_) {}
}

void saveLessonToWebStorage(String title, String content) {
  try {
    html.window.localStorage['metodist_current_lesson_title'] = title;
    html.window.localStorage['metodist_current_lesson_content'] = content;
  } catch (_) {}
}
