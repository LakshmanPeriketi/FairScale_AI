import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 40),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildQuickStats(),
                  const SizedBox(height: 40),
                  _buildWorkingInstructions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome to FairScale Command Center",
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
        ),
        const SizedBox(height: 8),
        const Text("Your shield against algorithmic bias is currently active.", style: TextStyle(color: Colors.black54, fontSize: 16)),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        _statCard("Total Scans", "1,248", Icons.analytics, Colors.blue),
        const SizedBox(width: 20),
        _statCard("Biases Blocked", "84", Icons.gpp_good, Colors.green),
        const SizedBox(width: 20),
        _statCard("Avg Fair Score", "98.2%", Icons.balance, Colors.orange),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.black45, fontSize: 14)),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingInstructions() {
    return GlassCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("How to Secure Your Bank", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          _stepItem(1, "Create a Project", "Upload your historical loan dataset to train the Tripartite AI Engines (Models A, B, and C)."),
          _stepItem(2, "Generate API Key", "Once trained, FairScale generates a unique Interceptor URL for your bank's backend."),
          _stepItem(3, "Intercept Loans", "Your backend sends every new loan to FairScale. We audit it in 50ms and return a fair decision."),
          _stepItem(4, "Monitor Dashboard", "View every correction and AI-reasoning in the 'Interception' tab to maintain compliance."),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.indigoAccent),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    "Note: Model C (Fair Mirror) will only activate if Model B detects a bias correlation above 0.5 in the original decision.",
                    style: TextStyle(color: Colors.indigoAccent, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(int num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(backgroundColor: Colors.indigoAccent, radius: 14, child: Text(num.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
