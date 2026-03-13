import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private func copyToClipboard(_ text: String) {
#if canImport(UIKit)
    UIPasteboard.general.string = text
#elseif canImport(AppKit)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
#endif
}

struct KeyPointsView: View {
    @EnvironmentObject var viewModel: AppViewModel

    var body: some View {
        Group {
            if let result = viewModel.analysisResult {
                if result.keyPoints.isEmpty {
                    EmptyResultView(
                        icon: "star.fill",
                        title: "No key points generated",
                        subtitle: "Try running the analysis again with more complete course material."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        StudySmartCard {
                            HStack {
                                Label("\(result.keyPoints.count) key insights", systemImage: "sparkles")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(StudySmartPalette.textPrimary)
                                Spacer()
                                Text("Long press to copy")
                                    .font(.caption)
                                    .foregroundStyle(StudySmartPalette.textMuted)
                            }
                        }

                        ForEach(Array(result.keyPoints.enumerated()), id: \.offset) { index, point in
                            KeyPointRow(index: index + 1, text: point)
                        }
                    }
                }
            } else {
                EmptyResultView(
                    icon: "sparkles",
                    title: "Analysis not ready",
                    subtitle: "Upload your PDFs and run Gemini to populate this section."
                )
            }
        }
    }
}

private struct KeyPointRow: View {
    let index: Int
    let text: String
    @State private var isCopied = false

    var body: some View {
        StudySmartCard {
            HStack(alignment: .top, spacing: 14) {
                Text("\(index)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.72))
                    .frame(width: 34, height: 34)
                    .background(StudySmartPalette.primary, in: Circle())

                Text(text)
                    .font(.body)
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isCopied {
                    Text("Copied")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.black.opacity(0.72))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(StudySmartPalette.success, in: Capsule(style: .continuous))
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture {
            copyToClipboard(text)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isCopied = false
                }
            }
        }
    }
}
