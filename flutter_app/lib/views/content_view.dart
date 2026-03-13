import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/app_view_model.dart';
import '../theme/study_smart_theme.dart';
import 'document_upload_view.dart';
import 'analysis_view.dart';
import 'settings_view.dart';

// MARK: - ContentView
// Mirrors Swift's ContentView from Sources/PDFAnalyzerAppCore/ContentView.swift
// Main navigation shell with a bottom dock (library, analyze, flashcards, settings).

class ContentView extends StatefulWidget {
  const ContentView({super.key});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> {
  int _selectedTab = 0;

  final List<_DockItem> _dockItems = const [
    _DockItem(label: 'Belgeler', icon: Icons.folder_rounded),
    _DockItem(label: 'Analiz', icon: Icons.auto_awesome_rounded),
    _DockItem(label: 'Sonuçlar', icon: Icons.layers_rounded),
    _DockItem(label: 'Ayarlar', icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return Scaffold(
      backgroundColor: StudySmartPalette.background,
      body: StudySmartBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    // Tab 0: Document upload
                    DocumentUploadView(
                      onAnalyzeTap: () => setState(() => _selectedTab = 1),
                    ),
                    // Tab 1: Analysis trigger / results preview
                    _AnalysisTabView(
                      onOpenFullAnalysis: () => setState(() => _selectedTab = 2),
                    ),
                    // Tab 2: Full analysis view
                    vm.analysisResult != null
                        ? AnalysisView(
                            result: vm.analysisResult!,
                            onBack: () => setState(() => _selectedTab = 1),
                          )
                        : _NoResultsView(
                            onGoToDocuments: () => setState(() => _selectedTab = 0),
                          ),
                    // Tab 3: Settings
                    const SettingsView(),
                  ],
                ),
              ),

              // Bottom dock
              _StudySmartDock(
                items: _dockItems,
                selectedIndex: _selectedTab,
                onItemSelected: (i) => setState(() => _selectedTab = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Analysis Tab View

class _AnalysisTabView extends StatelessWidget {
  const _AnalysisTabView({required this.onOpenFullAnalysis});

  final VoidCallback onOpenFullAnalysis;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          StudySmartTopBar(
            title: 'StudySmart',
            trailing: vm.analysisResult != null
                ? GestureDetector(
                    onTap: onOpenFullAnalysis,
                    child: const Icon(
                      Icons.open_in_full_rounded,
                      color: StudySmartPalette.primary,
                      size: 22,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 24),

          // Section header
          const StudySmartSectionHeader(
            eyebrow: 'AI Analizi',
            title: 'Gemini ile Analiz Et',
            subtitle: 'Belgelerinizi yükleyin ve analiz başlatın',
          ),
          const SizedBox(height: 24),

          // Status cards
          if (vm.examQuestionsDocument != null)
            _StatusCard(
              icon: Icons.description_rounded,
              label: 'Sınav Soruları',
              value: vm.examQuestionsDocument!.name,
              wordCount: _wordCount(vm.examQuestionsDocument!.extractedText),
            ),
          if (vm.examQuestionsDocument != null) const SizedBox(height: 8),

          ...vm.studyMaterials.map(
            (doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _StatusCard(
                icon: Icons.book_rounded,
                label: 'Çalışma Materyali',
                value: doc.name,
                wordCount: _wordCount(doc.extractedText),
              ),
            ),
          ),

          if (vm.examQuestionsDocument == null && vm.studyMaterials.isEmpty)
            StudySmartCard(
              padding: const EdgeInsets.all(20),
              child: const StudySmartEmptyCard(
                icon: Icons.upload_file_rounded,
                title: 'Belge Yüklenmedi',
                subtitle: 'Analiz başlatmak için önce "Belgeler" sekmesinden PDF yükleyin.',
              ),
            ),

          const SizedBox(height: 24),

          // Analyze button
          StudySmartActionButton(
            title: vm.isAnalyzing ? 'Analiz Ediliyor...' : 'Gemini ile Analiz Et',
            icon: Icons.auto_awesome_rounded,
            isEnabled: vm.canAnalyze,
            isLoading: vm.isAnalyzing,
            onPressed: () async {
              await vm.analyze();
              if (vm.analysisResult != null && context.mounted) {
                onOpenFullAnalysis();
              }
            },
          ),

          if (vm.analysisError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: StudySmartPalette.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: StudySmartPalette.danger.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: StudySmartPalette.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      vm.analysisError!,
                      style: const TextStyle(
                        color: StudySmartPalette.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (vm.analysisResult != null) ...[
            const SizedBox(height: 24),
            _ResultPreviewCard(result: vm.analysisResult!, onOpen: onOpenFullAnalysis),
          ],
        ],
      ),
    );
  }

  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.wordCount,
  });

  final IconData icon;
  final String label;
  final String value;
  final int wordCount;

  @override
  Widget build(BuildContext context) {
    return StudySmartCard(
      cornerRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: StudySmartPalette.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: StudySmartPalette.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: StudySmartPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$wordCount kelime',
            style: const TextStyle(
              color: StudySmartPalette.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultPreviewCard extends StatelessWidget {
  const _ResultPreviewCard({required this.result, required this.onOpen});

  final dynamic result;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return StudySmartCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: StudySmartPalette.success, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Analiz Tamamlandı',
                  style: TextStyle(
                    color: StudySmartPalette.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onOpen,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: kPrimaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aç',
                    style: TextStyle(
                      color: Color(0xCC000000),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetricBadge(label: '${result.keyPoints.length}', sublabel: 'Önemli\nNokta'),
              const SizedBox(width: 8),
              _MetricBadge(label: '${result.reviewTable.length}', sublabel: 'Kavram\nTablosu'),
              const SizedBox(width: 8),
              _MetricBadge(label: '${result.studyQuestions.length}', sublabel: 'Çalışma\nSorusu'),
              const SizedBox(width: 8),
              _MetricBadge(label: '${result.flashcards.length}', sublabel: 'Flaşkart'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({required this.label, required this.sublabel});

  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: StudySmartPalette.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: StudySmartPalette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: const TextStyle(
                color: StudySmartPalette.textMuted,
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.onGoToDocuments});

  final VoidCallback onGoToDocuments;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StudySmartEmptyCard(
              icon: Icons.layers_rounded,
              title: 'Henüz Analiz Yok',
              subtitle:
                  'Sonuçları görmek için önce belgelerinizi yükleyin ve analiz başlatın.',
            ),
            const SizedBox(height: 24),
            StudySmartActionButton(
              title: 'Belge Yükle',
              icon: Icons.upload_file_rounded,
              onPressed: onGoToDocuments,
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Bottom Dock

class _DockItem {
  final String label;
  final IconData icon;

  const _DockItem({required this.label, required this.icon});
}

class _StudySmartDock extends StatelessWidget {
  const _StudySmartDock({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final List<_DockItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        border: const Border(
          top: BorderSide(color: StudySmartPalette.surfaceBorder, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isSelected = i == selectedIndex;
              return GestureDetector(
                onTap: () => onItemSelected(i),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        color: isSelected
                            ? StudySmartPalette.primary
                            : StudySmartPalette.textMuted,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? StudySmartPalette.primary
                              : StudySmartPalette.textMuted,
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 2,
                        width: isSelected ? 20 : 0,
                        decoration: BoxDecoration(
                          gradient: isSelected ? kPrimaryGradient : null,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
