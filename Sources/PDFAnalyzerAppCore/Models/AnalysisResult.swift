import Foundation

// MARK: - Top-level result

/// The structured analysis result returned by Gemini.
struct AnalysisResult: Codable, Equatable {
    var keyPoints: [String]
    var reviewTable: [ReviewTableRow]
    var studyQuestions: [String]
    var flashcards: [Flashcard]
}

// MARK: - Review table row

/// A single row in the quick review table.
struct ReviewTableRow: Codable, Identifiable, Equatable {
    var id: UUID
    var concept: String
    var explanation: String

    init(id: UUID = UUID(), concept: String, explanation: String) {
        self.id = id
        self.concept = concept
        self.explanation = explanation
    }

    enum CodingKeys: String, CodingKey {
        case concept, explanation
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.concept = try container.decode(String.self, forKey: .concept)
        self.explanation = try container.decode(String.self, forKey: .explanation)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(concept, forKey: .concept)
        try container.encode(explanation, forKey: .explanation)
    }
}

// MARK: - Flashcard

/// A question/answer flashcard.
struct Flashcard: Codable, Identifiable, Equatable {
    var id: UUID
    var question: String
    var answer: String

    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }

    enum CodingKeys: String, CodingKey {
        case question, answer
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.question = try container.decode(String.self, forKey: .question)
        self.answer = try container.decode(String.self, forKey: .answer)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(question, forKey: .question)
        try container.encode(answer, forKey: .answer)
    }
}
