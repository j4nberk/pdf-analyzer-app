import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/analysis_result.dart';
import '../models/app_error.dart';

// MARK: - GeminiService
// Mirrors Swift's GeminiService from Sources/PDFAnalyzerAppCore/Services/GeminiService.swift
// Sends requests to the Google Gemini REST API and returns structured analysis results.

class GeminiService {
  final http.Client _client;

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  /// Analyzes the study material (optionally against past exam questions) and returns a structured result.
  Future<AnalysisResult> analyze({
    String? examQuestionsText,
    required String studyMaterialText,
    required String apiKey,
    String model = 'gemini-2.5-flash',
  }) async {
    if (apiKey.trim().isEmpty) {
      throw AppError.noAPIKey;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(
      examQuestionsText: examQuestionsText,
      studyMaterialText: studyMaterialText,
    );

    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.3,
        'maxOutputTokens': 8192,
      },
    };

    final http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'PDFAnalyzerApp/1.0',
        },
        body: jsonEncode(requestBody),
      );
    } catch (e) {
      throw AppError.networkError(e.toString());
    }

    if (response.statusCode != 200) {
      // Try to parse the Gemini error body
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        final apiError = errorBody['error'] as Map<String, dynamic>?;
        if (apiError != null) {
          throw AppError.apiError(
            '${apiError['message']} (kod: ${apiError['code']})',
          );
        }
      } catch (e) {
        if (e is AppError) rethrow;
      }
      throw AppError.apiError('HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> responseBody;
    try {
      responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw AppError.responseParsingFailed('JSON ayrıştırılamadı: $e');
    }

    // Check for error in response body
    if (responseBody.containsKey('error')) {
      final apiError = responseBody['error'] as Map<String, dynamic>;
      throw AppError.apiError(
        '${apiError['message']} (kod: ${apiError['code']})',
      );
    }

    // Extract candidate text from Gemini response
    final candidates = responseBody['candidates'] as List?;
    String? candidateText;

    if (candidates != null && candidates.isNotEmpty) {
      final firstCandidate = candidates.first as Map<String, dynamic>?;
      final parts = firstCandidate?['content']?['parts'] as List?;
      if (parts != null && parts.isNotEmpty) {
        final firstPart = parts.first as Map<String, dynamic>?;
        candidateText = firstPart?['text'] as String?;
      }
    }

    if (candidateText == null || candidateText.isEmpty) {
      throw AppError.responseParsingFailed('Yanıt içeriği boş');
    }

    return _parseAnalysisResult(candidateText);
  }

  // MARK: - Prompt Builder

  String _trimText(String text, int maxChars) =>
      text.length > maxChars ? text.substring(0, maxChars) : text;

  String _buildTwoDocumentPrompt(String examText, String materialText) => '''
Sen deneyimli bir eğitim asistanısın. Sana iki belge veriyorum:

1. Geçmiş Sınav Soruları Belgesi - Öğrencinin daha önce gördüğü veya çıkmış sınav soruları
2. Çalışma Materyali - Ders notları, slaytlar veya ders kitabı içeriği

---
GEÇMİŞ SINAV SORULARI:
$examText
---
ÇALIŞMA MATERYALİ:
$materialText
---

Bu iki belgeyi analiz ederek aşağıdakileri oluştur:

1. **keyPoints**: Geçmiş sınav soruları göz önüne alındığında çalışma materyalindeki en önemli 15 nokta. Her nokta kısa, net ve öğrencinin sınavda işine yarayacak bilgi içermeli.

2. **reviewTable**: Anahtar kavramları ve açıklamalarını içeren hızlı tekrar tablosu. En az 10, en fazla 15 satır. Her satırda "concept" (kavram/terim) ve "explanation" (kısa açıklama) olmalı.

3. **studyQuestions**: Çalışma materyaline ve geçmiş sınav sorularının tarzına dayalı 10 özgün çalışma sorusu. Sorular öğrenciyi düşündürmeli ve konuyu pekiştirmeli.

4. **flashcards**: Etkili ezberleme için 10 flaşkart. Her flaşkartta "question" (kısa, net bir soru) ve "answer" (özlü bir cevap) olmalı.''';

  String _buildSingleDocumentPrompt(String materialText) => '''
Sen deneyimli bir eğitim asistanısın. Sana bir çalışma materyali veriyorum:

---
ÇALIŞMA MATERYALİ:
$materialText
---

Bu belgeyi analiz ederek aşağıdakileri oluştur:

1. **keyPoints**: Çalışma materyalindeki en önemli 15 nokta. Her nokta kısa, net ve öğrencinin öğrenmesi gereken temel bilgi içermeli.

2. **reviewTable**: Anahtar kavramları ve açıklamalarını içeren hızlı tekrar tablosu. En az 10, en fazla 15 satır. Her satırda "concept" (kavram/terim) ve "explanation" (kısa açıklama) olmalı.

3. **studyQuestions**: Çalışma materyaline dayalı 10 özgün çalışma sorusu. Sorular öğrenciyi düşündürmeli ve konuyu pekiştirmeli.

4. **flashcards**: Etkili ezberleme için 10 flaşkart. Her flaşkartta "question" (kısa, net bir soru) ve "answer" (özlü bir cevap) olmalı.''';

  static const _jsonFormatInstruction = '''
YALNIZCA aşağıdaki JSON formatında yanıt ver, başka hiçbir metin ekleme:
{
  "keyPoints": ["nokta1", "nokta2", "..."],
  "reviewTable": [
    {"concept": "kavram", "explanation": "açıklama"},
    "..."
  ],
  "studyQuestions": ["soru1", "soru2", "..."],
  "flashcards": [
    {"question": "soru", "answer": "cevap"},
    "..."
  ]
}''';

  String _buildPrompt({
    String? examQuestionsText,
    required String studyMaterialText,
  }) {
    // Limit texts to avoid exceeding token limits while keeping most relevant content
    const maxChars = 30000;
    final trimmedMaterial = _trimText(studyMaterialText, maxChars);

    final hasExamQuestions =
        examQuestionsText != null && examQuestionsText.trim().isNotEmpty;

    final docSection = hasExamQuestions
        ? _buildTwoDocumentPrompt(_trimText(examQuestionsText!, maxChars), trimmedMaterial)
        : _buildSingleDocumentPrompt(trimmedMaterial);

    return '$docSection\n\n$_jsonFormatInstruction\n';
  }

  // MARK: - Response Parsing

  AnalysisResult _parseAnalysisResult(String text) {
    // Gemini sometimes wraps JSON in markdown code fences — strip them
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw AppError.responseParsingFailed('Metin JSON\'a dönüştürülemedi: $e');
    }

    try {
      return AnalysisResult.fromJson(json);
    } catch (e) {
      throw AppError.responseParsingFailed(e.toString());
    }
  }

  void dispose() {
    _client.close();
  }
}
