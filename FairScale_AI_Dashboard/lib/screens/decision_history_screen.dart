import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/glass_card.dart';

class DecisionHistoryScreen extends StatefulWidget {
  const DecisionHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DecisionHistoryScreen> createState() => _DecisionHistoryScreenState();
}

class _DecisionHistoryScreenState extends State<DecisionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Decision History",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.indigo[900], letterSpacing: -1),
                  ),
                  const SizedBox(height: 4),
                  const Text("Archives of all processed and remediated applications.", style: TextStyle(color: Colors.black38)),
                ],
              ),
              const Spacer(),
              _buildStatsBadge(),
            ],
          ),
          const SizedBox(height: 40),
          
          Row(
            children: [
              Container(
                height: 50,
                width: 380,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.indigoAccent,
                  unselectedLabelColor: Colors.black38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: "ACCEPTED"),
                    Tab(text: "REJECTED"),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: "Search by applicant name...",
                      hintStyle: TextStyle(color: Colors.black26, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 20, color: Colors.black26),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDecisionList("APPROVE"),
                _buildDecisionList("REJECT"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('applications')
          .where('final_decision', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final name = (doc.data() as Map)['name']?.toString().toLowerCase() ?? "";
            return name.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.indigoAccent.withOpacity(0.03), shape: BoxShape.circle),
                  child: Icon(Icons.inbox_outlined, size: 48, color: Colors.indigoAccent.withOpacity(0.2)),
                ),
                const SizedBox(height: 20),
                Text(
                  _searchQuery.isNotEmpty ? "No results for '$_searchQuery'" : "No ${type.toLowerCase()}d applications yet.", 
                  style: const TextStyle(color: Colors.black26, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HistoryCard(data: data),
            );
          },
        );
      },
    );
  }

  Widget _buildStatsBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final decisions = snapshot.data!.docs.where((d) => (d.data() as Map)['final_decision'] != null).toList();
        final approved = decisions.where((d) => (d.data() as Map)['final_decision'] == "APPROVE").length;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.blueAccent]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.indigoAccent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.white, size: 18),
              const SizedBox(width: 12),
              Text(
                "${decisions.length} TOTAL DECISIONS",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.white24),
              const SizedBox(width: 12),
              Text(
                "${((approved / (decisions.isEmpty ? 1 : decisions.length)) * 100).toInt()}% APPROVAL",
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isApproved = data['final_decision'] == "APPROVE";
    final color = isApproved ? Colors.green : Colors.redAccent;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(isApproved ? Icons.verified_outlined : Icons.block_flipped, color: color, size: 24),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "Anonymous", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: Colors.indigo[900])),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _miniInfo(Icons.attach_money, "\$${data['income'] ?? 'N/A'}"),
                    const SizedBox(width: 16),
                    _miniInfo(Icons.work_outline, data['Occupation'] ?? 'N/A'),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  isApproved ? "SUCCESS" : "DECLINED",
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Finalized on Shield",
                style: TextStyle(color: Colors.black.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.black26),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: Colors.black45, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
