import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'screens/auth_page.dart';
import 'screens/dashboard_page.dart';
import 'screens/profile_setup_page.dart';

const aqdinGreen = Color(0xFF176B55);
const aqdinDeepGreen = Color(0xFF07362A);
const aqdinGold = Color(0xFFDDBB69);

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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: aqdinGreen),
      scaffoldBackgroundColor: const Color(0xFFF8F9F6),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8F9F6), foregroundColor: aqdinDeepGreen),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE3EAE5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE3EAE5))),
      ),
    ),
    home: const AqdinLaunchPage(),
  );
}

class AqdinLaunchPage extends StatefulWidget {
  const AqdinLaunchPage({super.key});
  @override
  State<AqdinLaunchPage> createState() => _AqdinLaunchPageState();
}
class _AqdinLaunchPageState extends State<AqdinLaunchPage> {
  bool _finished = false;
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _finished = true);
    });
  }
  @override
  Widget build(BuildContext context) => _finished ? const AqdinRoot() : const AqdinSplashScreen();
}

class AqdinSplashScreen extends StatelessWidget {
  const AqdinSplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: aqdinDeepGreen,
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        AqdinLogo(light: true, markSize: 150),
        SizedBox(height: 34),
        SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: aqdinGold)),
      ]),
    ),
  );
}

class AqdinRoot extends StatelessWidget {
  const AqdinRoot({super.key});
  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) return const AqdinWelcomePage();
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) return const AqdinWelcomePage();
        return FutureBuilder(
          future: Supabase.instance.client.from('user_profiles').select('onboarding_complete').eq('id', session.user.id).maybeSingle(),
          builder: (context, profile) {
            if (profile.connectionState != ConnectionState.done) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: aqdinGreen)));
            }
            if (profile.hasError) return const ProfileSetupPage();
            return profile.data?['onboarding_complete'] == true ? const DashboardPage() : const ProfileSetupPage();
          },
        );
      },
    );
  }
}

class AqdinLogo extends StatelessWidget {
  const AqdinLogo({super.key, this.light = false, this.markSize = 76, this.showDescriptor = true});
  final bool light;
  final double markSize;
  final bool showDescriptor;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SvgPicture.asset('assets/branding/aqdin_mark.svg', width: markSize, height: markSize),
      const SizedBox(height: 7),
      Text('AQDIN', style: TextStyle(
        fontFamily: 'serif', fontWeight: FontWeight.w700, fontSize: 36,
        letterSpacing: 1.8, color: light ? const Color(0xFFF8EBC8) : aqdinDeepGreen,
      )),
      if (showDescriptor) ...[
        const SizedBox(height: 3),
        Text('M U S L I M   M A T R I M O N I A L', style: TextStyle(
          fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.3,
          color: light ? aqdinGold : aqdinGreen,
        )),
      ],
    ],
  );
}

class AqdinWelcomePage extends StatelessWidget {
  const AqdinWelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final ready = SupabaseConfig.isConfigured;
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(minHeight: 330),
                      padding: const EdgeInsets.fromLTRB(28, 34, 28, 30),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [aqdinDeepGreen, Color(0xFF10513F)]),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(34)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const AqdinLogo(light: true, markSize: 96),
                          const SizedBox(height: 22),
                          const Text('Find your person.\nBuild your future.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontFamily: 'serif', fontSize: 29, height: 1.2, fontWeight: FontWeight.w700, color: Colors.white)),
                          const SizedBox(height: 12),
                          const Text('A thoughtful space for Muslims seeking marriage, built around intention, compatibility, and trust.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, height: 1.5, color: Color(0xFFD9E7DF))),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 18),
                      child: Column(
                        children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: const [
                            _WelcomeBenefit(icon: Icons.verified_user_outlined, label: 'Safer\nintroductions'),
                            _WelcomeBenefit(icon: Icons.favorite_border, label: 'Serious\nintentions'),
                            _WelcomeBenefit(icon: Icons.family_restroom, label: 'Family\ninvolvement'),
                          ]),
                          const SizedBox(height: 20),
                          Container(width: double.infinity, padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: ready ? const Color(0xFFEAF4EE) : const Color(0xFFFFF3E3), borderRadius: BorderRadius.circular(13)),
                            child: Text(ready ? 'Secure account services are ready' : 'Preview mode — backend configuration is required to create an account',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: ready ? aqdinGreen : const Color(0xFF8A5A16), fontSize: 12, fontWeight: FontWeight.w600))),
                          const SizedBox(height: 14),
                          SizedBox(width: double.infinity, height: 54, child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: aqdinGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: ready ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage())) : null,
                            child: const Text('Create an account', style: TextStyle(fontWeight: FontWeight.w600)))),
                          const SizedBox(height: 10),
                          SizedBox(width: double.infinity, height: 54, child: OutlinedButton(
                            style: OutlinedButton.styleFrom(foregroundColor: aqdinGreen, side: const BorderSide(color: Color(0xFFB7CEC3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                            onPressed: ready ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage(initialLogin: true))) : null,
                            child: const Text('I already have an account'))),
                          const SizedBox(height: 14),
                          const Text('For adults 18+  •  Marriage with intention', style: TextStyle(fontSize: 11, color: Color(0xFF849089))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBenefit extends StatelessWidget {
  const _WelcomeBenefit({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFE5F0E9), shape: BoxShape.circle),
      child: Icon(icon, color: aqdinGreen, size: 22)),
    const SizedBox(height: 7),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, height: 1.35, color: Color(0xFF52645A), fontWeight: FontWeight.w600)),
  ]);
}
