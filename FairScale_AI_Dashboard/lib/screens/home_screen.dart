import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'scanning_screen.dart';
import 'metadata_screen.dart';
import '../widgets/glass_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Stream<List<Map<String, dynamic>>> _pendingStream = FirebaseFirestore.instance
      .collection('applications')
      .where('status', isEqualTo: 'pending')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        "id": doc.id,
        "name": data["name"] ?? "Unknown",
        "income": data["income"] ?? 0,
        "gender": data["gender"] ?? "Unknown",
        "risk": data["status"] == "healed" 
            ? "Healed" 
            : (data["modelB_biasFlag"] == "Bias Suspected" ? "High" : (data["status"] == "pending" ? "Medium" : "Low")),
        ...data
      };
    }).toList();
  });

  List<Map<String, dynamic>> initialData = [];
  bool _isBackendLive = false;
  Timer? _heartbeatTimer;

  @override
  void initState() {
    super.initState();
    _startHeartbeat();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        // In a real app, use a proper package, here we just check for demo visibility
        setState(() {
          _isBackendLive = true; // Simulating successful ping for demo
        });
      } catch (_) {
        setState(() => _isBackendLive = false);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Live Application Feed",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
          ),
          const SizedBox(height: 8),
          const Text("Real-time interception queue awaiting FairScale AI verification.", style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 32),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _pendingStream,
              initialData: initialData,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final apps = snapshot.data!;
                return ListView.builder(
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ApplicationCard(appData: apps[index]),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> appData;

  const ApplicationCard({Key? key, required this.appData}) : super(key: key);

  String _getRiskLevel(double score) {
    if (score >= 0.7) return "High";
    if (score >= 0.4) return "Medium";
    return "Low";
  }

  Color _getRiskColor(String risk) {
    switch (risk) {
      case "High": return Colors.deepPurpleAccent;
      case "Medium": return Colors.orangeAccent;
      case "Low": 
      case "Healed": return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double biasScore = double.tryParse(appData['bias_score']?.toString() ?? '0.0') ?? 0.0;
    final String risk = appData['status'] == 'healed' ? "Healed" : _getRiskLevel(biasScore);
    final riskColor = _getRiskColor(risk);
    
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        title: Text(
          appData["name"] ?? "Anonymous Applicant",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Occupation: ${appData["Occupation"] ?? 'N/A'} • Income: \$${appData["income"] ?? appData["Capital_Gain"] ?? 'N/A'}", 
            style: const TextStyle(color: Colors.black45)
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: riskColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: riskColor.withOpacity(0.2)),
          ),
          child: Text(
            risk == "Healed" ? "✅ Fairness Applied" : "$risk Risk detected",
            style: TextStyle(
              color: riskColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => ScanningScreen(appData: appData),
              transitionDuration: const Duration(milliseconds: 500),
              transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
            ),
          );
        },
      ),
    );
  }
}
