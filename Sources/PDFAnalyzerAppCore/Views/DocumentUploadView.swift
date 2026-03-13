import SwiftUI
import UniformTypeIdentifiers

struct DocumentUploadView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var showingResults: Bool

    let openSettings: () -> Void

    @State private var showingExamPicker = false
    @State private var showingStudyPicker = false
    @State private var previewTab: AnalysisSectionTab = .flashcards

    private let pdfType = UTType.pdf
    private let librarySectionID = "library-section"
    private let analyzeSectionID = "analyze-section"
    private let resultsSectionID = "results-section"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    topBar

                    uploadSection
                        .id(librarySectionID)

                    analyzeSection
                        .id(analyzeSectionID)

                    if let error = viewModel.analysisError {
                        errorCard(error)
                    }

                    resultsPreviewSection
                        .id(resultsSectionID)

                    Color.clear
                        .frame(height: 110)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                StudySmartDock(items: dockItems(proxy: proxy))
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    .background(Color.clear)
            }
        }
        .fileImporter(
            isPresented: $showingExamPicker,
            allowedContentTypes: [pdfType],
            allowsMultipleSelection: false
        ) { result in
            handlePickedFile(result: result, isExam: true)
        }
        .fileImporter(
            isPresented: $showingStudyPicker,
            allowedContentTypes: [pdfType],
            allowsMultipleSelection: true
        ) { result in
            handlePickedFile(result: result, isExam: false)
        }
        .onChange(of: viewModel.analysisResult) { _, newValue in
            if newValue != nil {
                previewTab = .flashcards
            }
        }
    }

    private var topBar: some View {
        StudySmartTopBar(
            title: "StudySmart",
            leading: {
                Image(systemName: "line.3.horizontal")
                    .foregroundStyle(StudySmartPalette.textPrimary)
            },
            trailing: {
                Button(action: openSettings) {
                    Image(systemName: "gearshape")
                        .foregroundStyle(StudySmartPalette.textPrimary)
                }
                .buttonStyle(.plain)
            }
        )
    }

    private var uploadSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudySmartSectionHeader(
                eyebrow: "Upload",
                title: "Build your study context",
                subtitle: "Past exams guide the model, current PDFs supply the course material."
            )

            UploadSourceCard(
                accent: StudySmartPalette.primary,
                icon: "text.badge.checkmark",
                title: "Source of Truth: Upload Past Exams",
                subtitle: "Train the model on your previous assessments.",
                trailingIcon: viewModel.examQuestionsDocument == nil ? "plus.circle.fill" : "checkmark.circle.fill",
                action: { showingExamPicker = true }
            ) {
                if let document = viewModel.examQuestionsDocument {
                    DocumentStatusRow(
                        document: document,
                        tint: StudySmartPalette.primary,
                        subtitle: "\(wordCount(for: document.extractedText)) words extracted"
                    ) {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            viewModel.examQuestionsDocument = nil
                            viewModel.clearAnalysis()
                        }
                    }
                } else {
                    UploadHint(text: "Add one reference PDF with old exams, quizzes, or practice sheets.")
                }
            }

            UploadSourceCard(
                accent: StudySmartPalette.secondary,
                icon: "doc.richtext.fill",
                title: "Current Material: Upload Lecture Slides/PDFs",
                subtitle: "Add your latest study materials for synthesis.",
                trailingIcon: "icloud.and.arrow.up.fill",
                action: { showingStudyPicker = true }
            ) {
                if viewModel.studyMaterials.isEmpty {
                    UploadHint(text: "You can add multiple lecture decks, notes, or supporting PDFs.")
                } else {
                    VStack(spacing: 10) {
                        ForEach(viewModel.studyMaterials) { document in
                            DocumentStatusRow(
                                document: document,
                                tint: StudySmartPalette.secondary,
                                subtitle: "\(wordCount(for: document.extractedText)) words"
                            ) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                    viewModel.studyMaterials.removeAll { $0.id == document.id }
                                    viewModel.clearAnalysis()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var analyzeSection: some View {
        VStack(spacing: 16) {
            StudySmartSectionHeader(
                eyebrow: "Analyze",
                title: "Run Gemini on your PDFs",
                subtitle: viewModel.apiKey.isEmpty
                    ? "Gemini API key is missing. Add it from Settings before analyzing."
                    : "When ready, generate summaries, review tables, study questions, and flashcards."
            )

            StudySmartActionButton(
                title: viewModel.isAnalyzing ? "Analyzing with Gemini API" : "Analyze with Gemini API",
                systemImage: "sparkles",
                isEnabled: viewModel.canAnalyze,
                isLoading: viewModel.isAnalyzing
            ) {
                Task {
                    await viewModel.analyze()
                }
            }

            if viewModel.analysisResult != nil {
                Button {
                    showingResults = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Open full analysis")
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(StudySmartPalette.surface, in: Capsule(style: .continuous))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var resultsPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            StudySmartSectionHeader(
                eyebrow: "Results",
                title: "Review what the model generated",
                subtitle: "Browse the same content groups shown in the design and jump into the detailed analysis view."
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AnalysisSectionTab.allCases) { tab in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                previewTab = tab
                            }
                        } label: {
                            StudySmartTabPill(tab: tab, isSelected: previewTab == tab)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 1)
            }

            Group {
                if let result = viewModel.analysisResult {
                    previewCard(result: result)
                } else {
                    StudySmartEmptyCard(
                        icon: "sparkles.rectangle.stack.fill",
                        title: "Analysis preview will appear here",
                        subtitle: "Upload both document types and run Gemini to unlock the flashcard-style results area."
                    )
                }
            }
        }
    }

    private func previewCard(result: AnalysisResult) -> some View {
        StudySmartCard(cornerRadius: 30) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(metricsTitle(for: previewTab))
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(StudySmartPalette.primary)

                        Capsule(style: .continuous)
                            .fill(StudySmartPalette.primary)
                            .frame(width: 42, height: 4)
                    }

                    Spacer()

                    Button {
                        showingResults = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundStyle(StudySmartPalette.textPrimary)
                            .padding(12)
                            .background(StudySmartPalette.surfaceStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

                previewBody(for: result)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 14) {
                    ResultMetricBadge(
                        icon: "star.fill",
                        value: "\(result.keyPoints.count)",
                        label: "Key points"
                    )

                    ResultMetricBadge(
                        icon: "questionmark.circle.fill",
                        value: "\(result.studyQuestions.count)",
                        label: "Questions"
                    )

                    ResultMetricBadge(
                        icon: "rectangle.stack.fill",
                        value: "\(result.flashcards.count)",
                        label: "Cards"
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func previewBody(for result: AnalysisResult) -> some View {
        switch previewTab {
        case .keyPoints:
            VStack(alignment: .leading, spacing: 12) {
                Text("Top concepts to remember")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(StudySmartPalette.textPrimary)

                ForEach(Array(result.keyPoints.prefix(3).enumerated()), id: \.offset) { index, point in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color.black.opacity(0.72))
                            .frame(width: 24, height: 24)
                            .background(StudySmartPalette.primary, in: Circle())

                        Text(point)
                            .font(.subheadline)
                            .foregroundStyle(StudySmartPalette.textSecondary)
                    }
                }
            }

        case .reviewTables:
            VStack(alignment: .leading, spacing: 14) {
                Text(result.reviewTable.first?.concept ?? "Review table")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(StudySmartPalette.textPrimary)

                Text(result.reviewTable.first?.explanation ?? "Once analysis is available, the leading review concept appears here.")
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textSecondary)

                if result.reviewTable.count > 1 {
                    Text("+\(result.reviewTable.count - 1) more concepts ready for revision")
                        .font(.caption)
                        .foregroundStyle(StudySmartPalette.textMuted)
                }
            }

        case .studyQuestions:
            VStack(alignment: .leading, spacing: 14) {
                Text("Self-test prompt")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(StudySmartPalette.secondary)

                Text(result.studyQuestions.first ?? "Your generated study questions will appear here.")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(StudySmartPalette.textPrimary)

                Text("Use these prompts before looking back at your notes.")
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textSecondary)
            }

        case .flashcards:
            VStack(alignment: .center, spacing: 16) {
                Text(result.flashcards.first.map { $0.question } ?? "Flashcards will appear here.")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text("Tap to reveal in the full flashcard view")
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textSecondary)
            }
            .frame(minHeight: 180)
        }
    }

    private func metricsTitle(for tab: AnalysisSectionTab) -> String {
        switch tab {
        case .keyPoints:
            return "KEY POINTS"
        case .reviewTables:
            return "REVIEW TABLES"
        case .studyQuestions:
            return "STUDY QUESTIONS"
        case .flashcards:
            return "FLASHCARDS"
        }
    }

    private func errorCard(_ error: String) -> some View {
        StudySmartCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(StudySmartPalette.warning)
                    .font(.title3)

                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func dockItems(proxy: ScrollViewProxy) -> [StudySmartDockItem] {
        [
            StudySmartDockItem(
                title: "Library",
                systemImage: "folder.fill",
                isSelected: false
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(librarySectionID, anchor: .top)
                }
            },
            StudySmartDockItem(
                title: "Analyze",
                systemImage: "sparkles",
                isSelected: viewModel.analysisResult == nil
            ) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(analyzeSectionID, anchor: .center)
                }
            },
            StudySmartDockItem(
                title: "Flashcards",
                systemImage: "rectangle.stack.fill",
                isSelected: viewModel.analysisResult != nil && previewTab == .flashcards
            ) {
                previewTab = .flashcards
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    proxy.scrollTo(resultsSectionID, anchor: .center)
                }
            },
            StudySmartDockItem(
                title: "Settings",
                systemImage: "gearshape.fill",
                isSelected: false
            ) {
                openSettings()
            }
        ]
    }

    private func wordCount(for text: String) -> Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    private func handlePickedFile(result: Result<[URL], Error>, isExam: Bool) {
        switch result {
        case .success(let urls):
            for url in urls {
                if isExam {
                    viewModel.loadExamQuestionsDocument(from: url)
                } else {
                    viewModel.addStudyMaterial(from: url)
                }
            }
        case .failure(let error):
            viewModel.analysisError = "Dosya seçme hatası: \(error.localizedDescription)"
        }
    }
}

private struct UploadSourceCard<Content: View>: View {
    let accent: Color
    let icon: String
    let title: String
    let subtitle: String
    let trailingIcon: String
    let action: () -> Void
    let content: Content

    init(
        accent: Color,
        icon: String,
        title: String,
        subtitle: String,
        trailingIcon: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.accent = accent
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.trailingIcon = trailingIcon
        self.action = action
        self.content = content()
    }

    var body: some View {
        StudySmartCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(accent)
                        .frame(width: 48, height: 48)
                        .background(accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer()

                    Image(systemName: trailingIcon)
                        .font(.headline)
                        .foregroundStyle(StudySmartPalette.textMuted)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(StudySmartPalette.textPrimary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(StudySmartPalette.textSecondary)
                        .multilineTextAlignment(.leading)
                }

                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

private struct UploadHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(StudySmartPalette.textMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
    }
}

private struct DocumentStatusRow: View {
    let document: Document
    let tint: Color
    let subtitle: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(StudySmartPalette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(document.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(StudySmartPalette.textMuted)
            }

            Spacer()

            Button(role: .destructive, action: remove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(StudySmartPalette.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(StudySmartPalette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ResultMetricBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(StudySmartPalette.primary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(StudySmartPalette.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundStyle(StudySmartPalette.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(StudySmartPalette.surface, in: Capsule(style: .continuous))
    }
}
