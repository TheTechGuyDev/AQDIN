import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(appBar: AppBar(title: const Text('AQDIN'), actions: [
      IconButton(tooltip: 'Sign out', onPressed: () => Supabase.instance.client.auth.signOut(), icon: const Icon(Icons.logout))]),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Assalamu alaikum', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: Color(0xFF17211D))),
        const SizedBox(height: 8), Text(email, style: const TextStyle(color: Color(0xFF68746E))),
        const SizedBox(height: 28),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFFEAF4EE), borderRadius: BorderRadius.circular(20)),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.favorite_rounded, color: Color(0xFF176B55), size: 30), SizedBox(height: 14),
            Text('Your journey starts here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF17211D))),
            SizedBox(height: 8), Text('Your account and introductory profile are set up. We are building discovery, preferences, and introductions next.', style: TextStyle(color: Color(0xFF52645A), height: 1.5))])),
        const SizedBox(height: 22), const Text('Coming next', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF17211D))),
        const _Next(icon: Icons.tune, title: 'Marriage preferences'), const _Next(icon: Icons.people_alt_outlined, title: 'Discover members'),
        const _Next(icon: Icons.favorite_border, title: 'Introductions and matches'), const _Next(icon: Icons.shield_outlined, title: 'Verification and safety'),
      ])));
  }
}
class _Next extends StatelessWidget {
  const _Next({required this.icon, required this.title});
  final IconData icon; final String title;
  @override
  Widget build(BuildContext context) => ListTile(contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(backgroundColor: const Color(0xFFE4F0EA), child: Icon(icon, color: const Color(0xFF176B55))),
    title: Text(title), trailing: const Icon(Icons.lock_outline, size: 18, color: Colors.grey));
}
