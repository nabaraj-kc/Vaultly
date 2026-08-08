import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'pdf_preview_stub.dart'
    if (dart.library.html) 'pdf_preview_web.dart'
    as pdf_impl;

class PdfPreviewWidget extends StatelessWidget {
  final Uint8List bytes;
  final String filename;

  const PdfPreviewWidget({
    Key? key,
    required this.bytes,
    required this.filename,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return pdf_impl.buildPdfPreview(bytes, filename);
  }
}
