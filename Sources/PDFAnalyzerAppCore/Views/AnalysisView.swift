import SwiftUI

struct AnalysisView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: AnalysisSectionTab = .flashcards

    var body: some View {
        ZStack {
            StudySmartBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    topBar

                    tabPicker

                    selectedContent

                    Color.clear
                        .frame(height: 32)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private var topBar: some View {
        StudySmartTopBar(
            title: "StudySmart",
            leading: {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(StudySmartPalette.textPrimary)
                }
                .buttonStyle(.plain)
            },
            trailing: {
                ShareButton()
            }
        )
    }

    private var tabPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(AnalysisSectionTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            selectedTab = tab
                        }
                    } label: {
                        StudySmartTabPill(tab: tab, isSelected: selectedTab == tab)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch selectedTab {
        case .keyPoints:
            KeyPointsView()
        case .reviewTables:
            ReviewTableView()
        case .studyQuestions:
            StudyQuestionsView()
        case .flashcards:
            FlashcardsView()
        }
    }
}

private struct ShareButton: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        if let result = viewModel.analysisResult {
            ShareLink(item: buildShareText(result: result)) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(StudySmartPalette.textPrimary)
            }
        }
    }

    private func buildShareText(result: AnalysisResult) -> String {
        var lines: [String] = []

        lines.append("STUDYSMART ANALYSIS")
        lines.append(String(repeating: "=", count: 32))

        lines.append("\nKEY POINTS")
        for (index, point) in result.keyPoints.enumerated() {
            lines.append("\(index + 1). \(point)")
        }

        lines.append("\nREVIEW TABLE")
        for row in result.reviewTable {
            lines.append("• \(row.concept): \(row.explanation)")
        }

        lines.append("\nSTUDY QUESTIONS")
        for (index, question) in result.studyQuestions.enumerated() {
            lines.append("\(index + 1). \(question)")
        }

        lines.append("\nFLASHCARDS")
        for (index, card) in result.flashcards.enumerated() {
            lines.append("Q\(index + 1): \(card.question)")
            lines.append("A\(index + 1): \(card.answer)")
        }

        return lines.joined(separator: "\n")
    }
}
