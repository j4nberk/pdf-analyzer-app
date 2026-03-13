import SwiftUI

enum StudySmartPalette {
    static let background = Color(hex: 0x131315)
    static let backgroundTop = Color(hex: 0x1A1D2C)
    static let surface = Color.white.opacity(0.09)
    static let surfaceStrong = Color.white.opacity(0.14)
    static let surfaceBorder = Color.white.opacity(0.1)
    static let textPrimary = Color(hex: 0xE4E2E4)
    static let textSecondary = Color(hex: 0xB9C0D0)
    static let textMuted = Color(hex: 0x80889B)
    static let primary = Color(hex: 0xAAC7FF)
    static let primaryStrong = Color(hex: 0x3E90FF)
    static let secondary = Color(hex: 0x74D1FF)
    static let tertiary = Color(hex: 0xE9B3FF)
    static let success = Color(hex: 0x86E2A7)
    static let warning = Color(hex: 0xFFC98B)
    static let danger = Color(hex: 0xFFB4AB)
}

enum AnalysisSectionTab: String, CaseIterable, Identifiable {
    case keyPoints
    case reviewTables
    case studyQuestions
    case flashcards

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keyPoints:
            return "Key Points"
        case .reviewTables:
            return "Review Tables"
        case .studyQuestions:
            return "Study Questions"
        case .flashcards:
            return "Flashcards"
        }
    }

    var systemImage: String {
        switch self {
        case .keyPoints:
            return "star.fill"
        case .reviewTables:
            return "tablecells.fill"
        case .studyQuestions:
            return "questionmark.circle.fill"
        case .flashcards:
            return "rectangle.stack.fill"
        }
    }
}

struct StudySmartBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [StudySmartPalette.backgroundTop, StudySmartPalette.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(StudySmartPalette.primaryStrong.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: -150, y: -250)

            Circle()
                .fill(StudySmartPalette.tertiary.opacity(0.15))
                .frame(width: 260, height: 260)
                .blur(radius: 90)
                .offset(x: 170, y: -240)

            Circle()
                .fill(StudySmartPalette.secondary.opacity(0.1))
                .frame(width: 260, height: 260)
                .blur(radius: 110)
                .offset(x: 140, y: 240)
        }
        .ignoresSafeArea()
    }
}

struct StudySmartTopBar<Leading: View, Trailing: View>: View {
    let title: String
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            leading
                .frame(width: 28, alignment: .leading)

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(StudySmartPalette.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
                .frame(width: 28, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
        )
    }
}

struct StudySmartActionButton: View {
    let title: String
    let systemImage: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: StudySmartPalette.primary.opacity(0.28), radius: 18, y: 12)

                HStack(spacing: 10) {
                    if isLoading {
                        ProgressView()
                            .tint(Color.black.opacity(0.8))
                    } else {
                        Image(systemName: systemImage)
                            .font(.headline.weight(.semibold))
                    }

                    Text(title)
                        .font(.headline.weight(.semibold))
                }
                .foregroundStyle(Color.black.opacity(0.72))
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 62)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled || isLoading ? 1 : 0.45)
        .scaleEffect(isEnabled ? 1 : 0.98)
    }
}

struct StudySmartTabPill: View {
    let tab: AnalysisSectionTab
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tab.systemImage)
                .font(.caption.weight(.semibold))
            Text(tab.title)
                .font(.footnote.weight(.medium))
        }
        .foregroundStyle(isSelected ? Color.black.opacity(0.72) : StudySmartPalette.textSecondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Group {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                } else {
                    Capsule(style: .continuous)
                        .fill(StudySmartPalette.surface)
                }
            }
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(StudySmartPalette.surfaceBorder, lineWidth: isSelected ? 0 : 1)
        )
    }
}

struct StudySmartDockItem: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
}

struct StudySmartDock: View {
    let items: [StudySmartDockItem]

    var body: some View {
        HStack {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: 5) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: item.isSelected ? .semibold : .regular))
                        Text(item.title)
                            .font(.system(size: 10, weight: item.isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(item.isSelected ? StudySmartPalette.primary : StudySmartPalette.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        if item.isSelected {
                            Capsule(style: .continuous)
                                .fill(StudySmartPalette.primary)
                                .frame(width: 16, height: 3)
                                .offset(y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule(style: .continuous))
        .overlay(
            Capsule(style: .continuous)
                .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
        )
    }
}

struct StudySmartCard<Content: View>: View {
    var cornerRadius: CGFloat = 28
    let content: Content

    init(cornerRadius: CGFloat = 28, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
            )
    }
}

struct StudySmartSectionHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.4)
                .foregroundStyle(StudySmartPalette.primary)

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(StudySmartPalette.textPrimary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(StudySmartPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StudySmartEmptyCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        StudySmartCard {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(StudySmartPalette.primary)
                    .padding(14)
                    .background(StudySmartPalette.surfaceStrong, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(StudySmartPalette.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }
}

extension View {
    func studySmartForeground() -> some View {
        foregroundStyle(StudySmartPalette.textPrimary)
    }
}

extension Color {
    init(hex: Int, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
