// MARK: - AppError
// Mirrors Swift's AppError enum from Sources/PDFAnalyzerAppCore/Models/AppError.swift
// All error messages are in Turkish as in the original app.

/// Custom error types used across the application.
class AppError implements Exception {
  final String message;

  const AppError._(this.message);

  /// Gemini API anahtarı girilmemiş.
  static const noAPIKey = AppError._(
    'Gemini API anahtarı girilmemiş. Lütfen Ayarlar ekranından API anahtarınızı girin.',
  );

  /// Sınav soruları belgesi yüklenmemiş.
  static const noExamDocument = AppError._(
    'Sınav soruları belgesi yüklenmemiş. Lütfen önce geçmiş sınav sorularınızı yükleyin.',
  );

  /// Çalışma materyali yüklenmemiş.
  static const noStudyMaterials = AppError._(
    'Çalışma materyali yüklenmemiş. Lütfen analiz etmek istediğiniz PDF veya slaytları yükleyin.',
  );

  /// PDF'den metin çıkarılamadı.
  factory AppError.pdfExtractionFailed(String detail) =>
      AppError._('PDF\'den metin çıkarılamadı: $detail');

  /// Gemini API hatası.
  factory AppError.apiError(String message) =>
      AppError._('Gemini API hatası: $message');

  /// API yanıtı işlenemedi.
  factory AppError.responseParsingFailed(String detail) =>
      AppError._('API yanıtı işlenemedi: $detail');

  /// Ağ hatası.
  factory AppError.networkError(String message) =>
      AppError._('Ağ hatası: $message');

  @override
  String toString() => message;
}
