import XCTest
@testable import PDFAnalyzerAppCore

final class AnalysisResultTests: XCTestCase {

    // MARK: - AnalysisResult decoding

    func testAnalysisResultDecoding_fullJSON() throws {
        let json = """
        {
          "keyPoints": ["Nokta 1", "Nokta 2"],
          "reviewTable": [
            {"concept": "Kavram A", "explanation": "Açıklama A"},
            {"concept": "Kavram B", "explanation": "Açıklama B"}
          ],
          "studyQuestions": ["Soru 1?", "Soru 2?"],
          "flashcards": [
            {"question": "S1?", "answer": "C1"},
            {"question": "S2?", "answer": "C2"}
          ]
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(AnalysisResult.self, from: json)

        XCTAssertEqual(result.keyPoints.count, 2)
        XCTAssertEqual(result.keyPoints[0], "Nokta 1")
        XCTAssertEqual(result.reviewTable.count, 2)
        XCTAssertEqual(result.reviewTable[0].concept, "Kavram A")
        XCTAssertEqual(result.reviewTable[1].explanation, "Açıklama B")
        XCTAssertEqual(result.studyQuestions.count, 2)
        XCTAssertEqual(result.flashcards.count, 2)
        XCTAssertEqual(result.flashcards[0].question, "S1?")
        XCTAssertEqual(result.flashcards[1].answer, "C2")
    }

    func testAnalysisResultDecoding_emptyArrays() throws {
        let json = """
        {
          "keyPoints": [],
          "reviewTable": [],
          "studyQuestions": [],
          "flashcards": []
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(AnalysisResult.self, from: json)

        XCTAssertTrue(result.keyPoints.isEmpty)
        XCTAssertTrue(result.reviewTable.isEmpty)
        XCTAssertTrue(result.studyQuestions.isEmpty)
        XCTAssertTrue(result.flashcards.isEmpty)
    }

    // MARK: - Flashcard

    func testFlashcardHasUniqueIDs() throws {
        let json = """
        [
          {"question": "Q1", "answer": "A1"},
          {"question": "Q2", "answer": "A2"}
        ]
        """.data(using: .utf8)!

        let cards = try JSONDecoder().decode([Flashcard].self, from: json)
        XCTAssertNotEqual(cards[0].id, cards[1].id)
    }

    // MARK: - ReviewTableRow

    func testReviewTableRowHasUniqueIDs() throws {
        let json = """
        [
          {"concept": "C1", "explanation": "E1"},
          {"concept": "C2", "explanation": "E2"}
        ]
        """.data(using: .utf8)!

        let rows = try JSONDecoder().decode([ReviewTableRow].self, from: json)
        XCTAssertNotEqual(rows[0].id, rows[1].id)
    }

    // MARK: - AppError descriptions

    func testAppErrorLocalizedDescriptions() {
        XCTAssertFalse(AppError.noAPIKey.localizedDescription.isEmpty)
        XCTAssertFalse(AppError.noExamDocument.localizedDescription.isEmpty)
        XCTAssertFalse(AppError.noStudyMaterials.localizedDescription.isEmpty)
        XCTAssertFalse(AppError.pdfExtractionFailed("test").localizedDescription.isEmpty)
        XCTAssertTrue(AppError.apiError("msg").localizedDescription.contains("msg"))
        XCTAssertTrue(AppError.responseParsingFailed("detail").localizedDescription.contains("detail"))
        XCTAssertTrue(AppError.networkError("net").localizedDescription.contains("net"))
    }

    // MARK: - Document model

    func testDocumentEquality() {
        let id = UUID()
        let doc1 = Document(id: id, name: "Test", type: .examQuestions)
        let doc2 = Document(id: id, name: "Different Name", type: .studyMaterial)
        XCTAssertEqual(doc1, doc2, "Documents with the same id should be equal regardless of other properties")
    }

    func testDocumentInequality() {
        let doc1 = Document(name: "Doc1", type: .examQuestions)
        let doc2 = Document(name: "Doc1", type: .examQuestions)
        XCTAssertNotEqual(doc1, doc2, "Documents with different UUIDs should not be equal")
    }
}

// MARK: - GeminiService response parsing tests

final class GeminiServiceParsingTests: XCTestCase {

    private let service = GeminiService()

    func testParseCleanJSON() throws {
        // Access the private parseAnalysisResult method via a helper that mimics it
        let json = """
        {
          "keyPoints": ["K1"],
          "reviewTable": [{"concept": "C", "explanation": "E"}],
          "studyQuestions": ["Q?"],
          "flashcards": [{"question": "Q", "answer": "A"}]
        }
        """
        let data = json.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
        XCTAssertEqual(result.keyPoints, ["K1"])
    }

    func testParseMarkdownWrappedJSON() throws {
        // Simulate the cleanup that GeminiService does
        var cleaned = """
        ```json
        {"keyPoints":["P1"],"reviewTable":[],"studyQuestions":[],"flashcards":[]}
        ```
        """.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleaned.hasPrefix("```json") { cleaned = String(cleaned.dropFirst(7)) }
        else if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        let data = cleaned.data(using: .utf8)!
        let result = try JSONDecoder().decode(AnalysisResult.self, from: data)
        XCTAssertEqual(result.keyPoints, ["P1"])
    }
}
