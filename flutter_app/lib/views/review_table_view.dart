import 'package:flutter/material.dart';
import '../models/analysis_result.dart';
import '../theme/study_smart_theme.dart';
import 'empty_result_view.dart';

// MARK: - ReviewTableView
// Mirrors Swift's ReviewTableView from Sources/PDFAnalyzerAppCore/Views/ReviewTableView.swift
// Searchable expandable list of concept/explanation pairs.

class ReviewTableView extends StatefulWidget {
  const ReviewTableView({super.key, required this.rows});

  final List<ReviewTableRow> rows;

  @override
  State<ReviewTableView> createState() => _ReviewTableViewState();
}

class _ReviewTableViewState extends State<ReviewTableView> {
  String _searchQuery = '';
  final Set<String> _expandedIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReviewTableRow> get _filteredRows {
    if (_searchQuery.trim().isEmpty) return widget.rows;
    final query = _searchQuery.toLowerCase();
    return widget.rows
        .where(
          (row) =>
              row.concept.toLowerCase().contains(query) ||
              row.explanation.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const EmptyResultView(
        icon: Icons.table_chart_rounded,
        title: 'Tekrar tablosu bulunamadı',
        subtitle: 'Daha zengin içerikli bir belgeyle yeniden analiz yapmayı deneyin.',
      );
    }

    final filtered = _filteredRows;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        // Search field
        Container(
          decoration: BoxDecoration(
            color: StudySmartPalette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: StudySmartPalette.surfaceBorder),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: StudySmartPalette.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Kavram veya açıklama ara...',
              hintStyle: const TextStyle(color: StudySmartPalette.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: StudySmartPalette.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close_rounded, color: StudySmartPalette.textMuted, size: 18),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        const SizedBox(height: 12),

        // Summary card
        StudySmartCard(
          cornerRadius: 20,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudySmartPalette.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.table_chart_rounded, color: StudySmartPalette.secondary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                '${filtered.length} kavram',
                style: const TextStyle(
                  color: StudySmartPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Text(
                  'filtrelendi',
                  style: TextStyle(color: StudySmartPalette.textMuted, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Rows
        ...filtered.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ReviewRow(
              row: row,
              isExpanded: _expandedIds.contains(row.id),
              onToggle: () {
                setState(() {
                  if (_expandedIds.contains(row.id)) {
                    _expandedIds.remove(row.id);
                  } else {
                    _expandedIds.add(row.id);
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.row,
    required this.isExpanded,
    required this.onToggle,
  });

  final ReviewTableRow row;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: StudySmartCard(
        cornerRadius: 18,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.concept,
                    style: const TextStyle(
                      color: StudySmartPalette.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: StudySmartPalette.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  row.explanation,
                  style: const TextStyle(
                    color: StudySmartPalette.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              crossFadeState:
                  isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
