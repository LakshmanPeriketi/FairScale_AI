import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/landing_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/.env");
  } catch (e) {
    print("Dotenv load failed from assets/.env, trying root .env");
    try {
      await dotenv.load(fileName: ".env");
    } catch (e2) {
      print("All dotenv loads failed");
    }
  }

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBw401Fi1nHZOzNPMxa6Oh1f_s3HqHs7y8",
      appId: "1:501055239937:web:2fc7993f5c0a9c14cecd00",
      messagingSenderId: "501055239937",
      projectId: "fairscaleai",
      authDomain: "fairscaleai.firebaseapp.com",
      storageBucket: "fairscaleai.firebasestorage.app",
    ),
  );
  // Point to the local Auth emulator to prevent 400 Bad Request errors with fake keys
  // await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099); 
  
  runApp(const FairScaleApp());
}

class FairScaleApp extends StatelessWidget {
  const FairScaleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FairScale AI | Modern Fairness Engine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Light Slate
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF0EA5E9),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      home: const LandingScreen(),
    );
  }
}
