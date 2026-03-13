import 'dart:convert';
import 'package:test/test.dart';
import 'package:pdf_analyzer_app/models/analysis_result.dart';
import 'package:pdf_analyzer_app/models/app_error.dart';
import 'package:pdf_analyzer_app/models/document.dart';

// MARK: - Tests
// Mirrors Swift's PDFAnalyzerAppTests.swift

void main() {
  // MARK: - AnalysisResult Tests

  group('AnalysisResult', () {
    const fullJson = '''
    {
      "keyPoints": ["nokta1", "nokta2", "nokta3"],
      "reviewTable": [
        {"concept": "kavram1", "explanation": "açıklama1"},
        {"concept": "kavram2", "explanation": "açıklama2"}
      ],
      "studyQuestions": ["soru1", "soru2"],
      "flashcards": [
        {"question": "s1", "answer": "c1"},
        {"question": "s2", "answer": "c2"}
      ]
    }
    ''';

    test('full JSON decoding', () {
      final json = jsonDecode(fullJson) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      expect(result.keyPoints, hasLength(3));
      expect(result.keyPoints[0], 'nokta1');
      expect(result.reviewTable, hasLength(2));
      expect(result.reviewTable[0].concept, 'kavram1');
      expect(result.reviewTable[0].explanation, 'açıklama1');
      expect(result.studyQuestions, hasLength(2));
      expect(result.flashcards, hasLength(2));
      expect(result.flashcards[0].question, 's1');
      expect(result.flashcards[0].answer, 'c1');
    });

    test('empty arrays decode correctly', () {
      const emptyJson = '''
      {
        "keyPoints": [],
        "reviewTable": [],
        "studyQuestions": [],
        "flashcards": []
      }
      ''';
      final json = jsonDecode(emptyJson) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      expect(result.keyPoints, isEmpty);
      expect(result.reviewTable, isEmpty);
      expect(result.studyQuestions, isEmpty);
      expect(result.flashcards, isEmpty);
    });

    test('flashcards have unique IDs', () {
      final json = jsonDecode(fullJson) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      final ids = result.flashcards.map((c) => c.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('review table rows have unique IDs', () {
      final json = jsonDecode(fullJson) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      final ids = result.reviewTable.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  // MARK: - AppError Tests

  group('AppError', () {
    test('all error messages are non-empty', () {
      final errors = [
        AppError.noAPIKey,
        AppError.noExamDocument,
        AppError.noStudyMaterials,
        AppError.pdfExtractionFailed('detail'),
        AppError.apiError('msg'),
        AppError.responseParsingFailed('detail'),
        AppError.networkError('msg'),
      ];

      for (final error in errors) {
        expect(error.message, isNotEmpty);
      }
    });

    test('error messages contain expected Turkish text', () {
      expect(AppError.noAPIKey.message, contains('API anahtarı'));
      expect(AppError.noExamDocument.message, contains('Sınav'));
      expect(AppError.noStudyMaterials.message, contains('materyali'));
    });
  });

  // MARK: - Document Tests

  group('Document', () {
    test('documents are equal by ID', () {
      const id = 'same-id';
      final doc1 = Document(id: id, name: 'Doc A', type: DocumentType.examQuestions);
      final doc2 = Document(id: id, name: 'Doc B', type: DocumentType.studyMaterial);

      expect(doc1, equals(doc2));
    });

    test('documents with different IDs are not equal', () {
      final doc1 = Document(id: 'id-1', name: 'Doc', type: DocumentType.examQuestions);
      final doc2 = Document(id: 'id-2', name: 'Doc', type: DocumentType.examQuestions);

      expect(doc1, isNot(equals(doc2)));
    });
  });

  // MARK: - GeminiService JSON Parsing Tests

  group('GeminiService JSON parsing', () {
    // Test the JSON parsing logic that GeminiService.analyze() uses internally.

    test('parse clean JSON', () {
      const jsonStr = '''
      {
        "keyPoints": ["point1"],
        "reviewTable": [{"concept": "c", "explanation": "e"}],
        "studyQuestions": ["q1"],
        "flashcards": [{"question": "q", "answer": "a"}]
      }
      ''';

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      expect(result.keyPoints, ['point1']);
      expect(result.reviewTable.first.concept, 'c');
      expect(result.studyQuestions, ['q1']);
      expect(result.flashcards.first.question, 'q');
    });

    test('parse markdown-wrapped JSON via GeminiService helper', () {
      const markdownWrapped = '''```json
{
  "keyPoints": ["point1"],
  "reviewTable": [{"concept": "c", "explanation": "e"}],
  "studyQuestions": ["q1"],
  "flashcards": [{"question": "q", "answer": "a"}]
}
```''';

      // Replicate the stripMarkdown logic from GeminiService
      var cleaned = markdownWrapped.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final result = AnalysisResult.fromJson(json);

      expect(result.keyPoints, ['point1']);
      expect(result.reviewTable.first.concept, 'c');
    });
  });
}
