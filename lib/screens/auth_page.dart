import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialLogin = false});
  final bool initialLogin;
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _key = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  late bool _login = widget.initialLogin;
  bool _busy = false, _obscure = true, _error = false;
  String? _message;
  @override
  void dispose() { _email.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    setState(() { _busy = true; _message = null; });
    try {
      final auth = Supabase.instance.client.auth;
      if (_login) {
        await auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      } else {
        final result = await auth.signUp(email: _email.text.trim(), password: _password.text);
        if (result.session == null && mounted) setState(() { _message = 'Account created. Check your email for the confirmation link, then return to sign in.'; _error = false; });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() { _message = e.message; _error = true; });
    } catch (_) {
      if (mounted) setState(() { _message = 'Something went wrong. Please try again.'; _error = true; });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(), body: SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), children: [
    const Text('AQDIN', style: TextStyle(color: Color(0xFF176B55), fontWeight: FontWeight.w800, letterSpacing: 2)),
    const SizedBox(height: 20),
    Text(_login ? 'Welcome back' : 'Begin with intention', style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Color(0xFF17211D))),
    const SizedBox(height: 8),
    Text(_login ? 'Sign in to continue your marriage journey.' : 'Create a private account to begin your journey towards marriage.', style: const TextStyle(color: Color(0xFF68746E), height: 1.5)),
    const SizedBox(height: 28),
    Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Email address', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline)),
        validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address'),
      const SizedBox(height: 18), const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
      TextFormField(controller: _password, obscureText: _obscure, autofillHints: _login ? const [AutofillHints.password] : const [AutofillHints.newPassword],
        decoration: InputDecoration(hintText: 'At least 8 characters', prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
        validator: (v) => (v ?? '').length >= 8 ? null : 'Use at least 8 characters'),
      if (_message != null) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _error ? const Color(0xFFFFEEEE) : const Color(0xFFEAF4EE), borderRadius: BorderRadius.circular(12)),
        child: Text(_message!, style: TextStyle(color: _error ? Colors.red.shade800 : const Color(0xFF176B55))))],
      const SizedBox(height: 24),
      SizedBox(height: 54, child: FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(_login ? 'Sign in' : 'Create account'))),
      const SizedBox(height: 18),
      TextButton(onPressed: _busy ? null : () => setState(() { _login = !_login; _message = null; }), child: Text(_login ? 'New to AQDIN? Create an account' : 'Already registered? Sign in')),
      const SizedBox(height: 12),
      const Text('By continuing, you confirm that you are at least 18 years old and agree to use AQDIN for marriage-oriented introductions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF849089))),
    ])),
  ])));
}
