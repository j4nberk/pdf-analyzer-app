import 'dart:math';
import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../theme/study_smart_theme.dart';
import 'empty_result_view.dart';

// MARK: - FlashcardsView
// Mirrors Swift's FlashcardsView from Sources/PDFAnalyzerAppCore/Views/FlashcardsView.swift
// Interactive card deck with flip animation, swipe gestures, and progress tracking.

class FlashcardsView extends StatefulWidget {
  const FlashcardsView({super.key, required this.flashcards});

  final List<Flashcard> flashcards;

  @override
  State<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends State<FlashcardsView>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isFlipped = false;
  double _dragOffset = 0.0;

  // Flip animation controller
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  void _goToNext() {
    if (_currentIndex < widget.flashcards.length - 1) {
      setState(() {
        _currentIndex++;
        _isFlipped = false;
        _dragOffset = 0;
      });
      _flipController.value = 0;
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _isFlipped = false;
        _dragOffset = 0;
      });
      _flipController.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.flashcards.isEmpty) {
      return const EmptyResultView(
        icon: Icons.layers_rounded,
        title: 'Flaşkart bulunamadı',
        subtitle: 'Daha zengin içerikli bir belgeyle yeniden analiz yapmayı deneyin.',
      );
    }

    final card = widget.flashcards[_currentIndex];
    final progress = (_currentIndex + 1) / widget.flashcards.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        children: [
          // Header with progress
          StudySmartCard(
            cornerRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'KART',
                      style: TextStyle(
                        color: StudySmartPalette.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentIndex + 1} / ${widget.flashcards.length}',
                      style: const TextStyle(
                        color: StudySmartPalette.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _isFlipped ? 'Cevap görünüyor' : 'Görmek için dokun',
                      style: const TextStyle(
                        color: StudySmartPalette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: StudySmartPalette.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(StudySmartPalette.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card stack (current + next preview)
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() => _dragOffset += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                const threshold = 70.0;
                if (_dragOffset < -threshold) {
                  _goToNext();
                } else if (_dragOffset > threshold) {
                  _goToPrevious();
                } else {
                  setState(() => _dragOffset = 0);
                }
              },
              onTap: _flipCard,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Next card preview (behind)
                  if (_currentIndex < widget.flashcards.length - 1)
                    Positioned.fill(
                      child: Transform.scale(
                        scale: 0.96,
                        child: Transform.translate(
                          offset: const Offset(0, 16),
                          child: Opacity(
                            opacity: 0.45,
                            child: _FlashCard(
                              card: widget.flashcards[_currentIndex + 1],
                              isFlipped: false,
                              flipAnimation: const AlwaysStoppedAnimation(0),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Current card
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: Matrix4.translationValues(_dragOffset * 0.3, 0, 0),
                    child: _FlashCard(
                      card: card,
                      isFlipped: _isFlipped,
                      flipAnimation: _flipAnimation,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Navigation buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavButton(
                icon: Icons.arrow_back_ios_rounded,
                label: 'Önceki',
                onTap: _currentIndex > 0 ? _goToPrevious : null,
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: _flipCard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _isFlipped ? 'Soruyu Göster' : 'Cevabı Göster',
                    style: const TextStyle(
                      color: Color(0xCC000000),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _NavButton(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'Sonraki',
                onTap: _currentIndex < widget.flashcards.length - 1 ? _goToNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// MARK: - Flash Card Widget

class _FlashCard extends StatelessWidget {
  const _FlashCard({
    required this.card,
    required this.isFlipped,
    required this.flipAnimation,
  });

  final Flashcard card;
  final bool isFlipped;
  final Animation<double> flipAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: flipAnimation,
      builder: (context, child) {
        final angle = flipAnimation.value * pi;
        final isShowingBack = angle > pi / 2;

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateY(angle),
          alignment: Alignment.center,
          child: isShowingBack
              ? Transform(
                  transform: Matrix4.identity()..rotateY(pi),
                  alignment: Alignment.center,
                  child: _CardFace(
                    text: card.answer,
                    label: 'CEVAP',
                    accentColor: StudySmartPalette.secondary,
                  ),
                )
              : _CardFace(
                  text: card.question,
                  label: 'SORU',
                  accentColor: StudySmartPalette.primary,
                ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.text,
    required this.label,
    required this.accentColor,
  });

  final String text;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: StudySmartPalette.surfaceBorder, width: 1),
      ),
      child: Stack(
        children: [
          // Glow accent circle (top right)
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.08),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  text,
                  style: const TextStyle(
                    color: StudySmartPalette.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kaydırarak geç',
                  style: TextStyle(color: StudySmartPalette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: active ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: StudySmartPalette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: StudySmartPalette.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon == Icons.arrow_back_ios_rounded) ...[
                Icon(icon, color: StudySmartPalette.textSecondary, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: const TextStyle(color: StudySmartPalette.textSecondary, fontSize: 13),
              ),
              if (icon == Icons.arrow_forward_ios_rounded) ...[
                const SizedBox(width: 4),
                Icon(icon, color: StudySmartPalette.textSecondary, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
