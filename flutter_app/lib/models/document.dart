// MARK: - Document Model
// Mirrors Swift's Document struct in Sources/PDFAnalyzerAppCore/Models/Document.swift

/// Represents an uploaded document (PDF) within the app.
class Document {
  final String id;
  String name;
  String extractedText;
  DocumentType type;

  Document({
    required this.id,
    required this.name,
    this.extractedText = '',
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Document && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// The type of document loaded by the user.
enum DocumentType {
  /// The reference "past exam questions" document.
  examQuestions,

  /// A study material document (lecture slides, notes, etc.).
  studyMaterial,
}
