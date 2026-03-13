import SwiftUI

struct FlashcardsView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var dragOffset: CGFloat = 0

    private var flashcards: [Flashcard] {
        viewModel.analysisResult?.flashcards ?? []
    }

    var body: some View {
        Group {
            if flashcards.isEmpty {
                EmptyResultView(
                    icon: "rectangle.stack.fill",
                    title: "No flashcards generated",
                    subtitle: "The flashcard deck will appear here after a successful analysis."
                )
            } else {
                VStack(spacing: 18) {
                    progressHeader

                    ZStack {
                        if currentIndex + 1 < flashcards.count {
                            FlashcardCard(
                                card: flashcards[currentIndex + 1],
                                isFlipped: .constant(false),
                                dragOffset: .constant(0)
                            )
                            .scaleEffect(0.96)
                            .offset(y: 16)
                            .opacity(0.45)
                            .allowsHitTesting(false)
                        }

                        FlashcardCard(
                            card: flashcards[currentIndex],
                            index: currentIndex + 1,
                            total: flashcards.count,
                            isFlipped: $isFlipped,
                            dragOffset: $dragOffset
                        )
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                            }
                            .onEnded { value in
                                handleSwipe(translation: value.translation.width)
                            }
                    )

                    navigationControls
                }
            }
        }
        .onChange(of: viewModel.analysisResult) { _, _ in
            currentIndex = 0
            isFlipped = false
            dragOffset = 0
        }
    }

    private var progressHeader: some View {
        StudySmartCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CARD \(currentIndex + 1) OF \(flashcards.count)")
                        .font(.caption.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(StudySmartPalette.primary)

                    Spacer()

                    Text(isFlipped ? "Answer visible" : "Tap to reveal")
                        .font(.caption)
                        .foregroundStyle(StudySmartPalette.textMuted)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(StudySmartPalette.surface)
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(max(flashcards.count, 1)))
                    }
                }
                .frame(height: 8)
            }
        }
    }

    private var navigationControls: some View {
        HStack(spacing: 14) {
            controlButton(systemImage: "arrow.left", isEnabled: currentIndex > 0) {
                navigate(by: -1)
            }

            Button {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                    isFlipped.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text(isFlipped ? "Show question" : "Reveal answer")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.black.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: Capsule(style: .continuous)
                )
            }
            .buttonStyle(.plain)

            controlButton(systemImage: "arrow.right", isEnabled: currentIndex < flashcards.count - 1) {
                navigate(by: 1)
            }
        }
    }

    private func controlButton(systemImage: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isEnabled ? StudySmartPalette.textPrimary : StudySmartPalette.textMuted)
                .frame(width: 54, height: 54)
                .background(StudySmartPalette.surface, in: Circle())
                .overlay(
                    Circle()
                        .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func navigate(by delta: Int) {
        let newIndex = currentIndex + delta
        guard newIndex >= 0 && newIndex < flashcards.count else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            isFlipped = false
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                currentIndex = newIndex
            }
        }
    }

    private func handleSwipe(translation: CGFloat) {
        let threshold: CGFloat = 70
        withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
            dragOffset = 0
        }

        if translation < -threshold {
            navigate(by: 1)
        } else if translation > threshold {
            navigate(by: -1)
        }
    }
}

private struct FlashcardCard: View {
    let card: Flashcard
    var index: Int = 1
    var total: Int = 1
    @Binding var isFlipped: Bool
    @Binding var dragOffset: CGFloat

    var body: some View {
        ZStack {
            cardFace(
                title: "Question",
                text: card.question,
                accent: StudySmartPalette.primary
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(.degrees(isFlipped ? -90 : 0), axis: (x: 0, y: 1, z: 0))

            cardFace(
                title: "Answer",
                text: card.answer,
                accent: StudySmartPalette.secondary
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(.degrees(isFlipped ? 0 : 90), axis: (x: 0, y: 1, z: 0))
        }
        .offset(x: dragOffset)
        .onTapGesture {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                isFlipped.toggle()
            }
        }
    }

    private func cardFace(title: String, text: String, accent: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.06), Color.white.opacity(0.03)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .stroke(StudySmartPalette.surfaceBorder, lineWidth: 1)

            Circle()
                .fill(accent.opacity(0.16))
                .frame(width: 180, height: 180)
                .blur(radius: 40)
                .offset(x: 95, y: -130)

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CARD \(index) OF \(total)")
                            .font(.caption.weight(.bold))
                            .tracking(1.2)
                            .foregroundStyle(accent)

                        Capsule(style: .continuous)
                            .fill(accent)
                            .frame(width: 34, height: 4)
                    }

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(StudySmartPalette.textPrimary)
                        .padding(12)
                        .background(StudySmartPalette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer()

                Text(text)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(StudySmartPalette.textPrimary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(isFlipped ? "Tap to go back" : "Tap to reveal the answer")
                    .font(.subheadline)
                    .foregroundStyle(StudySmartPalette.textSecondary)
                    .frame(maxWidth: .infinity)

                Spacer()

                HStack {
                    Label("Study deck", systemImage: "cube.transparent")
                        .font(.footnote)
                        .foregroundStyle(StudySmartPalette.textSecondary)

                    Spacer()

                    Label("Swipe for next", systemImage: "arrow.left.and.right")
                        .font(.footnote)
                        .foregroundStyle(StudySmartPalette.textSecondary)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 420)
        .shadow(color: Color.black.opacity(0.18), radius: 24, y: 16)
    }
}
