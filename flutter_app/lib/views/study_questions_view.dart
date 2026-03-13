import 'package:flutter/material.dart';
import '../theme/study_smart_theme.dart';
import 'empty_result_view.dart';

// MARK: - StudyQuestionsView
// Mirrors Swift's StudyQuestionsView from Sources/PDFAnalyzerAppCore/Views/StudyQuestionsView.swift
// Displays 10 self-test prompts based on exam patterns and study material.

class StudyQuestionsView extends StatelessWidget {
  const StudyQuestionsView({super.key, required this.questions});

  final List<String> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const EmptyResultView(
        icon: Icons.help_rounded,
        title: 'Çalışma sorusu bulunamadı',
        subtitle: 'Daha zengin içerikli bir belgeyle yeniden analiz yapmayı deneyin.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Summary card
        StudySmartCard(
          cornerRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudySmartPalette.tertiary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.help_rounded, color: StudySmartPalette.tertiary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                '${questions.length} soru hazır',
                style: const TextStyle(
                  color: StudySmartPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Questions
        ...questions.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: StudySmartCard(
              cornerRadius: 18,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  NumberBadge(
                    number: entry.key + 1,
                    color: StudySmartPalette.tertiary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        color: StudySmartPalette.textPrimary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
