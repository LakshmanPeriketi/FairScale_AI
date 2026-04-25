import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'instructions_screen.dart';
import 'decision_history_screen.dart';

class ManagementShell extends StatefulWidget {
  const ManagementShell({Key? key}) : super(key: key);

  @override
  State<ManagementShell> createState() => _ManagementShellState();
}

class _ManagementShellState extends State<ManagementShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages.addAll([
      const InstructionsScreen(),
      OnboardingScreen(onComplete: () => setState(() => _currentIndex = 2)),
      const HomeScreen(), // Rebranded as Interception
      const DecisionHistoryScreen(),
      const ProfileScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Modern Sidebar
          _buildSidebar(),
          // Main Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _pages[_currentIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          _buildBrand(),
          const SizedBox(height: 60),
          _sidebarItem(0, "Overview", Icons.dashboard_outlined),
          _sidebarItem(1, "Create Project", Icons.add_circle_outline),
          _sidebarItem(2, "Interception", Icons.security_outlined),
          _sidebarItem(3, "Decision History", Icons.history_edu_outlined),
          _sidebarItem(4, "Manager Profile", Icons.person_outline),
          const Spacer(),
          _buildLogout(),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigoAccent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 15),
          const Text(
            "FairScale",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(int index, String label, IconData icon) {
    bool isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigoAccent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.indigoAccent : Colors.black45),
            const SizedBox(width: 15),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.indigoAccent : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogout() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListTile(
        onTap: () => Navigator.pop(context),
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
      ),
    );
  }
}
