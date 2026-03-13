import SwiftUI

struct ReviewTableView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var searchText = ""

    private var filteredRows: [ReviewTableRow] {
        guard let result = viewModel.analysisResult else { return [] }
        if searchText.isEmpty { return result.reviewTable }
        return result.reviewTable.filter {
            $0.concept.localizedCaseInsensitiveContains(searchText) ||
            $0.explanation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        Group {
            if let result = viewModel.analysisResult {
                if result.reviewTable.isEmpty {
                    EmptyResultView(
                        icon: "tablecells.fill",
                        title: "No review table generated",
                        subtitle: "The model did not return summary rows for this analysis."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        searchField

                        StudySmartCard {
                            HStack {
                                Label("\(filteredRows.count) review rows", systemImage: "tablecells")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(StudySmartPalette.textPrimary)
                                Spacer()
                                Text(searchText.isEmpty ? "All concepts" : "Filtered")
                                    .font(.caption)
                                    .foregroundStyle(StudySmartPalette.textMuted)
                            }
                        }

                        ForEach(filteredRows) { row in
                            ReviewRowView(row: row)
                        }
                    }
                }
            } else {
                EmptyResultView(
                    icon: "sparkles",
                    title: "Analysis not ready",
                    subtitle: "Once you analyze your PDFs, the concept breakdown appears here."
                )
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(StudySmartPalette.textMuted)

            TextField("Search concept or explanation", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundStyle(StudySmartPalette.textPrimary)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(StudySmartPalette.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(StudySmartPalette.surface, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
        )
    }
}

private struct ReviewRowView: View {
    let row: ReviewTableRow
    @State private var isExpanded = false

    var body: some View {
        StudySmartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.concept)
                            .font(.headline)
                            .foregroundStyle(StudySmartPalette.textPrimary)

                        Text(isExpanded ? row.explanation : row.explanation)
                            .font(.subheadline)
                            .foregroundStyle(StudySmartPalette.textSecondary)
                            .lineLimit(isExpanded ? nil : 3)
                    }

                    Spacer(minLength: 12)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(StudySmartPalette.textMuted)
                        .padding(10)
                        .background(StudySmartPalette.surface, in: Circle())
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isExpanded.toggle()
            }
        }
    }
}
