import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/study_smart_theme.dart';
import 'empty_result_view.dart';

// MARK: - KeyPointsView
// Mirrors Swift's KeyPointsView from Sources/PDFAnalyzerAppCore/Views/KeyPointsView.swift
// Displays the 15 most important concepts extracted from the study material.

class KeyPointsView extends StatefulWidget {
  const KeyPointsView({super.key, required this.keyPoints});

  final List<String> keyPoints;

  @override
  State<KeyPointsView> createState() => _KeyPointsViewState();
}

class _KeyPointsViewState extends State<KeyPointsView> {
  String? _copiedId;

  @override
  Widget build(BuildContext context) {
    if (widget.keyPoints.isEmpty) {
      return const EmptyResultView(
        icon: Icons.star_rounded,
        title: 'Önemli nokta bulunamadı',
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
                  color: StudySmartPalette.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.star_rounded, color: StudySmartPalette.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                '${widget.keyPoints.length} önemli içgörü',
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

        // Key points list
        ...widget.keyPoints.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KeyPointCard(
              number: entry.key + 1,
              text: entry.value,
              isCopied: _copiedId == 'kp_${entry.key}',
              onLongPress: () => _copyToClipboard('kp_${entry.key}', entry.value),
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String id, String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedId = id);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _copiedId = null);
    });
  }
}

class _KeyPointCard extends StatelessWidget {
  const _KeyPointCard({
    required this.number,
    required this.text,
    required this.isCopied,
    required this.onLongPress,
  });

  final int number;
  final String text;
  final bool isCopied;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: StudySmartCard(
        cornerRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NumberBadge(number: number),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: StudySmartPalette.textPrimary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            if (isCopied)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'Kopyalandı',
                  style: TextStyle(
                    color: StudySmartPalette.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
