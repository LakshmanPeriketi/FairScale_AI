/// Example & Test Usage for ExplanationService
/// 
/// This demonstrates how to use the explanation layer with sample data.
/// To run: dart lib/services/explanation_service_example.dart

import '../models/explanation_model.dart';
import 'explanation_service.dart';

void main() {
  // Example 1: Simple bias analysis
  final sampleAnalysis = BiasAnalysis(
    biasScore: 0.75,
    featureImportance: [
      FeatureAttribution(featureName: 'Zip Code (proxy for location)', importance: 0.40),
      FeatureAttribution(featureName: 'Income', importance: 0.25),
      FeatureAttribution(featureName: 'Credit history', importance: 0.20),
      FeatureAttribution(featureName: 'Employment length', importance: 0.15),
    ],
    modelADecision: 'REJECT',
    modelCDecision: 'APPROVE',
    modelAConfidence: 0.82,
    modelCConfidence: 0.89,
    applicantName: 'Jane Doe',
    gender: 'Female',
    race: 'African American',
  );

  // Generate explanation
  final explanation = ExplanationService.generateExplanation(sampleAnalysis);

  print('=== FAIRSCALE AI EXPLANATION LAYER ===\n');
  print('Main Explanation:');
  print(explanation.mainExplanation);
  print('\n---\n');

  print('Feature Attribution Narrative:');
  for (final line in explanation.attributionNarrative) {
    print('  $line');
  }
  print('\n---\n');

  if (explanation.sdgImpactNote != null) {
    print('UN SDG 10 Impact:');
    print(explanation.sdgImpactNote);
    print('\n---\n');
  }

  print('Gemini 1.5 Flash Prompt Template:');
  print(explanation.geminiExplanation);
  print('\n---\n');

  // Example 2: Low bias scenario
  final lowBiasAnalysis = BiasAnalysis(
    biasScore: 0.15,
    featureImportance: [
      FeatureAttribution(featureName: 'Income', importance: 0.50),
      FeatureAttribution(featureName: 'Credit score', importance: 0.35),
      FeatureAttribution(featureName: 'Employment duration', importance: 0.15),
    ],
    modelADecision: 'APPROVE',
    modelCDecision: 'APPROVE',
    modelAConfidence: 0.92,
    modelCConfidence: 0.93,
    applicantName: 'John Smith',
    gender: 'Male',
    race: 'White',
  );

  final lowBiasExplanation = ExplanationService.generateExplanation(lowBiasAnalysis);

  print('=== LOW BIAS SCENARIO ===\n');
  print(lowBiasExplanation.mainExplanation);
  print('\n(Note: SDG impact note is omitted for low-bias scenarios)\n');

  // Example 3: JSON serialization (for API calls)
  print('=== JSON EXAMPLE (for API integration) ===\n');
  print('Input JSON:');
  print(sampleAnalysis.toJson());
  print('\nOutput JSON:');
  print(explanation.toJson());
}
