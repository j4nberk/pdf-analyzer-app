import Foundation

// MARK: - Gemini API types

private struct GeminiRequest: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig

    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String
    }

    struct GenerationConfig: Encodable {
        let responseMimeType: String
        let temperature: Double
        let maxOutputTokens: Int
    }
}

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?
    let error: APIError?

    struct Candidate: Decodable {
        let content: Content
        let finishReason: String?
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let text: String
    }

    struct APIError: Decodable {
        let code: Int
        let message: String
        let status: String
    }
}

// MARK: - GeminiService

/// Sends requests to the Google Gemini REST API and returns structured analysis results.
struct GeminiService {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Analyzes the study material against past exam questions and returns a structured result.
    /// - Parameters:
    ///   - examQuestionsText: Plain text extracted from the past exam questions document.
    ///   - studyMaterialText: Plain text extracted from the study material documents.
    ///   - apiKey: The Gemini API key.
    ///   - model: The Gemini model identifier (default: `gemini-3.1-flash`).
    func analyze(
        examQuestionsText: String,
        studyMaterialText: String,
        apiKey: String,
        model: String = "gemini-3.1-flash"
    ) async throws -> AnalysisResult {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AppError.noAPIKey
        }

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw AppError.apiError("Geçersiz API URL'si")
        }

        let prompt = buildPrompt(examQuestionsText: examQuestionsText, studyMaterialText: studyMaterialText)

        let requestBody = GeminiRequest(
            contents: [
                GeminiRequest.Content(parts: [GeminiRequest.Part(text: prompt)])
            ],
            generationConfig: GeminiRequest.GenerationConfig(
                responseMimeType: "application/json",
                temperature: 0.3,
                maxOutputTokens: 8192
            )
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("PDFAnalyzerApp/1.0", forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AppError.networkError(error.localizedDescription)
        }

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            // Try to parse the Gemini error body
            if let geminiResponse = try? JSONDecoder().decode(GeminiResponse.self, from: data),
               let apiErr = geminiResponse.error {
                throw AppError.apiError("\(apiErr.message) (kod: \(apiErr.code))")
            }
            throw AppError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        if let apiErr = geminiResponse.error {
            throw AppError.apiError("\(apiErr.message) (kod: \(apiErr.code))")
        }

        guard let candidateText = geminiResponse.candidates?.first?.content.parts.first?.text else {
            throw AppError.responseParsingFailed("Yanıt içeriği boş")
        }

        return try parseAnalysisResult(from: candidateText)
    }

    // MARK: - Prompt

    private func buildPrompt(examQuestionsText: String, studyMaterialText: String) -> String {
        // Limit texts to avoid exceeding token limits while keeping most relevant content
        let maxChars = 30_000
        let trimmedExam = String(examQuestionsText.prefix(maxChars))
        let trimmedMaterial = String(studyMaterialText.prefix(maxChars))

        return """
        Sen deneyimli bir eğitim asistanısın. Sana iki belge veriyorum:

        1. Geçmiş Sınav Soruları Belgesi - Öğrencinin daha önce gördüğü veya çıkmış sınav soruları
        2. Çalışma Materyali - Ders notları, slaytlar veya ders kitabı içeriği

        ---
        GEÇMİŞ SINAV SORULARI:
        \(trimmedExam)
        ---
        ÇALIŞMA MATERYALİ:
        \(trimmedMaterial)
        ---

        Bu iki belgeyi analiz ederek aşağıdakileri oluştur:

        1. **keyPoints**: Geçmiş sınav soruları göz önüne alındığında çalışma materyalindeki en önemli 15 nokta. Her nokta kısa, net ve öğrencinin sınavda işine yarayacak bilgi içermeli.

        2. **reviewTable**: Anahtar kavramları ve açıklamalarını içeren hızlı tekrar tablosu. En az 10, en fazla 15 satır. Her satırda "concept" (kavram/terim) ve "explanation" (kısa açıklama) olmalı.

        3. **studyQuestions**: Çalışma materyaline ve geçmiş sınav sorularının tarzına dayalı 10 özgün çalışma sorusu. Sorular öğrenciyi düşündürmeli ve konuyu pekiştirmeli.

        4. **flashcards**: Etkili ezberleme için 10 flaşkart. Her flaşkartta "question" (kısa, net bir soru) ve "answer" (özlü bir cevap) olmalı.

        YALNIZCA aşağıdaki JSON formatında yanıt ver, başka hiçbir metin ekleme:
        {
          "keyPoints": ["nokta1", "nokta2", "..."],
          "reviewTable": [
            {"concept": "kavram", "explanation": "açıklama"},
            "..."
          ],
          "studyQuestions": ["soru1", "soru2", "..."],
          "flashcards": [
            {"question": "soru", "answer": "cevap"},
            "..."
          ]
        }
        """
    }

    // MARK: - Response parsing

    private func parseAnalysisResult(from text: String) throws -> AnalysisResult {
        // Gemini sometimes wraps JSON in markdown code fences — strip them
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst(7))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst(3))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast(3))
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AppError.responseParsingFailed("Metin UTF-8'e dönüştürülemedi")
        }

        do {
            let result = try JSONDecoder().decode(AnalysisResult.self, from: jsonData)
            return result
        } catch {
            throw AppError.responseParsingFailed(error.localizedDescription)
        }
    }
}
