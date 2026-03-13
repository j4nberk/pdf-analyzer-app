import 'package:flutter/material.dart';

// MARK: - StudySmart Color Palette
// Mirrors Swift's StudySmartPalette enum from
// Sources/PDFAnalyzerAppCore/Theme/StudySmartTheme.swift

class StudySmartPalette {
  StudySmartPalette._();

  // Backgrounds
  static const Color background = Color(0xFF131315);
  static const Color backgroundTop = Color(0xFF1A1D2C);

  // Surfaces
  static const Color surface = Color(0x17FFFFFF); // white 9% opacity
  static const Color surfaceStrong = Color(0x24FFFFFF); // white 14%
  static const Color surfaceBorder = Color(0x1AFFFFFF); // white 10%

  // Text
  static const Color textPrimary = Color(0xFFE4E2E4);
  static const Color textSecondary = Color(0xFFB9C0D0);
  static const Color textMuted = Color(0xFF80889B);

  // Accent Colors
  static const Color primary = Color(0xFFAAC7FF);
  static const Color primaryStrong = Color(0xFF3E90FF);
  static const Color secondary = Color(0xFF74D1FF);
  static const Color tertiary = Color(0xFFE9B3FF);

  // Semantic
  static const Color success = Color(0xFF86E2A7);
  static const Color warning = Color(0xFFFFC98B);
  static const Color danger = Color(0xFFFFB4AB);
}

// MARK: - Analysis Section Tabs
// Mirrors Swift's AnalysisSectionTab enum

enum AnalysisSectionTab {
  keyPoints,
  reviewTables,
  studyQuestions,
  flashcards;

  String get title {
    switch (this) {
      case AnalysisSectionTab.keyPoints:
        return 'Key Points';
      case AnalysisSectionTab.reviewTables:
        return 'Review Tables';
      case AnalysisSectionTab.studyQuestions:
        return 'Study Questions';
      case AnalysisSectionTab.flashcards:
        return 'Flashcards';
    }
  }

  IconData get icon {
    switch (this) {
      case AnalysisSectionTab.keyPoints:
        return Icons.star_rounded;
      case AnalysisSectionTab.reviewTables:
        return Icons.table_chart_rounded;
      case AnalysisSectionTab.studyQuestions:
        return Icons.help_rounded;
      case AnalysisSectionTab.flashcards:
        return Icons.layers_rounded;
    }
  }
}

// MARK: - Common Gradients

/// The primary → secondary gradient used for action buttons and active tabs.
const LinearGradient kPrimaryGradient = LinearGradient(
  colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// MARK: - StudySmart Background Widget
// Mirrors Swift's StudySmartBackground View

class StudySmartBackground extends StatelessWidget {
  const StudySmartBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [StudySmartPalette.backgroundTop, StudySmartPalette.background],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Blue glow – top left
        Positioned(
          left: -150,
          top: -200,
          child: _GlowCircle(
            size: 320,
            color: StudySmartPalette.primaryStrong.withOpacity(0.22),
            blurRadius: 80,
          ),
        ),
        // Purple glow – top right
        Positioned(
          right: -90,
          top: -180,
          child: _GlowCircle(
            size: 260,
            color: StudySmartPalette.tertiary.withOpacity(0.15),
            blurRadius: 90,
          ),
        ),
        // Cyan glow – bottom right
        Positioned(
          right: -100,
          bottom: 40,
          child: _GlowCircle(
            size: 260,
            color: StudySmartPalette.secondary.withOpacity(0.10),
            blurRadius: 110,
          ),
        ),
        // Actual content
        child,
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
    required this.blurRadius,
  });

  final double size;
  final Color color;
  final double blurRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

// MARK: - StudySmart Top Bar
// Mirrors Swift's StudySmartTopBar View

class StudySmartTopBar extends StatelessWidget {
  const StudySmartTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: StudySmartPalette.surfaceBorder, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: leading,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: StudySmartPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 28,
                child: trailing,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - StudySmart Action Button
// Mirrors Swift's StudySmartActionButton View

class StudySmartActionButton extends StatelessWidget {
  const StudySmartActionButton({
    super.key,
    required this.title,
    required this.icon,
    this.isEnabled = true,
    this.isLoading = false,
    required this.onPressed,
  });

  final String title;
  final IconData icon;
  final bool isEnabled;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final active = isEnabled && !isLoading;
    return GestureDetector(
      onTap: active ? onPressed : null,
      child: Opacity(
        opacity: isEnabled || isLoading ? 1.0 : 0.45,
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [StudySmartPalette.primary, StudySmartPalette.secondary],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(31),
            boxShadow: [
              BoxShadow(
                color: StudySmartPalette.primary.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xCC000000),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: const Color(0xCC000000), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xCC000000),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// MARK: - StudySmart Tab Pill
// Mirrors Swift's StudySmartTabPill View

class StudySmartTabPill extends StatelessWidget {
  const StudySmartTabPill({
    super.key,
    required this.tab,
    required this.isSelected,
    required this.onTap,
  });

  final AnalysisSectionTab tab;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? kPrimaryGradient : null,
          color: isSelected ? null : StudySmartPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? null
              : Border.all(color: StudySmartPalette.surfaceBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: 12,
              color: isSelected
                  ? const Color(0xCC000000)
                  : StudySmartPalette.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              tab.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xCC000000)
                    : StudySmartPalette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - StudySmart Card
// Mirrors Swift's StudySmartCard View

class StudySmartCard extends StatelessWidget {
  const StudySmartCard({
    super.key,
    required this.child,
    this.cornerRadius = 28.0,
    this.padding,
  });

  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(cornerRadius),
        border: Border.all(color: StudySmartPalette.surfaceBorder, width: 1),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );
  }
}

// MARK: - StudySmart Section Header
// Mirrors Swift's StudySmartSectionHeader View

class StudySmartSectionHeader extends StatelessWidget {
  const StudySmartSectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!.toUpperCase(),
            style: const TextStyle(
              color: StudySmartPalette.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
        if (eyebrow != null) const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: StudySmartPalette.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              color: StudySmartPalette.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

// MARK: - StudySmart Empty Card
// Mirrors Swift's StudySmartEmptyCard View

class StudySmartEmptyCard extends StatelessWidget {
  const StudySmartEmptyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor = StudySmartPalette.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: StudySmartPalette.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: StudySmartPalette.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Number Badge
// Small numbered circle used in KeyPointsView and StudyQuestionsView

class NumberBadge extends StatelessWidget {
  const NumberBadge({
    super.key,
    required this.number,
    this.color = StudySmartPalette.primary,
  });

  final int number;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Center(
        child: Text(
          '$number',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
