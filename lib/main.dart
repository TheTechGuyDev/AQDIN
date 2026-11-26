import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AqdinApp());
}

class AqdinApp extends StatelessWidget {
  const AqdinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQDIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B55),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9F7),
          foregroundColor: Color(0xFF17211D),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const AqdinWelcomePage(),
    );
  }
}

class AqdinWelcomePage extends StatelessWidget {
  const AqdinWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0EA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  CupertinoIcons.heart_circle_fill,
                  color: Color(0xFF176B55),
                  size: 38,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'AQDIN',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  color: Color(0xFF17211D),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Find your person. Build your future.',
                style: TextStyle(
                  fontSize: 23,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF25352E),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'A thoughtful space for Muslims seeking marriage, built around intention, compatibility, and trust.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF68746E),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF176B55),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get started',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF176B55),
                    side: const BorderSide(color: Color(0xFFB7C9C0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('I already have an account'),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'For adults 18+ • Marriage with intention',
                  style: TextStyle(fontSize: 12, color: Color(0xFF849089)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
