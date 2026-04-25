import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Stream<QuerySnapshot> _deploymentsStream = FirebaseFirestore.instance
      .collection('deployments')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Manager Portal",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text("IDENTITY VERIFIED", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPersonalDetails(),
              const SizedBox(width: 40),
              Expanded(child: _buildProjectVault()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return SizedBox(
      width: 400,
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.indigoAccent,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Lakshman Periketi", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("Head of AI Governance", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Text("ENTERPRISE ADMIN", style: TextStyle(color: Colors.indigoAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            const Divider(),
            _profileInfo(Icons.email_outlined, "lakshman@fairscale.ai"),
            _profileInfo(Icons.security_outlined, "Biometric Auth Active"),
            _profileInfo(Icons.history, "Last Audit: 12m ago"),
          ],
        ),
      ),
    );
  }

  Widget _profileInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigoAccent, size: 20),
          const SizedBox(width: 15),
          Text(text, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildProjectVault() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("API Lifecycle Management", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Text("AUTO-SYNC ACTIVE", style: TextStyle(color: Colors.indigoAccent, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: _deploymentsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.02), borderRadius: BorderRadius.circular(20)),
                child: const Center(child: Text("No projects found. Create one to begin audit.", style: TextStyle(color: Colors.black38))),
              );
            }

            return Column(
              children: docs.map((doc) => _apiCard(doc.id, doc.data() as Map<String, dynamic>)).toList(),
            );
          }
        ),
      ],
    );
  }

  String? _expandedApiId;

  Widget _apiCard(String docId, Map<String, dynamic> project) {
    bool isExpanded = _expandedApiId == docId;
    String rawStatus = project['status'] ?? "Live (Active)";
    
    String status = "Live (Active)";
    if (rawStatus.contains("Live") || rawStatus == "ACTIVE") status = "Live (Active)";
    else if (rawStatus.contains("Paused") || rawStatus == "NON-ACTIVE") status = "Paused (Dormant)";
    else if (rawStatus.contains("Terminated") || rawStatus == "TERMINATED") status = "Terminated (Revoked)";

    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case "Live (Active)":
        statusColor = Colors.green;
        statusIcon = Icons.sensors;
        break;
      case "Paused (Dormant)":
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle_outline;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.cancel_outlined;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _expandedApiId = isExpanded ? null : docId),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Icon(statusIcon, color: statusColor, size: 28),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(project['name'] ?? "Unnamed Project", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(project['key'] ?? "pending...", style: TextStyle(fontFamily: 'monospace', color: Colors.black38, fontSize: 13, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    _statusPicker(docId, status, statusColor),
                    const SizedBox(width: 12),
                    Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.black12),
                  ],
                ),
              ),
              if (isExpanded) _buildApiDetails(project),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiDetails(Map<String, dynamic> project) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _detailSection(
                  "PROTECTED ATTRIBUTES", 
                  project['biasedFeatures'] ?? project['features']?.split(',').take(2).join(', ') ?? "Gender, Race, Age",
                  Colors.orange,
                  Icons.warning_amber_rounded
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _detailSection(
                  "TARGET OUTCOME", 
                  project['targetColumn'] ?? "Income >50K",
                  Colors.indigoAccent,
                  Icons.track_changes
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _detailSection(
            "MERIT FEATURES (REMEDIATION)", 
            project['meritFeatures'] ?? "Occupation, Education, Capital_Gain, Hours_per_week",
            Colors.green,
            Icons.verified_user_outlined
          ),
          const SizedBox(height: 24),
          _detailSection(
            "TRAINING DATASET", 
            project['dataset'] ?? "Census_Audit_v1.csv (50,000 samples)",
            Colors.black54,
            Icons.storage_outlined
          ),
        ],
      ),
    );
  }

  Widget _detailSection(String title, String value, Color color, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _statusPicker(String docId, String currentStatus, Color statusColor) {
    const List<Map<String, dynamic>> items = [
      {"label": "Live (Active)", "color": Colors.green, "icon": Icons.sensors},
      {"label": "Paused (Dormant)", "color": Colors.orange, "icon": Icons.pause_circle_outline},
      {"label": "Terminated (Revoked)", "color": Colors.red, "icon": Icons.cancel_outlined},
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((i) => i['label'] == currentStatus) ? currentStatus : items.first['label'],
          icon: Icon(Icons.keyboard_arrow_down, color: statusColor, size: 18),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item['label'],
              child: Row(
                children: [
                  Icon(item['icon'], color: item['color'], size: 16),
                  const SizedBox(width: 10),
                  Text(
                    item['label'],
                    style: TextStyle(color: item['color'], fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              FirebaseFirestore.instance.collection('deployments').doc(docId).update({'status': val});
            }
          },
        ),
      ),
    );
  }
}
