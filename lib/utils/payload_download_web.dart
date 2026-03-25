import 'dart:convert';
import 'dart:html' as html;

void downloadJsonPayload({required String fileName, required String jsonContent}) {
  final bytes = utf8.encode(jsonContent);
  final blob = html.Blob(<dynamic>[bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
