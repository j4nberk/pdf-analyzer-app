import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/document.dart';
import '../models/analysis_result.dart';
import '../models/app_error.dart';
import '../services/pdf_service.dart';
import '../services/gemini_service.dart';

// MARK: - AppViewModel
// Mirrors Swift's AppViewModel from Sources/PDFAnalyzerAppCore/ViewModels/AppViewModel.swift
// Central state manager for the app. Uses ChangeNotifier (equivalent to @ObservableObject).

class AppViewModel extends ChangeNotifier {
  // MARK: - Documents
  Document? examQuestionsDocument;
  List<Document> studyMaterials = [];

  // MARK: - Analysis
  AnalysisResult? analysisResult;
  bool isAnalyzing = false;
  String? analysisError;

  // MARK: - Settings
  String _apiKey = '';
  String _selectedModel = 'gemini-2.5-flash';

  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;

  set apiKey(String value) {
    _apiKey = value;
    _prefs?.setString('geminiAPIKey', value);
    notifyListeners();
  }

  set selectedModel(String value) {
    _selectedModel = value;
    _prefs?.setString('geminiModel', value);
    notifyListeners();
  }

  // MARK: - Services
  final _pdfService = PDFService();
  final _geminiService = GeminiService();

  // MARK: - Available Models
  static const List<String> availableModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
  ];

  SharedPreferences? _prefs;

  AppViewModel() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _apiKey = _prefs!.getString('geminiAPIKey') ?? '';
    _selectedModel = _prefs!.getString('geminiModel') ?? 'gemini-2.5-flash';
    notifyListeners();
  }

  // MARK: - Document Management

  /// Loads a PDF from the given file path and sets it as the exam questions document.
  Future<void> loadExamQuestionsDocument(String filePath, String fileName) async {
    analysisError = null;
    notifyListeners();
    try {
      final text = await _pdfService.extractText(filePath);
      examQuestionsDocument = Document(
        id: DateTime.now().toIso8601String(),
        name: fileName.replaceAll('.pdf', ''),
        extractedText: text,
        type: DocumentType.examQuestions,
      );
    } catch (e) {
      analysisError = e.toString();
    }
    notifyListeners();
  }

  /// Loads a PDF from the given file path and appends it to study materials.
  Future<void> addStudyMaterial(String filePath, String fileName) async {
    analysisError = null;
    notifyListeners();
    try {
      final text = await _pdfService.extractText(filePath);
      final doc = Document(
        id: '${DateTime.now().toIso8601String()}_$fileName',
        name: fileName.replaceAll('.pdf', ''),
        extractedText: text,
        type: DocumentType.studyMaterial,
      );
      studyMaterials = [...studyMaterials, doc];
    } catch (e) {
      analysisError = e.toString();
    }
    notifyListeners();
  }

  /// Removes the study material at the given index.
  void removeStudyMaterial(int index) {
    if (index < 0 || index >= studyMaterials.length) return;
    studyMaterials = List.from(studyMaterials)..removeAt(index);
    notifyListeners();
  }

  /// Clears the selected exam questions document.
  void clearExamQuestionsDocument() {
    examQuestionsDocument = null;
    notifyListeners();
  }

  // MARK: - Analysis

  /// Whether the app can run an analysis (study materials loaded, API key set, not already running).
  bool get canAnalyze =>
      studyMaterials.isNotEmpty &&
      _apiKey.trim().isNotEmpty &&
      !isAnalyzing;

  /// Sends documents to Gemini for analysis and stores the result.
  Future<void> analyze() async {
    if (studyMaterials.isEmpty) {
      analysisError = AppError.noStudyMaterials.message;
      notifyListeners();
      return;
    }
    if (_apiKey.trim().isEmpty) {
      analysisError = AppError.noAPIKey.message;
      notifyListeners();
      return;
    }

    isAnalyzing = true;
    analysisError = null;
    analysisResult = null;
    notifyListeners();

    final combinedStudyText = studyMaterials
        .map((d) => '=== ${d.name} ===\n${d.extractedText}')
        .join('\n\n');

    try {
      final result = await _geminiService.analyze(
        examQuestionsText: examQuestionsDocument?.extractedText,
        studyMaterialText: combinedStudyText,
        apiKey: _apiKey,
        model: _selectedModel,
      );
      analysisResult = result;
    } catch (e) {
      analysisError = e.toString();
    }

    isAnalyzing = false;
    notifyListeners();
  }

  /// Clears the current analysis result.
  void clearAnalysis() {
    analysisResult = null;
    analysisError = null;
    notifyListeners();
  }

  /// Clears all loaded documents and results.
  void clearAll() {
    examQuestionsDocument = null;
    studyMaterials = [];
    analysisResult = null;
    analysisError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _geminiService.dispose();
    super.dispose();
  }
}
