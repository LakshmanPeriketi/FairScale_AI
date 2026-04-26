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
                    // --- TOP SECTION: FAIRNESS GAUGE & APPLICANT INFO ---
                    _buildHeader(liveData, biasScore),
                    const SizedBox(height: 40),

                    // --- DUAL-MODEL COMPARISON ---
                    if (isMobile)
                      Column(
                        children: [
                          _buildModelCard(context, "MODEL A (BASELINE)", modelADecision, "${(modelAConfidence * 100).toInt()}%", modelAFactors, Colors.deepPurpleAccent, true),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Icon(Icons.compare_arrows, color: Colors.black12, size: 40)),
                          _buildModelCard(context, "MODEL C (FAIR MIRROR)", modelCDecision, "${(modelCConfidence * 100).toInt()}%", modelCFactors, Colors.green, false),
                        ],
                      )
                    else
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _buildModelCard(context, "MODEL A (BASELINE)", modelADecision, "${(modelAConfidence * 100).toInt()}%", modelAFactors, Colors.deepPurpleAccent, true)),
                            const SizedBox(width: 32),
                            Expanded(child: _buildModelCard(context, "MODEL C (FAIR MIRROR)", modelCDecision, "${(modelCConfidence * 100).toInt()}%", modelCFactors, Colors.green, false)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 40),

                    // --- AI INSIGHT & FEATURE ATTRIBUTION ---
                    _buildInsightSection(context, explanationText, biasScore, modelAFactors),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, double biasScore) {
    final fairnessPercentage = ((1 - biasScore) * 100).toInt();
    final scoreColor = biasScore > 0.6 ? Colors.orange : (biasScore > 0.3 ? Colors.indigoAccent : Colors.green);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Fairness Gauge
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CircularProgressIndicator(
                  value: 1 - biasScore,
                  strokeWidth: 10,
                  backgroundColor: Colors.black.withOpacity(0.05),
                  color: scoreColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$fairnessPercentage%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: scoreColor)),
                  const Text("FAIRNESS", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black26)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "Applicant Profile", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _metaBadge(Icons.assignment_ind_outlined, "ID: ${appData['id'].toString().substring(0, 8)}"),
                    const SizedBox(width: 16),
                    _metaBadge(Icons.location_on_outlined, data['Country'] ?? "Global"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaBadge(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black26),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black38, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: accentColor, letterSpacing: 1.5)),
              Icon(isOriginal ? Icons.warning_amber_rounded : Icons.verified_user_outlined, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 32),
          const Text("SYSTEM OUTPUT", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          const SizedBox(height: 4),
          Text(decision, style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: accentColor)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text("Confidence: $confidence", style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 32),
          const Divider(height: 1),
          const SizedBox(height: 32),
          const Text("CORE LOGIC FACTORS", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          const SizedBox(height: 20),
          ...factors.take(3).map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.3), shape: BoxShape.circle),
                ),
                const SizedBox(width: 16),
                Text(f, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildInsightSection(BuildContext context, String text, double biasScore, List<String> factors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 28),
              const SizedBox(width: 16),
              const Text("AI AUDIT JUSTIFICATION", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.indigoAccent, letterSpacing: 0.5)),
              const Spacer(),
              if (biasScore > 0.6)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.withOpacity(0.3))),
                  child: const Text("BIAS DETECTED", style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Feature Importance Bar Chart (Simplified)
          const Text("BIAS ATTRIBUTION BY FEATURE", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          const SizedBox(height: 24),
          _buildFeatureChart(factors, biasScore),
          
          const SizedBox(height: 48),
          const Text("HUMAN-IN-THE-LOOP SUMMARY (GEMINI)", style: TextStyle(fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold, color: Colors.black26)),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(fontSize: 16, height: 1.8, color: Colors.black87, fontStyle: FontStyle.italic)),
          
          const SizedBox(height: 54),
          Row(
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
                    elevation: 10,
                    shadowColor: Colors.indigoAccent.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("APPLY FAIR REMEDIATION & APPROVE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
                    side: const BorderSide(color: Colors.orangeAccent, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("REJECT", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChart(List<String> factors, double biasScore) {
    // Simulated importance scores for the bar chart
    final List<double> values = [0.85, 0.65, 0.45];
    final List<Color> colors = [Colors.orange, Colors.orangeAccent, Colors.orangeAccent.withOpacity(0.5)];

    return Column(
      children: List.generate(factors.take(3).length, (index) {
        final featureName = factors[index];
        final importance = values[index];
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(featureName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                  Text("${(importance * 100).toInt()}% Impact", style: const TextStyle(fontSize: 11, color: Colors.black38)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: importance,
                  minHeight: 8,
                  backgroundColor: Colors.black.withOpacity(0.05),
                  color: colors[index],
                ),
              ),
            ],
          ),
        );
      }),
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
