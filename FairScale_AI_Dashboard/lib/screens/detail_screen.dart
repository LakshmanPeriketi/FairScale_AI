import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import '../models/explanation_model.dart';
import '../services/explanation_service.dart';

class DetailScreen extends StatelessWidget {
  final Map<String, dynamic> appData;

  const DetailScreen({Key? key, required this.appData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Shield Evaluation: ${appData["name"] ?? "Applicant"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('applications').doc(appData['id']).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final liveData = snapshot.data!.data() as Map<String, dynamic>;
          final biasScore = double.tryParse(liveData['bias_score']?.toString() ?? '0.0') ?? 0.0;
          final modelADecision = liveData['model_a_decision'] ?? "REJECT";
          final modelCDecision = liveData['model_c_decision'] ?? "APPROVE";
          final modelAConfidence = (double.tryParse(liveData['model_a_confidence']?.toString() ?? '1.0') ?? 1.0);
          final modelCConfidence = (double.tryParse(liveData['model_c_confidence']?.toString() ?? '1.0') ?? 1.0);
          final List<String> modelAFactors = List<String>.from(liveData['model_a_factors'] ?? ["Demographic Correlation", "Historical weights"]);
          final List<String> modelCFactors = List<String>.from(liveData['model_c_factors'] ?? ["Merit prioritized", "Bias neutralized"]);

          String firebaseEx = (liveData['gemini_explanation'] ?? "").toString().trim();
          String explanationText = firebaseEx;

          if (firebaseEx.isEmpty || firebaseEx.contains("Analyzing") || firebaseEx.length < 5) {
              final analysis = BiasAnalysis(
                  biasScore: biasScore,
                  featureImportance: modelAFactors.map((f) => FeatureAttribution(featureName: f, importance: 0.25)).toList(),
                  modelADecision: modelADecision,
                  modelCDecision: modelCDecision,
                  modelAConfidence: modelAConfidence,
                  modelCConfidence: modelCConfidence,
                  applicantName: liveData['name'] ?? 'Applicant',
                  gender: liveData['Sex'] ?? liveData['gender'],
                  race: liveData['Race'] ?? liveData['race'],
              );
              explanationText = ExplanationService.generateExplanation(analysis).mainExplanation;
              ExplanationService.getGeminiAnalysis(analysis).then((geminiText) {
                FirebaseFirestore.instance.collection('applications').doc(appData['id']).update({'gemini_explanation': geminiText});
              }).catchError((e) => debugPrint("FairScale Gemini Error: $e"));
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 800;
          
              return SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isMobile)
                      Column(
                        children: [
                          _buildModelCard(context, "Model A (Ingest)", modelADecision, "${(modelAConfidence * 100).toInt()}%", modelAFactors, Colors.deepPurpleAccent, true),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Icon(Icons.compare_arrows, color: Colors.black12, size: 40)),
                          _buildModelCard(context, "Model C (Mirror)", modelCDecision, "${(modelCConfidence * 100).toInt()}%", modelCFactors, Colors.green, false),
                        ],
                      )
                    else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildModelCard(context, "Model A (Ingest)", modelADecision, "${(modelAConfidence * 100).toInt()}%", modelAFactors, Colors.deepPurpleAccent, true)),
                            const SizedBox(width: 32),
                            Expanded(child: _buildModelCard(context, "Model C (Mirror)", modelCDecision, "${(modelCConfidence * 100).toInt()}%", modelCFactors, Colors.green, false)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),
                    _buildInsightSection(context, explanationText, biasScore),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModelCard(BuildContext context, String title, String decision, String confidence, List<String> factors, Color accentColor, bool isOriginal) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 2),
        boxShadow: [BoxShadow(color: accentColor.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isOriginal ? Icons.warning_amber_rounded : Icons.verified_user_outlined, color: accentColor),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 32),
          const Text("OUTCOME", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          Text(decision, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 8),
          Text("Confidence Score: $confidence", style: const TextStyle(color: Colors.black38, fontSize: 13)),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          const Text("DETERMINING FACTORS", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          const SizedBox(height: 16),
          ...factors.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: accentColor.withOpacity(0.4)),
                const SizedBox(width: 12),
                Text(f, style: const TextStyle(color: Colors.black87, fontSize: 14)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInsightSection(BuildContext context, String text, double biasScore) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.indigoAccent.withOpacity(0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.indigoAccent),
              const SizedBox(width: 12),
              const Text("FairScale Audit Insight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigoAccent)),
              const Spacer(),
              if (biasScore > 0.6)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text("BIAS SUSPECTED", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(text, style: const TextStyle(fontSize: 15, height: 1.8, color: Colors.black87)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('applications').doc(appData['id']).update({
                        'status': 'decided',
                        'final_decision': 'APPROVE',
                      });
                      _showSuccessDialog(context, "Decision Approved");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("APPLY FAIRNESS & APPROVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('applications').doc(appData['id']).update({
                        'status': 'decided',
                        'final_decision': 'REJECT',
                      });
                      _showSuccessDialog(context, "Application Rejected");
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      side: const BorderSide(color: Colors.orangeAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("REJECT", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showSuccessDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(40),
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.verified_outlined, size: 60, color: Colors.green),
              ),
              const SizedBox(height: 32),
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              Text(
                "The application logic has healed successfully. ${appData['name']}'s outcome has been adjusted using Model C's fair recommendation.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(ctx); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("RETURN TO FEED", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
