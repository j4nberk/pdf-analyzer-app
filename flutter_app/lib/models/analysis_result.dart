// MARK: - Analysis Result Models
// Mirrors Swift's AnalysisResult, ReviewTableRow, Flashcard structs
// from Sources/PDFAnalyzerAppCore/Models/AnalysisResult.swift

/// The structured analysis result returned by Gemini.
class AnalysisResult {
  final List<String> keyPoints;
  final List<ReviewTableRow> reviewTable;
  final List<String> studyQuestions;
  final List<Flashcard> flashcards;

  const AnalysisResult({
    required this.keyPoints,
    required this.reviewTable,
    required this.studyQuestions,
    required this.flashcards,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      keyPoints: List<String>.from(json['keyPoints'] as List? ?? []),
      reviewTable: ((json['reviewTable'] as List?) ?? [])
          .map((e) => ReviewTableRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      studyQuestions: List<String>.from(json['studyQuestions'] as List? ?? []),
      flashcards: ((json['flashcards'] as List?) ?? [])
          .map((e) => Flashcard.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysisResult &&
          runtimeType == other.runtimeType &&
          keyPoints.toString() == other.keyPoints.toString() &&
          reviewTable.toString() == other.reviewTable.toString() &&
          studyQuestions.toString() == other.studyQuestions.toString() &&
          flashcards.toString() == other.flashcards.toString();

  @override
  int get hashCode =>
      keyPoints.hashCode ^ reviewTable.hashCode ^ studyQuestions.hashCode ^ flashcards.hashCode;
}

/// A single row in the quick review table.
class ReviewTableRow {
  final String id;
  final String concept;
  final String explanation;

  ReviewTableRow({
    String? id,
    required this.concept,
    required this.explanation,
  }) : id = id ?? _generateId();

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return 'row_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  factory ReviewTableRow.fromJson(Map<String, dynamic> json) {
    return ReviewTableRow(
      concept: json['concept'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  @override
  String toString() => 'ReviewTableRow(concept: $concept, explanation: $explanation)';
}

/// A question/answer flashcard.
class Flashcard {
  final String id;
  final String question;
  final String answer;

  Flashcard({
    String? id,
    required this.question,
    required this.answer,
  }) : id = id ?? _generateId();

  static int _idCounter = 0;

  static String _generateId() {
    _idCounter++;
    return 'card_${DateTime.now().millisecondsSinceEpoch}_$_idCounter';
  }

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }

  @override
  String toString() => 'Flashcard(question: $question, answer: $answer)';
}
