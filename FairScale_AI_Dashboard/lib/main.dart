import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const FairScaleApp());
}

class FairScaleApp extends StatelessWidget {
  const FairScaleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FairScale AI Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent, // Allow global background to show through
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4F46E5),         // Indigo primary
          secondary: Color(0xFF10B981),       // Emerald secondary
          background: Colors.transparent,     
          surface: Colors.transparent,        
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).primaryTextTheme),
      ),
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E17), // Deep dark space
                Color(0xFF171336), // Deep Indigo
                Color(0xFF2B0C36), // Deep Purple neon
              ],
            ),
          ),
          child: child,
        );
      },
      home: const OnboardingScreen(),
    );
  }
}
