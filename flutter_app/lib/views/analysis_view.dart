import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/analysis_result.dart';
import '../theme/study_smart_theme.dart';
import 'key_points_view.dart';
import 'review_table_view.dart';
import 'study_questions_view.dart';
import 'flashcards_view.dart';

// MARK: - AnalysisView
// Mirrors Swift's AnalysisView from Sources/PDFAnalyzerAppCore/Views/AnalysisView.swift
// Tabbed results screen showing key points, review table, study questions, and flashcards.

class AnalysisView extends StatefulWidget {
  const AnalysisView({
    super.key,
    required this.result,
    this.onBack,
  });

  final AnalysisResult result;
  final VoidCallback? onBack;

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  AnalysisSectionTab _selectedTab = AnalysisSectionTab.keyPoints;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: StudySmartTopBar(
            title: 'StudySmart',
            leading: widget.onBack != null
                ? GestureDetector(
                    onTap: widget.onBack,
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: StudySmartPalette.textSecondary,
                      size: 20,
                    ),
                  )
                : null,
            trailing: GestureDetector(
              onTap: () => _shareResults(context),
              child: const Icon(
                Icons.share_rounded,
                color: StudySmartPalette.textSecondary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Tab picker (horizontal scroll)
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: AnalysisSectionTab.values.map((tab) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: StudySmartTabPill(
                  tab: tab,
                  isSelected: _selectedTab == tab,
                  onTap: () => setState(() => _selectedTab = tab),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case AnalysisSectionTab.keyPoints:
        return KeyPointsView(key: const ValueKey('keyPoints'), keyPoints: widget.result.keyPoints);
      case AnalysisSectionTab.reviewTables:
        return ReviewTableView(key: const ValueKey('review'), rows: widget.result.reviewTable);
      case AnalysisSectionTab.studyQuestions:
        return StudyQuestionsView(
            key: const ValueKey('questions'), questions: widget.result.studyQuestions);
      case AnalysisSectionTab.flashcards:
        return FlashcardsView(key: const ValueKey('flashcards'), flashcards: widget.result.flashcards);
    }
  }

  void _shareResults(BuildContext context) {
    final result = widget.result;
    final buffer = StringBuffer();

    buffer.writeln('📚 STUDYSMART ANALİZ SONUÇLARI');
    buffer.writeln('');
    buffer.writeln('⭐ ÖNEMLI NOKTALAR');
    for (var i = 0; i < result.keyPoints.length; i++) {
      buffer.writeln('${i + 1}. ${result.keyPoints[i]}');
    }

    buffer.writeln('');
    buffer.writeln('📋 TEKRAR TABLOSU');
    for (final row in result.reviewTable) {
      buffer.writeln('• ${row.concept}: ${row.explanation}');
    }

    buffer.writeln('');
    buffer.writeln('❓ ÇALIŞMA SORULARI');
    for (var i = 0; i < result.studyQuestions.length; i++) {
      buffer.writeln('${i + 1}. ${result.studyQuestions[i]}');
    }

    buffer.writeln('');
    buffer.writeln('🃏 FLAŞKARTLAR');
    for (var i = 0; i < result.flashcards.length; i++) {
      final card = result.flashcards[i];
      buffer.writeln('K${i + 1}: ${card.question}');
      buffer.writeln('C${i + 1}: ${card.answer}');
      buffer.writeln('');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sonuçlar panoya kopyalandı'),
        backgroundColor: StudySmartPalette.success,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
