import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/app_error.dart';

// MARK: - PDFService
// Mirrors Swift's PDFService from Sources/PDFAnalyzerAppCore/Services/PDFService.swift
// Extracts plain text from PDF files using Syncfusion Flutter PDF (null-safe,
// supports both Android and iOS natively).

class PDFService {
  /// Extracts all text from the PDF at the given file path.
  ///
  /// Throws [AppError] if the PDF cannot be read or yields no text.
  Future<String> extractText(String filePath) async {
    final File file = File(filePath);

    final List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      throw AppError.pdfExtractionFailed('Belge okunamadı: $e');
    }

    final PdfDocument doc;
    try {
      doc = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw AppError.pdfExtractionFailed('PDF açılamadı: $e');
    }

    if (doc.pages.count == 0) {
      doc.dispose();
      throw AppError.pdfExtractionFailed('PDF hiç sayfa içermiyor');
    }

    final buffer = StringBuffer();
    try {
      final PdfTextExtractor extractor = PdfTextExtractor(doc);
      for (var i = 0; i < doc.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.trim().isNotEmpty) {
          buffer.writeln(pageText);
        }
      }
    } catch (e) {
      doc.dispose();
      throw AppError.pdfExtractionFailed('Metin çıkarılamadı: $e');
    } finally {
      doc.dispose();
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      throw AppError.pdfExtractionFailed(
        'PDF\'den metin çıkarılamadı. Belge yalnızca görüntü veya taranmış içerik içeriyor olabilir.',
      );
    }

    return text;
  }
}
