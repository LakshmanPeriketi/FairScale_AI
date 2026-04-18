import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../models/explanation_model.dart';
import 'explanation_service.dart';

/// Gemini 1.5 Flash API Service
/// Calls Google's Gemini API to generate AI-powered bias explanations
class GeminiService {
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Generate a bias explanation using Gemini 1.5 Flash
  /// 
  /// Calls the Gemini API with a structured prompt about the bias analysis
  /// Returns a natural language explanation optimized for bank managers
  static Future<String> generateBiasExplanation(BiasAnalysis analysis) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'GEMINI_API_KEY not set in .env file. '
        'Copy .env.example to .env and add your Gemini API key.',
      );
    }

    final prompt = ExplanationService.generateGeminiPrompt(analysis);

    try {
      final response = await http
          .post(
            Uri.parse('$_apiUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt}
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 200,
                'temperature': 0.7,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final text = json['candidates'][0]['content']['parts'][0]['text'];
        return text as String;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid GEMINI_API_KEY: ${response.body}');
      } else if (response.statusCode == 429) {
        throw Exception('Rate limited by Gemini API. Try again later.');
      } else {
        throw Exception(
          'Gemini API error (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Batch generate explanations for multiple applications
  /// Useful for processing queued applications
  static Future<Map<String, String>> generateBatchExplanations(
    List<BiasAnalysis> analyses,
  ) async {
    final results = <String, String>{};

    for (final analysis in analyses) {
      try {
        final explanation = await generateBiasExplanation(analysis);
        results[analysis.applicantName] = explanation;
      } catch (e) {
        results[analysis.applicantName] = 'Error: $e';
      }
    }

    return results;
  }
}
