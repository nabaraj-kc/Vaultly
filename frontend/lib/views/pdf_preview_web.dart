import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:typed_data';

Widget buildPdfPreview(Uint8List bytes, String filename) {
  // Create a Blob from the raw file bytes in memory
  final blob = html.Blob([bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  // Register a unique view factory ID for this document
  final viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}-${bytes.length}';
  
  ui_web.platformViewRegistry.registerViewFactory(viewId, (int viewId) {
    final iframe = html.IFrameElement()
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';
    return iframe;
  });
  
  return SizedBox(
    width: double.infinity,
    height: 600, // Visual viewport height
    child: HtmlElementView(viewType: viewId),
  );
}
