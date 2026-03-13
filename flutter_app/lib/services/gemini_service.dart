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

  /// Analyzes the study material against past exam questions and returns a structured result.
  Future<AnalysisResult> analyze({
    required String examQuestionsText,
    required String studyMaterialText,
    required String apiKey,
    String model = 'gemini-2.0-flash',
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
    final candidateText = candidates
        ?.cast<Map<String, dynamic>>()
        .firstOrNull?['content']?['parts']
        ?.cast<Map<String, dynamic>>()
        .firstOrNull?['text'] as String?;

    if (candidateText == null || candidateText.isEmpty) {
      throw AppError.responseParsingFailed('Yanıt içeriği boş');
    }

    return _parseAnalysisResult(candidateText);
  }

  // MARK: - Prompt Builder

  String _buildPrompt({
    required String examQuestionsText,
    required String studyMaterialText,
  }) {
    // Limit texts to avoid exceeding token limits while keeping most relevant content
    const maxChars = 30000;
    final trimmedExam = examQuestionsText.length > maxChars
        ? examQuestionsText.substring(0, maxChars)
        : examQuestionsText;
    final trimmedMaterial = studyMaterialText.length > maxChars
        ? studyMaterialText.substring(0, maxChars)
        : studyMaterialText;

    return '''
Sen deneyimli bir eğitim asistanısın. Sana iki belge veriyorum:

1. Geçmiş Sınav Soruları Belgesi - Öğrencinin daha önce gördüğü veya çıkmış sınav soruları
2. Çalışma Materyali - Ders notları, slaytlar veya ders kitabı içeriği

---
GEÇMİŞ SINAV SORULARI:
$trimmedExam
---
ÇALIŞMA MATERYALİ:
$trimmedMaterial
---

Bu iki belgeyi analiz ederek aşağıdakileri oluştur:

1. **keyPoints**: Geçmiş sınav soruları göz önüne alındığında çalışma materyalindeki en önemli 15 nokta. Her nokta kısa, net ve öğrencinin sınavda işine yarayacak bilgi içermeli.

2. **reviewTable**: Anahtar kavramları ve açıklamalarını içeren hızlı tekrar tablosu. En az 10, en fazla 15 satır. Her satırda "concept" (kavram/terim) ve "explanation" (kısa açıklama) olmalı.

3. **studyQuestions**: Çalışma materyaline ve geçmiş sınav sorularının tarzına dayalı 10 özgün çalışma sorusu. Sorular öğrenciyi düşündürmeli ve konuyu pekiştirmeli.

4. **flashcards**: Etkili ezberleme için 10 flaşkart. Her flaşkartta "question" (kısa, net bir soru) ve "answer" (özlü bir cevap) olmalı.

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
}
''';
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
