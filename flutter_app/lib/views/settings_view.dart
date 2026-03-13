import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/app_view_model.dart';
import '../theme/study_smart_theme.dart';

// MARK: - SettingsView
// Mirrors Swift's SettingsView from Sources/PDFAnalyzerAppCore/Views/SettingsView.swift
// Configuration screen for API key, model selection, and app info.

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _showApiKey = false;
  late final TextEditingController _apiKeyController;

  @override
  void initState() {
    super.initState();
    final vm = context.read<AppViewModel>();
    _apiKeyController = TextEditingController(text: vm.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  static const _modelDisplayNames = {
    'gemini-2.0-flash': 'Gemini 2.0 Flash (Önerilen)',
    'gemini-1.5-flash': 'Gemini 1.5 Flash',
    'gemini-1.5-pro': 'Gemini 1.5 Pro',
    'gemini-2.0-flash-lite': 'Gemini 2.0 Flash-Lite',
  };

  static const _modelDescriptions = {
    'gemini-2.0-flash': 'Hızlı ve güçlü — çoğu belge için ideal.',
    'gemini-1.5-flash': 'Dengeli hız ve kalite.',
    'gemini-1.5-pro': 'En yüksek kalite, karmaşık belgeler için.',
    'gemini-2.0-flash-lite': 'En hızlı seçenek, basit belgeler için.',
  };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppViewModel>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar
          const StudySmartTopBar(title: 'Ayarlar'),
          const SizedBox(height: 24),

          // API Key section
          _SettingsSection(
            title: 'Gemini API Anahtarı',
            children: [
              StudySmartCard(
                cornerRadius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _apiKeyController,
                            obscureText: !_showApiKey,
                            style: const TextStyle(
                              color: StudySmartPalette.textPrimary,
                              fontSize: 13,
                              fontFamily: 'monospace',
                            ),
                            decoration: const InputDecoration(
                              hintText: 'API anahtarınızı girin...',
                              hintStyle: TextStyle(color: StudySmartPalette.textMuted),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (val) => vm.apiKey = val,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _showApiKey = !_showApiKey),
                          child: Icon(
                            _showApiKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: StudySmartPalette.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status indicator
                    Row(
                      children: [
                        Icon(
                          vm.apiKey.trim().isEmpty
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_rounded,
                          color: vm.apiKey.trim().isEmpty
                              ? StudySmartPalette.warning
                              : StudySmartPalette.success,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          vm.apiKey.trim().isEmpty
                              ? 'API anahtarı gerekli'
                              : 'API anahtarı ayarlandı',
                          style: TextStyle(
                            color: vm.apiKey.trim().isEmpty
                                ? StudySmartPalette.warning
                                : StudySmartPalette.success,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _openUrl(context, 'https://aistudio.google.com'),
                child: const Text(
                  'aistudio.google.com adresinden ücretsiz API anahtarı alın →',
                  style: TextStyle(
                    color: StudySmartPalette.primary,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: StudySmartPalette.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Model selection
          _SettingsSection(
            title: 'Gemini Modeli',
            children: [
              StudySmartCard(
                cornerRadius: 16,
                child: Column(
                  children: AppViewModel.availableModels.asMap().entries.map((entry) {
                    final i = entry.key;
                    final model = entry.value;
                    final isSelected = vm.selectedModel == model;
                    final isLast = i == AppViewModel.availableModels.length - 1;

                    return GestureDetector(
                      onTap: () => vm.selectedModel = model,
                      child: Container(
                        decoration: BoxDecoration(
                          border: isLast
                              ? null
                              : const Border(
                                  bottom:
                                      BorderSide(color: StudySmartPalette.surfaceBorder, width: 1),
                                ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _modelDisplayNames[model] ?? model,
                                      style: TextStyle(
                                        color: isSelected
                                            ? StudySmartPalette.primary
                                            : StudySmartPalette.textPrimary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (_modelDescriptions.containsKey(model))
                                      Text(
                                        _modelDescriptions[model]!,
                                        style: const TextStyle(
                                          color: StudySmartPalette.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_rounded,
                                  color: StudySmartPalette.primary,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // About section
          _SettingsSection(
            title: 'Hakkında',
            children: [
              StudySmartCard(
                cornerRadius: 16,
                child: Column(
                  children: [
                    _InfoRow(label: 'Uygulama', value: 'StudyMed+'),
                    const Divider(color: StudySmartPalette.surfaceBorder, height: 1),
                    _InfoRow(label: 'Sürüm', value: '1.0.0'),
                    const Divider(color: StudySmartPalette.surfaceBorder, height: 1),
                    _InfoRow(label: 'Yapay Zeka', value: 'Google Gemini API'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Danger zone
          _SettingsSection(
            title: 'Tehlikeli Bölge',
            children: [
              GestureDetector(
                onTap: () => _confirmClearAll(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StudySmartPalette.danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: StudySmartPalette.danger.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline_rounded, color: StudySmartPalette.danger, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Tüm Verileri Temizle',
                        style: TextStyle(
                          color: StudySmartPalette.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: StudySmartPalette.backgroundTop,
        title: const Text(
          'Tüm Verileri Temizle',
          style: TextStyle(color: StudySmartPalette.textPrimary),
        ),
        content: const Text(
          'Tüm yüklenen belgeler ve analiz sonuçları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: StudySmartPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(color: StudySmartPalette.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<AppViewModel>().clearAll();
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Temizle',
              style: TextStyle(color: StudySmartPalette.danger, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geçersiz bağlantı'),
          backgroundColor: StudySmartPalette.surface,
        ),
      );
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı açılamadı'),
            backgroundColor: StudySmartPalette.surface,
          ),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı açılırken bir hata oluştu'),
          backgroundColor: StudySmartPalette.surface,
        ),
      );
    }
  }
}

// MARK: - Supporting Widgets

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: StudySmartPalette.textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(color: StudySmartPalette.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(color: StudySmartPalette.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
