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
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _otp = TextEditingController();
  late bool _login = widget.initialLogin;
  bool _busy = false, _obscure = true, _awaitingOtp = false, _useEmailCode = false;
  String? _message;
  bool _error = false;

  @override
  void dispose() {
    _email.dispose(); _password.dispose(); _otp.dispose(); super.dispose();
  }

  void _returnToApp() {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _busy = true; _message = null; });
    try { await action(); }
    on AuthException catch (e) {
      if (mounted) setState(() { _message = e.message; _error = true; });
    } catch (e) {
      if (mounted) setState(() { _message = 'Could not complete this request. Check your connection and try again.'; _error = true; });
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _submit() async {
    if (!_key.currentState!.validate()) return;
    final auth = Supabase.instance.client.auth;
    await _run(() async {
      final email = _email.text.trim();
      if (_login) {
        if (_useEmailCode) {
          await auth.signInWithOtp(email: email, shouldCreateUser: false);
          if (mounted) setState(() { _awaitingOtp = true; _message = 'A sign-in code has been sent to $email.'; _error = false; });
        } else {
          await auth.signInWithPassword(email: email, password: _password.text);
          _returnToApp();
        }
      } else {
        await auth.signUp(email: email, password: _password.text);
        if (mounted) setState(() { _awaitingOtp = true; _message = 'Enter the verification code sent to $email. Your existing AQDIN account has not been changed.'; _error = false; });
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_otp.text.trim().length < 6) {
      setState(() { _message = 'Enter the 6-digit email code.'; _error = true; });
      return;
    }
    final auth = Supabase.instance.client.auth;
    await _run(() async {
      await auth.verifyOTP(
        email: _email.text.trim(),
        token: _otp.text.trim(),
        type: _login ? OtpType.email : OtpType.signup,
      );
      _returnToApp();
    });
  }

  Future<void> _resendCode() async {
    final auth = Supabase.instance.client.auth;
    await _run(() async {
      if (_login) {
        await auth.signInWithOtp(email: _email.text.trim(), shouldCreateUser: false);
      } else {
        await auth.resend(type: OtpType.signup, email: _email.text.trim());
      }
      if (mounted) setState(() { _message = 'A new code has been sent.'; _error = false; });
    });
  }

  Future<void> _forgotPassword() async {
    if (_email.text.trim().isEmpty) {
      setState(() { _message = 'Enter your email address first.'; _error = true; });
      return;
    }
    await _run(() async {
      await Supabase.instance.client.auth.resetPasswordForEmail(_email.text.trim());
      if (mounted) setState(() { _message = 'If the account exists, a password-reset email has been sent.'; _error = false; });
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      children: [
        const Text('AQDIN', style: TextStyle(color: Color(0xFF176B55), fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 20),
        Text(_awaitingOtp ? 'Verify your email' : (_login ? 'Welcome back' : 'Begin with intention'),
          style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w800, color: Color(0xFF17211D))),
        const SizedBox(height: 8),
        Text(_awaitingOtp ? 'Enter the one-time code delivered to your inbox.' :
          (_login ? 'Sign in securely to continue your marriage journey.' : 'Create your account. Email verification uses a one-time code.'),
          style: const TextStyle(color: Color(0xFF68746E), height: 1.5)),
        const SizedBox(height: 26),
        Form(key: _key, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!_awaitingOtp) ...[
            const Text('Email address', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextFormField(controller: _email, enabled: !_busy, keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline)),
              validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim()) ? null : 'Enter a valid email address'),
            if (!_login || !_useEmailCode) ...[
              const SizedBox(height: 18),
              const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _password, enabled: !_busy, obscureText: _obscure,
                autofillHints: _login ? const [AutofillHints.password] : const [AutofillHints.newPassword],
                decoration: InputDecoration(hintText: 'At least 8 characters', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined))),
                validator: (v) => (_login || (v ?? '').length >= 8) ? null : 'Use at least 8 characters'),
            ],
            if (_login) ...[
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : _forgotPassword, child: const Text('Forgot password?'))),
              SwitchListTile(contentPadding: EdgeInsets.zero, value: _useEmailCode,
                onChanged: _busy ? null : (v) => setState(() => _useEmailCode = v),
                title: const Text('Sign in with email code instead', style: TextStyle(fontSize: 13))),
            ],
          ] else ...[
            TextFormField(controller: _otp, autofocus: true, enabled: !_busy,
              keyboardType: TextInputType.number, maxLength: 8,
              decoration: const InputDecoration(labelText: 'Email verification code', hintText: '123456', prefixIcon: Icon(Icons.verified_outlined)),
            ),
            TextButton(onPressed: _busy ? null : _resendCode, child: const Text('Resend code')),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: _error ? const Color(0xFFFFEEEE) : const Color(0xFFEAF4EE), borderRadius: BorderRadius.circular(12)),
              child: Text(_message!, style: TextStyle(color: _error ? Colors.red.shade800 : const Color(0xFF176B55)))),
          ],
          const SizedBox(height: 20),
          SizedBox(height: 54, child: FilledButton(
            onPressed: _busy ? null : (_awaitingOtp ? _verifyCode : _submit),
            child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_awaitingOtp ? 'Verify and continue' : (_login ? 'Sign in' : 'Create account')))),
          const SizedBox(height: 12),
          TextButton(onPressed: _busy ? null : () => setState(() {
            _login = !_login; _awaitingOtp = false; _useEmailCode = false; _message = null; _otp.clear();
          }), child: Text(_login ? 'New to AQDIN? Create an account' : 'Already registered? Sign in')),
          if (_awaitingOtp) TextButton(onPressed: _busy ? null : () => setState(() { _awaitingOtp = false; _otp.clear(); _message = null; }),
            child: const Text('Change email address')),
          const SizedBox(height: 12),
          const Text('By continuing, you confirm that you are at least 18 years old and agree to use AQDIN for marriage-oriented introductions.',
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF849089))),
        ])),
      ],
    )),
  );
}
