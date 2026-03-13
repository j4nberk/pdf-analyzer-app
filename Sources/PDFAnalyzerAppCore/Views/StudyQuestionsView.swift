import SwiftUI

struct StudyQuestionsView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if let result = viewModel.analysisResult {
                if result.studyQuestions.isEmpty {
                    EmptyResultView(
                        icon: "questionmark.circle.fill",
                        title: "No study questions generated",
                        subtitle: "Try adding richer lecture material and rerun the analysis."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        StudySmartCard {
                            HStack {
                                Label("\(result.studyQuestions.count) prompts ready", systemImage: "brain")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(StudySmartPalette.textPrimary)
                                Spacer()
                                Text("Answer before checking notes")
                                    .font(.caption)
                                    .foregroundStyle(StudySmartPalette.textMuted)
                            }
                        }

                        ForEach(Array(result.studyQuestions.enumerated()), id: \.offset) { index, question in
                            StudyQuestionRow(index: index + 1, question: question)
                        }
                    }
                }
            } else {
                EmptyResultView(
                    icon: "sparkles",
                    title: "Analysis not ready",
                    subtitle: "This section fills with self-test questions after Gemini finishes."
                )
            }
        }
    }
}

private struct StudyQuestionRow: View {
    let index: Int
    let question: String

    var body: some View {
        StudySmartCard {
            HStack(alignment: .top, spacing: 14) {
                Text("\(index)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .frame(width: 34, height: 34)
                    .background(StudySmartPalette.tertiary, in: Circle())

                Text(question)
                    .font(.body)
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
