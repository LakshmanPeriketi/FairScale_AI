# FairScale AI - Explanation Layer Documentation

## Overview

The **Explanation Layer** is a modular Dart/Flutter service that converts raw ML model outputs into clear, human-readable explanations for the FairScale AI dashboard.

### Key Features

✅ **Bias Score Translation** — Converts numerical bias scores (0.0-1.0) into natural language  
✅ **Feature Attribution Narration** — Explains which features drove biased decisions  
✅ **Gemini 1.5 Flash Integration** — Pre-built prompt template for Gemini LLM  
✅ **UN SDG 10 Impact Notes** — Optional impact note on reduced inequalities  
✅ **JSON Serialization** — Ready for API/backend integration  
✅ **Modular & Testable** — Business logic separated from UI

---

## Architecture

### Files

```
lib/
├── models/
│   └── explanation_model.dart       # Data classes: BiasAnalysis, ExplanationOutput
├── services/
│   ├── explanation_service.dart     # Core logic
│   └── explanation_service_example.dart  # Usage examples
└── screens/
    └── detail_screen.dart           # Updated to use explanation service
```

### Data Flow

```
Model Outputs (bias score, features, decisions)
    ↓
BiasAnalysis (structured data model)
    ↓
ExplanationService.generateExplanation()
    ↓
ExplanationOutput (human-readable text + Gemini prompt)
    ↓
Dashboard Display
```

---

## API Reference

### `BiasAnalysis` (Input Model)

```dart
BiasAnalysis(
  biasScore: 0.75,              // 0.0 (fair) to 1.0 (highly biased)
  featureImportance: [
    FeatureAttribution(
      featureName: 'Zip Code',
      importance: 0.40,           // 0.0 to 1.0
    ),
  ],
  modelADecision: 'REJECT',      // Original model's decision
  modelCDecision: 'APPROVE',     // Fair model's decision
  modelAConfidence: 0.87,        // 0.0 to 1.0
  modelCConfidence: 0.91,        // 0.0 to 1.0
  applicantName: 'Jane Doe',
  gender: 'Female',
  race: 'African American',
);
```

### `ExplanationOutput` (Output Model)

```dart
ExplanationOutput(
  mainExplanation: "⚠️ Significant bias detected...",
  attributionNarrative: [
    "40.0% — Zip Code",
    "25.0% — Income",
    "20.0% — Credit history",
  ],
  sdgImpactNote: "UN SDG 10 (Reduced Inequalities)...",
  geminiExplanation: "You are a fairness expert...", // Gemini prompt
);
```

### Main API

```dart
// Generate all explanations at once
final output = ExplanationService.generateExplanation(analysis);

// Get just the natural language explanation
String explanation = ExplanationService.generateExplanation(analysis).mainExplanation;

// Get Gemini prompt for custom LLM calls
String prompt = ExplanationService.generateGeminiPrompt(analysis);

// JSON serialization (for APIs)
final json = analysis.toJson();
final restored = BiasAnalysis.fromJson(json);
```

---

## Usage Example

### In the Dashboard (Flutter UI)

See [detail_screen.dart](lib/screens/detail_screen.dart) for the full implementation.

```dart
// 1. Create bias analysis from model outputs
final analysis = BiasAnalysis(
  biasScore: 0.68,
  featureImportance: [...],
  modelADecision: 'REJECT',
  modelCDecision: 'APPROVE',
  // ... other fields
);

// 2. Generate explanation
final explanation = ExplanationService.generateExplanation(analysis);

// 3. Display in UI
Text(explanation.mainExplanation)  // Main narrative
// + attribution widget
// + SDG impact note (if applicable)

// 4. Send to Gemini (when API key is set)
final geminiPrompt = explanation.geminiExplanation;
// Send to Gemini API...
```

### Standalone Example

Run: `dart lib/services/explanation_service_example.dart`

Outputs sample explanations for high-bias and low-bias scenarios.

---

## Integration with Gemini API

### Setup

1. **Add http package** to `pubspec.yaml`:
   ```yaml
   dependencies:
     http: ^1.1.0
   ```

2. **Set environment variable** (local dev or cloud):
   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   ```

3. **Create a Gemini service** (new file):

   ```dart
   // lib/services/gemini_service.dart
   import 'package:http/http.dart' as http;
   import 'dart:convert';
   import 'explanation_service.dart';
   import '../models/explanation_model.dart';

   class GeminiService {
     static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
     
     static Future<String> generateBiasExplanation(BiasAnalysis analysis) async {
       final apiKey = String.fromEnvironment('GEMINI_API_KEY');
       final prompt = ExplanationService.generateGeminiPrompt(analysis);

       final response = await http.post(
         Uri.parse('$apiUrl?key=$apiKey'),
         headers: {'Content-Type': 'application/json'},
         body: jsonEncode({
           'contents': [
             {
               'parts': [{'text': prompt}]
             }
           ]
         }),
       );

       if (response.statusCode == 200) {
         final json = jsonDecode(response.body);
         return json['candidates'][0]['content']['parts'][0]['text'];
       } else {
         throw Exception('Gemini API error: ${response.body}');
       }
     }
   }
   ```

4. **Call Gemini from UI**:

   ```dart
   final geminiText = await GeminiService.generateBiasExplanation(analysis);
   ```

---

## Risk Levels

- **High Risk** (bias score ≥ 0.70): Urgent bias flag
- **Medium Risk** (0.40–0.69): Moderate bias requiring attention
- **Low Risk** (< 0.40): Minor bias, no SDG impact note generated

---

## Testing

### Unit Testing Example

```dart
void main() {
  test('High bias scenarios produce warning', () {
    final analysis = BiasAnalysis(
      biasScore: 0.85,
      featureImportance: [...],
      // ... other fields
    );
    
    final output = ExplanationService.generateExplanation(analysis);
    expect(output.mainExplanation.contains('⚠️'), true);
    expect(output.sdgImpactNote, isNotNull);
  });

  test('Low bias scenarios produce no SDG note', () {
    final analysis = BiasAnalysis(
      biasScore: 0.15,
      featureImportance: [...],
      // ... other fields
    );
    
    final output = ExplanationService.generateExplanation(analysis);
    expect(output.sdgImpactNote, isNull);
  });
}
```

---

## Design Decisions

1. **Static Methods** — Simple, no state needed, easy to test
2. **Modular Output** — Each explanation component is separate (main, features, SDG, Gemini) for flexible display
3. **JSON Serialization** — Ready for backend APIs or persistence
4. **Risk-Based Logic** — Thresholds (0.3, 0.7) for natural language variation
5. **Gemini Prompt as Output** — The service generates a prompt template; actual LLM calls are separate (cleaner, testable)

---

## Non-Technical Explanation Examples

### High Bias Case
> "⚠️ Significant bias detected. Jane Doe's application shows a decision mismatch: Model A recommends REJECT (87% confidence), while Model C recommends APPROVE (91% confidence). The discrepancy stems from "Zip Code", which often correlates with demographic disparities. Model C removes this constraint and focuses on direct financial metrics, providing a fairer assessment."

### Low Bias Case
> "Analysis shows low bias risk. Both models agree on low. The decision process appears fair and consistent with policies."

---

## Next Steps (Manual)

- [ ] Add `http: ^1.1.0` to pubspec.yaml dependencies
- [ ] Create `lib/services/gemini_service.dart` with Gemini API calls (see Integration section)
- [ ] Set `GEMINI_API_KEY` environment variable in deployment
- [ ] Connect backend to provide real `BiasAnalysis` data (currently using mock)
- [ ] Update `detail_screen.dart` to call Gemini service for "AI-generated" text if needed
- [ ] Add unit tests in `test/` directory
- [ ] Deploy with Firebase Cloud Functions for Gemini API calls (FE → Backend → Gemini)

---

## Files Modified/Created

✅ **Created:** `lib/models/explanation_model.dart`  
✅ **Created:** `lib/services/explanation_service.dart`  
✅ **Created:** `lib/services/explanation_service_example.dart`  
✅ **Updated:** `lib/screens/detail_screen.dart` (imports + usage)  

---

## Questions?

See the example file or refer to existing screens for integration patterns.
