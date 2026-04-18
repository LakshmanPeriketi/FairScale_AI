/// Data models for bias explanation layer
class FeatureAttribution {
  final String featureName;
  final double importance;

  FeatureAttribution({
    required this.featureName,
    required this.importance,
  });

  factory FeatureAttribution.fromJson(Map<String, dynamic> json) {
    return FeatureAttribution(
      featureName: json['featureName'] as String,
      importance: (json['importance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'featureName': featureName,
    'importance': importance,
  };
}

/// Bias analysis input from model outputs
class BiasAnalysis {
  final double biasScore; // 0.0 to 1.0, where 1.0 = highest bias
  final List<FeatureAttribution> featureImportance;
  final String modelADecision; // e.g., "REJECT"
  final String modelCDecision; // e.g., "APPROVE"
  final double modelAConfidence;
  final double modelCConfidence;
  final String applicantName;
  final String? gender;
  final String? race;

  BiasAnalysis({
    required this.biasScore,
    required this.featureImportance,
    required this.modelADecision,
    required this.modelCDecision,
    required this.modelAConfidence,
    required this.modelCConfidence,
    required this.applicantName,
    this.gender,
    this.race,
  });

  factory BiasAnalysis.fromJson(Map<String, dynamic> json) {
    return BiasAnalysis(
      biasScore: (json['biasScore'] as num).toDouble(),
      featureImportance: (json['featureImportance'] as List<dynamic>?)
          ?.map((e) => FeatureAttribution.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      modelADecision: json['modelADecision'] as String,
      modelCDecision: json['modelCDecision'] as String,
      modelAConfidence: (json['modelAConfidence'] as num).toDouble(),
      modelCConfidence: (json['modelCConfidence'] as num).toDouble(),
      applicantName: json['applicantName'] as String,
      gender: json['gender'] as String?,
      race: json['race'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'biasScore': biasScore,
    'featureImportance': featureImportance.map((e) => e.toJson()).toList(),
    'modelADecision': modelADecision,
    'modelCDecision': modelCDecision,
    'modelAConfidence': modelAConfidence,
    'modelCConfidence': modelCConfidence,
    'applicantName': applicantName,
    'gender': gender,
    'race': race,
  };
}

/// Generated explanation output
class ExplanationOutput {
  final String mainExplanation;
  final String? geminiExplanation;
  final String? sdgImpactNote;
  final List<String> attributionNarrative;

  ExplanationOutput({
    required this.mainExplanation,
    this.geminiExplanation,
    this.sdgImpactNote,
    required this.attributionNarrative,
  });

  factory ExplanationOutput.fromJson(Map<String, dynamic> json) {
    return ExplanationOutput(
      mainExplanation: json['mainExplanation'] as String,
      geminiExplanation: json['geminiExplanation'] as String?,
      sdgImpactNote: json['sdgImpactNote'] as String?,
      attributionNarrative: List<String>.from(json['attributionNarrative'] as List<dynamic>? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'mainExplanation': mainExplanation,
    'geminiExplanation': geminiExplanation,
    'sdgImpactNote': sdgImpactNote,
    'attributionNarrative': attributionNarrative,
  };
}
