import 'package:flutter/material.dart';
import '../theme/study_smart_theme.dart';

// MARK: - EmptyResultView
// Mirrors Swift's EmptyResultView from Sources/PDFAnalyzerAppCore/Views/EmptyResultView.swift
// Simple empty state wrapper around StudySmartEmptyCard.

class EmptyResultView extends StatelessWidget {
  const EmptyResultView({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StudySmartEmptyCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}
