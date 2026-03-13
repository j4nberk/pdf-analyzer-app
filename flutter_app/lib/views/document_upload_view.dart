import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/app_view_model.dart';
import '../theme/study_smart_theme.dart';

// MARK: - DocumentUploadView
// Mirrors Swift's DocumentUploadView from Sources/PDFAnalyzerAppCore/Views/DocumentUploadView.swift
// Main screen for loading exam question and study material PDFs.

class DocumentUploadView extends StatelessWidget {
  const DocumentUploadView({super.key, required this.onAnalyzeTap});

  final VoidCallback onAnalyzeTap;

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
            trailing: GestureDetector(
              onTap: () => _showAbout(context),
              child: const Icon(
                Icons.info_outline_rounded,
                color: StudySmartPalette.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Hero header
          const StudySmartSectionHeader(
            eyebrow: 'Belge Yönetimi',
            title: 'PDF\'leri Yükle',
            subtitle: 'Sınav sorularını ve çalışma materyallerini yükleyin',
          ),
          const SizedBox(height: 24),

          // -- EXAM QUESTIONS SECTION --
          const _SectionLabel(
            icon: Icons.quiz_rounded,
            title: 'Geçmiş Sınav Soruları',
            subtitle: 'Referans olarak kullanılacak sınav soruları PDF\'i',
            color: StudySmartPalette.primary,
          ),
          const SizedBox(height: 10),

          if (vm.examQuestionsDocument == null)
            _UploadPlaceholder(
              label: 'Sınav soruları PDF\'ini seçin',
              icon: Icons.upload_file_rounded,
              onTap: () async {
                final result = await _pickPDF();
                if (result != null && context.mounted) {
                  await vm.loadExamQuestionsDocument(result.path, result.name);
                }
              },
            )
          else
            _DocumentRow(
              document: vm.examQuestionsDocument!,
              onRemove: () {
                vm.examQuestionsDocument = null;
                vm.notifyListeners();
              },
            ),

          const SizedBox(height: 24),

          // -- STUDY MATERIALS SECTION --
          Row(
            children: [
              const Expanded(
                child: _SectionLabel(
                  icon: Icons.book_rounded,
                  title: 'Çalışma Materyalleri',
                  subtitle: 'Ders notları, slaytlar veya ders kitabı PDF\'leri',
                  color: StudySmartPalette.secondary,
                ),
              ),
              if (vm.studyMaterials.isNotEmpty)
                GestureDetector(
                  onTap: () async {
                    final result = await _pickPDF();
                    if (result != null && context.mounted) {
                      await vm.addStudyMaterial(result.path, result.name);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: StudySmartPalette.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: StudySmartPalette.secondary,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (vm.studyMaterials.isEmpty)
            _UploadPlaceholder(
              label: 'Çalışma materyali PDF\'i ekleyin',
              icon: Icons.add_circle_outline_rounded,
              onTap: () async {
                final result = await _pickPDF();
                if (result != null && context.mounted) {
                  await vm.addStudyMaterial(result.path, result.name);
                }
              },
            )
          else
            Column(
              children: vm.studyMaterials.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _DocumentRow(
                    document: entry.value,
                    onRemove: () => vm.removeStudyMaterial(entry.key),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Analyze button
          StudySmartActionButton(
            title: vm.isAnalyzing ? 'Analiz Ediliyor...' : 'Gemini ile Analiz Et',
            icon: Icons.auto_awesome_rounded,
            isEnabled: vm.canAnalyze,
            isLoading: vm.isAnalyzing,
            onPressed: () async {
              await vm.analyze();
              if (vm.analysisResult != null && context.mounted) {
                onAnalyzeTap();
              }
            },
          ),

          if (vm.analysisError != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: vm.analysisError!),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<({String path, String name})?> _pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.path == null) return null;
    return (path: file.path!, name: file.name);
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudySmartPalette.backgroundTop,
        title: const Text('PDF Analiz', style: TextStyle(color: StudySmartPalette.textPrimary)),
        content: const Text(
          'Sürüm 1.0.0\nGoogle Gemini API destekli çalışma asistanı.',
          style: TextStyle(color: StudySmartPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam', style: TextStyle(color: StudySmartPalette.primary)),
          ),
        ],
      ),
    );
  }
}

// MARK: - Supporting Widgets

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: StudySmartPalette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: StudySmartPalette.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: StudySmartPalette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: StudySmartPalette.surfaceBorder,
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: StudySmartPalette.textMuted, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: StudySmartPalette.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.onRemove});

  final dynamic document;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final wordCount = document.extractedText.trim().isEmpty
        ? 0
        : (document.extractedText.trim() as String)
            .split(RegExp(r'\s+'))
            .length;

    return StudySmartCard(
      cornerRadius: 16,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StudySmartPalette.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: StudySmartPalette.success,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name as String,
                  style: const TextStyle(
                    color: StudySmartPalette.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                color: StudySmartPalette.textMuted,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudySmartPalette.danger.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: StudySmartPalette.danger.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: StudySmartPalette.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: StudySmartPalette.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
