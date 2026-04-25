import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/explanation_model.dart';

/// Explanation Service
/// Transforms model outputs (bias scores, feature importance, decisions)
/// into clear, human-readable explanations for the dashboard and Gemini.
class ExplanationService {
  
  static Future<String> getGeminiAnalysis(BiasAnalysis analysis) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) return "API Key not found.";

      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final prompt = generateGeminiPrompt(analysis);
      
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? generateExplanation(analysis).mainExplanation;
    } catch (e) {
      print("Gemini API Error: $e");
      // Fallback to local template on any API error (Key, Model, or Quota)
      return generateExplanation(analysis).mainExplanation;
    }
  }

  /// Generate a natural language explanation from bias analysis data
  static ExplanationOutput generateExplanation(BiasAnalysis analysis) {
    final mainExplanation = _generateMainExplanation(analysis);
    final attributionNarrative = _generateAttributionNarrative(analysis);
    final sdgNote = _generateSDGImpactNote(analysis);
    final geminiPrompt = generateGeminiPrompt(analysis);

    return ExplanationOutput(
      mainExplanation: mainExplanation,
      attributionNarrative: attributionNarrative,
      sdgImpactNote: sdgNote,
      geminiExplanation: geminiPrompt,
    );
  }

  /// Core explanation text generator
  /// Converts bias score and feature importance into non-technical prose
  static String _generateMainExplanation(BiasAnalysis analysis) {
    final decisionDifference = analysis.modelADecision != analysis.modelCDecision;
    final riskLevel = _getRiskLevel(analysis.biasScore);
    final topBiasFeature = _getTopBiasFeature(analysis.featureImportance);

    if (!decisionDifference) {
      return 'Analysis shows low bias risk. Both models agree on $riskLevel. '
          'The decision process appears fair and consistent with policies.';
    }

    final explanation = StringBuffer();

    if (riskLevel == 'high') {
      explanation.write('⚠️ Significant bias detected. ');
    } else if (riskLevel == 'medium') {
      explanation.write('⚡ Moderate bias flag. ');
    } else {
      explanation.write('ℹ️ Minor bias detected. ');
    }

    explanation.write('${analysis.applicantName}\'s application shows a decision mismatch: '
        'Model A recommends ${analysis.modelADecision} (${(analysis.modelAConfidence * 100).toStringAsFixed(0)}% confidence), '
        'while Model C recommends ${analysis.modelCDecision} (${(analysis.modelCConfidence * 100).toStringAsFixed(0)}% confidence). ');

    if (topBiasFeature != null) {
      explanation.write('The discrepancy stems from "${topBiasFeature.featureName}", '
          'which often correlates with demographic disparities. ');
    }

    explanation.write('Model C removes this constraint and focuses on direct financial metrics, '
        'providing a fairer assessment.');

    return explanation.toString();
  }

  /// Generate human-friendly narration of feature attributions
  static List<String> _generateAttributionNarrative(BiasAnalysis analysis) {
    if (analysis.featureImportance.isEmpty) {
      return ['No feature attribution data available.'];
    }

    final narrative = <String>[];
    final sorted = List<FeatureAttribution>.from(analysis.featureImportance)
      ..sort((a, b) => b.importance.compareTo(a.importance));

    for (var i = 0; i < sorted.take(3).length; i++) {
      final feature = sorted[i];
      final percentage = (feature.importance * 100).toStringAsFixed(1);
      narrative.add('$percentage% — ${feature.featureName}');
    }

    return narrative;
  }

  /// Generate UN SDG 10 (Reduced Inequalities) impact note
  static String? _generateSDGImpactNote(BiasAnalysis analysis) {
    if (analysis.biasScore < 0.3) {
      return null; // Skip for low-bias scenarios
    }

    return 'UN SDG 10 (Reduced Inequalities): Applying fair model decisions '
        'reduces lending discrimination and promotes equitable access to financial services '
        'for underrepresented communities.';
  }

  /// Generate a Gemini 1.5 Flash prompt for explanation generation
  /// Returns a structured prompt string that can be sent to Gemini API
  static String generateGeminiPrompt(BiasAnalysis analysis) {
    final topFeatures = _getTopNFeatures(analysis.featureImportance, 3)
        .map((f) => '"${f.featureName}" (${(f.importance * 100).toStringAsFixed(1)}%)')
        .join(', ');

    return '''
You are a fairness and bias explanation expert for a lending AI system.

Based on the following model evaluation, generate a brief, non-technical explanation 
suitable for a bank manager. Keep it under 150 words. Use plain language, no jargon.

Applicant: ${analysis.applicantName}
Demographics: Gender: ${analysis.gender ?? 'not provided'}, Race/Ethnicity: ${analysis.race ?? 'not provided'}

Model A (Biased): ${analysis.modelADecision} (${(analysis.modelAConfidence * 100).toStringAsFixed(0)}% confidence)
- Heavily influenced by: $topFeatures

Model C (Fair): ${analysis.modelCDecision} (${(analysis.modelCConfidence * 100).toStringAsFixed(0)}% confidence)
- Uses only validated financial metrics

Bias Risk Level: ${_getRiskLevel(analysis.biasScore)}
Overall Bias Score: ${(analysis.biasScore * 100).toStringAsFixed(1)}%

Generate a concise explanation that:
1. Identifies the bias risk
2. Explains which feature caused the mismatch
3. Recommends applying Model C's fair decision
4. Explains the business/ethical benefit

Do not list detailed metrics. Focus on the "why" and "so what".
''';
  }

  /// Helper: Get risk level label from bias score
  static String _getRiskLevel(double biasScore) {
    if (biasScore >= 0.7) return 'high';
    if (biasScore >= 0.4) return 'medium';
    return 'low';
  }

  /// Helper: Get top bias-contributing feature
  static FeatureAttribution? _getTopBiasFeature(List<FeatureAttribution> features) {
    if (features.isEmpty) return null;
    return features.reduce((a, b) => a.importance > b.importance ? a : b);
  }

  /// Helper: Get top N features by importance
  static List<FeatureAttribution> _getTopNFeatures(
    List<FeatureAttribution> features,
    int n,
  ) {
    if (features.isEmpty) return [];
    final sorted = List<FeatureAttribution>.from(features)
      ..sort((a, b) => b.importance.compareTo(a.importance));
    return sorted.take(n).toList();
  }
}
