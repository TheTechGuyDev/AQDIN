import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/profile_setup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.publishableKey);
  }
  runApp(const AqdinApp());
}

class AqdinApp extends StatelessWidget {
  const AqdinApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AQDIN', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B55)), scaffoldBackgroundColor: const Color(0xFFF8F9F7),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
    home: const AqdinRoot());
}

class AqdinRoot extends StatelessWidget {
  const AqdinRoot({super.key});
  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) return const AqdinWelcomePage();
    return StreamBuilder<AuthState>(stream: Supabase.instance.client.auth.onAuthStateChange, builder: (context, snapshot) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return const AqdinWelcomePage();
      return FutureBuilder(future: Supabase.instance.client.from('user_profiles').select('onboarding_complete').eq('id', session.user.id).maybeSingle(),
        builder: (context, profile) {
          if (profile.connectionState != ConnectionState.done) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (profile.hasError) return const ProfileSetupPage();
          return profile.data?['onboarding_complete'] == true ? const DashboardPage() : const ProfileSetupPage();
        });
    });
  }
}

class AqdinWelcomePage extends StatelessWidget {
  const AqdinWelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final ready = SupabaseConfig.isConfigured;
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Spacer(),
        Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFE4F0EA), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.favorite_rounded, color: Color(0xFF176B55), size: 36)),
        const SizedBox(height: 28),
        const Text('AQDIN', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: 2.2, color: Color(0xFF17211D))),
        const SizedBox(height: 12),
        const Text('Find your person. Build your future.', style: TextStyle(fontSize: 25, height: 1.2, fontWeight: FontWeight.w700, color: Color(0xFF25352E))),
        const SizedBox(height: 14),
        const Text('A thoughtful space for Muslims seeking marriage, built around intention, compatibility, and trust.', style: TextStyle(fontSize: 15, height: 1.55, color: Color(0xFF68746E))),
        const Spacer(),
        Container(width: double.infinity, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: ready ? const Color(0xFFEAF4EE) : const Color(0xFFFFF3E3), borderRadius: BorderRadius.circular(12)),
          child: Text(ready ? 'Secure account services are ready' : 'Preview mode — backend configuration is required to create an account',
            style: TextStyle(color: ready ? const Color(0xFF176B55) : const Color(0xFF8A5A16), fontSize: 12))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: ready ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())) : null, child: const Text('Create an account'))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 54, child: OutlinedButton(onPressed: ready ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage(initialLogin: true))) : null, child: const Text('I already have an account'))),
        const SizedBox(height: 20),
        const Center(child: Text('For adults 18+ • Marriage with intention', style: TextStyle(fontSize: 12, color: Color(0xFF849089)))),
      ]))));
  }
}
