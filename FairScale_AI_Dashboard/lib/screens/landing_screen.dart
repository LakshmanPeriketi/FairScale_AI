import 'package:flutter/material.dart';
import 'auth_screen.dart';
import '../widgets/glass_card.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [
              Color(0xFFF0F9FF), // Sky 50
              Color(0xFFF8FAFC), // Slate 50
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Soft Background Blurs
            Positioned(
              top: -200,
              right: -200,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withOpacity(0.03),
                ),
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavbar(context),
                  _buildHero(context),
                  _buildFeatures(context),
                  _buildTrustLogos(),
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.indigoAccent, Colors.blueAccent]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.indigoAccent.withOpacity(0.2), blurRadius: 20)],
                ),
                child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Text(
                "FairScale AI",
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w900, 
                  letterSpacing: -0.5,
                  color: Colors.indigo[900]
                ),
              ),
            ],
          ),
          Row(
            children: [
              _navLink("Solutions"),
              const SizedBox(width: 30),
              _navLink("Enterprise"),
              const SizedBox(width: 30),
              _navLink("API Docs"),
              const SizedBox(width: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: true)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigoAccent,
                  elevation: 2,
                  shadowColor: Colors.black12,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.indigoAccent.withOpacity(0.1)),
                  ),
                ),
                child: const Text("Manager Login", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navLink(String text) {
    return TextButton(
      onPressed: () {},
      child: Text(
        text,
        style: TextStyle(color: Colors.indigo[900]?.withOpacity(0.6), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.indigoAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.indigoAccent.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 16),
                const SizedBox(width: 10),
                const Text(
                  "NEXT-GEN AI GOVERNANCE PLATFORM",
                  style: TextStyle(
                    color: Colors.indigoAccent, 
                    fontSize: 11, 
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 2
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Text(
            "Eliminate AI Bias\nin Lending Forever.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 84, 
              fontWeight: FontWeight.w900, 
              height: 1.0,
              letterSpacing: -2,
              color: Colors.indigo[900]
            ),
          ),
          const SizedBox(height: 32),
          const SizedBox(
            width: 800,
            child: Text(
              "FairScale intercepts biased lending decisions in real-time. Our proprietary tripartite engine ensures demographic parity without sacrificing predictive accuracy.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, color: Colors.black45, height: 1.6),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigoAccent.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AuthScreen(isLogin: false)));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Start Free Trial", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                ),
              ),
              const SizedBox(width: 24),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
                  side: BorderSide(color: Colors.indigoAccent.withOpacity(0.2), width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text("Watch Demo", style: TextStyle(color: Colors.indigo[900], fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustLogos() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Text(
            "TRUSTED BY GLOBAL FINANCIAL LEADERS",
            style: TextStyle(color: Colors.black12, fontSize: 12, letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _logoPlaceholder("CITIBANK"),
              _logoPlaceholder("GOLDMAN SACHS"),
              _logoPlaceholder("JP MORGAN"),
              _logoPlaceholder("HSBC"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Text(
        text,
        style: const TextStyle(color: Colors.black12, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }

  Widget _buildFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 100),
      child: Column(
        children: [
          Text(
            "The Tripartite Engine",
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.indigo[900]),
          ),
          const SizedBox(height: 20),
          const Text(
            "Three layers of defense against algorithmic discrimination.",
            style: TextStyle(fontSize: 18, color: Colors.black38),
          ),
          const SizedBox(height: 80),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: [
              _featureCard("Model A: Original Ingest", "Trained on raw historical data to baseline your current decision logic.", Icons.psychology_outlined, Colors.blueAccent),
              _featureCard("Model B: Bias Detective", "Adversarial engine that flags demographic correlations in real-time.", Icons.radar_outlined, Colors.indigoAccent),
              _featureCard("Model C: Fair Mirror", "Optimized exclusively on merit metrics to provide the corrected decision.", Icons.auto_awesome_outlined, Colors.tealAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featureCard(String title, String desc, IconData icon, Color accentColor) {
    return Container(
      width: 380,
      height: 280,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.indigoAccent.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.indigoAccent.withOpacity(0.03), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor, size: 32),
          ),
          const SizedBox(height: 32),
          Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.indigo[900])),
          const SizedBox(height: 16),
          Text(desc, style: const TextStyle(color: Colors.black38, height: 1.5, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(80),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.03))),
      ),
      child: Column(
        children: [
          Text(
            "FairScale AI",
            style: TextStyle(color: Colors.indigo[900], fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 20),
          const Text(
            "© 2026 FairScale AI. Pioneering Demographic Parity in Global Finance.",
            style: TextStyle(color: Colors.black26, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
