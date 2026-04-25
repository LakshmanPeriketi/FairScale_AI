import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';
import 'dart:math';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({Key? key}) : super(key: key);

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  final Random _random = Random();

  String _generateKey(String prefix) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return "${prefix}_${List.generate(12, (index) => chars[_random.nextInt(chars.length)]).join()}";
  }

  Future<void> _seedInitialData() async {
    final snapshot = await FirebaseFirestore.instance.collection('deployments').get();
    if (snapshot.docs.isEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      final items = [
        {
          "name": "Census-Lending-v1 (Live)",
          "key": _generateKey("fs_live"),
          "dataset": "UCI Adult Census Income (Subset: 5,000)",
          "features": "Age, Occupation, Education, Gender, Race...",
          "status": "ACTIVE",
          "timestamp": FieldValue.serverTimestamp(),
        },
        {
          "name": "Demographic-Parity-Beta",
          "key": _generateKey("fs_beta"),
          "dataset": "LendingClub Prototype (Subset: 2,500)",
          "features": "Credit_Score, Debt_Ratio, Employment...",
          "status": "INACTIVE",
          "timestamp": FieldValue.serverTimestamp(),
        },
      ];
      for (var item in items) {
        batch.set(FirebaseFirestore.instance.collection('deployments').doc(), item);
      }
      await batch.commit();
    }
  }

  @override
  void initState() {
    super.initState();
    _seedInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text("Project Registry", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('deployments').add({
                "name": "Manual-Deployment-v${DateTime.now().millisecond}",
                "key": _generateKey("fs_live"),
                "dataset": "Manual_Seed_Update",
                "features": "Age, Education, Merit_Score, Risk_Factor",
                "status": "ACTIVE",
                "timestamp": FieldValue.serverTimestamp(),
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("New Project API Generated & Saved!")),
              );
            },
            icon: const Icon(Icons.add, color: Colors.indigoAccent),
            label: const Text("NEW PROJECT", style: TextStyle(color: Colors.indigoAccent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('deployments')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final Map<String, String> dep = data.map((key, value) => MapEntry(key, value.toString()));
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildExpandableDeploymentCard(context, dep),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildExpandableDeploymentCard(BuildContext context, Map<String, String> dep) {
    final status = dep['status']!;
    final isLive = status == "ACTIVE";
    final activeColor = status == "DEPRECATED" ? Colors.redAccent : (isLive ? Colors.greenAccent : Colors.white24);
    final endpointUrl = "https://api.fairscale.ai/v1/intercept?key=${dep['key']}";

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.white70,
          iconColor: Colors.indigoAccent,
          title: Text(
            dep['name']!,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: activeColor.withOpacity(0.5)),
            ),
            child: Text(
              status,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activeColor),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Dataset", dep['dataset']!),
                  _buildInfoRow("Features", dep['features']!),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 16),
                  const Text("Generated Interceptor API:", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            endpointUrl,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.blueAccent),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: endpointUrl));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("API Endpoint copied to clipboard!")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
