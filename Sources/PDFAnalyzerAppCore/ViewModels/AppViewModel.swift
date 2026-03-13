import SwiftUI
import Combine

// MARK: - AppViewModel

@MainActor
public final class AppViewModel: ObservableObject {

    // MARK: Documents
    @Published var examQuestionsDocument: Document?
    @Published var studyMaterials: [Document] = []

    // MARK: Analysis
    @Published var analysisResult: AnalysisResult?
    @Published var isAnalyzing = false
    @Published var analysisError: String?

    // MARK: Settings
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: "geminiAPIKey") }
    }
    @Published var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "geminiModel") }
    }

    // MARK: Services
    private let geminiService = GeminiService()
    private let pdfService = PDFService()

    // MARK: Available models
    let availableModels: [String] = [
        "gemini-3.1-flash",
        "gemini-3.1-pro",
        "gemini-3.1-flash-lite",
        "gemini-3.1-flash-image"
    ]

    public init() {
        apiKey = UserDefaults.standard.string(forKey: "geminiAPIKey") ?? ""
        selectedModel = UserDefaults.standard.string(forKey: "geminiModel") ?? "gemini-3.1-flash"
    }

    // MARK: - Document management

    /// Loads a PDF from a security-scoped URL and adds it as the exam questions document.
    func loadExamQuestionsDocument(from url: URL) {
        analysisError = nil
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let text = try pdfService.extractText(from: url)
            examQuestionsDocument = Document(
                name: url.deletingPathExtension().lastPathComponent,
                url: url,
                extractedText: text,
                type: .examQuestions
            )
        } catch {
            analysisError = error.localizedDescription
        }
    }

    /// Loads a PDF from a security-scoped URL and appends it to study materials.
    func addStudyMaterial(from url: URL) {
        analysisError = nil
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }

        do {
            let text = try pdfService.extractText(from: url)
            let doc = Document(
                name: url.deletingPathExtension().lastPathComponent,
                url: url,
                extractedText: text,
                type: .studyMaterial
            )
            studyMaterials.append(doc)
        } catch {
            analysisError = error.localizedDescription
        }
    }

    /// Removes a study material at the given offsets.
    func removeStudyMaterials(at offsets: IndexSet) {
        studyMaterials.remove(atOffsets: offsets)
    }

    // MARK: - Analysis

    var canAnalyze: Bool {
        examQuestionsDocument != nil && !studyMaterials.isEmpty && !isAnalyzing
    }

    /// Sends documents to Gemini for analysis and stores the result.
    func analyze() async {
        guard let examDoc = examQuestionsDocument else {
            analysisError = AppError.noExamDocument.localizedDescription
            return
        }
        guard !studyMaterials.isEmpty else {
            analysisError = AppError.noStudyMaterials.localizedDescription
            return
        }
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            analysisError = AppError.noAPIKey.localizedDescription
            return
        }

        isAnalyzing = true
        analysisError = nil
        analysisResult = nil

        let combinedStudyText = studyMaterials
            .map { "=== \($0.name) ===\n\($0.extractedText)" }
            .joined(separator: "\n\n")

        do {
            let result = try await geminiService.analyze(
                examQuestionsText: examDoc.extractedText,
                studyMaterialText: combinedStudyText,
                apiKey: apiKey,
                model: selectedModel
            )
            analysisResult = result
        } catch {
            analysisError = error.localizedDescription
        }

        isAnalyzing = false
    }

    /// Clears the current analysis result.
    func clearAnalysis() {
        analysisResult = nil
        analysisError = nil
    }

    /// Clears all loaded documents and results.
    func clearAll() {
        examQuestionsDocument = nil
        studyMaterials = []
        analysisResult = nil
        analysisError = nil
    }
}
