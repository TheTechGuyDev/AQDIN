import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}
class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController(), _country = TextEditingController(text: 'Nigeria'), _city = TextEditingController(), _bio = TextEditingController();
  DateTime? _dob; String? _gender, _marital; bool _saving = false; String? _error;
  @override
  void dispose() { _name.dispose(); _country.dispose(); _city.dispose(); _bio.dispose(); super.dispose(); }
  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now(); var age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) age--;
    return age;
  }
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(context: context, initialDate: DateTime(now.year - 25), firstDate: DateTime(1900), lastDate: now);
    if (date != null) setState(() => _dob = date);
  }
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_dob == null || (_age ?? 0) < 18) { setState(() => _error = 'AQDIN is for adults aged 18 and over.'); return; }
    setState(() { _saving = true; _error = null; });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('user_profiles').upsert({
        'id': user.id, 'display_name': _name.text.trim(), 'date_of_birth': _dob!.toIso8601String().split('T').first,
        'gender': _gender, 'marital_status': _marital, 'country_code': _country.text.trim(), 'city': _city.text.trim(),
        'bio': _bio.text.trim(), 'onboarding_complete': true, 'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } on PostgrestException catch (e) { setState(() => _error = e.message); }
    catch (_) { setState(() => _error = 'Could not save your profile. Please try again.'); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF25352E))));
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Your profile'), actions: [
    TextButton(onPressed: () => Supabase.instance.client.auth.signOut(), child: const Text('Sign out'))]),
    body: SafeArea(child: Form(key: _key, child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 32), children: [
      const Text('Let’s introduce you', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF17211D))),
      const SizedBox(height: 8), const Text('Start with a few essentials. You control what appears on your profile.', style: TextStyle(color: Color(0xFF68746E), height: 1.5)),
      const SizedBox(height: 24), _label('Name you want members to see'),
      TextFormField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Your name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null),
      const SizedBox(height: 18), _label('Date of birth'),
      OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.calendar_month_outlined), label: Text(_dob == null ? 'Choose date of birth' : _dob!.day.toString() + '/' + _dob!.month.toString() + '/' + _dob!.year.toString())),
      const SizedBox(height: 18), _label('Gender'),
      DropdownButtonFormField<String>(value: _gender, decoration: const InputDecoration(hintText: 'Select gender'),
        items: const [DropdownMenuItem(value: 'woman', child: Text('Woman')), DropdownMenuItem(value: 'man', child: Text('Man')), DropdownMenuItem(value: 'self_described', child: Text('Prefer to describe'))],
        onChanged: (v) => setState(() => _gender = v), validator: (v) => v == null ? 'Select an option' : null),
      const SizedBox(height: 18), _label('Marital status'),
      DropdownButtonFormField<String>(value: _marital, decoration: const InputDecoration(hintText: 'Select marital status'),
        items: const [DropdownMenuItem(value: 'never_married', child: Text('Never married')), DropdownMenuItem(value: 'divorced', child: Text('Divorced')), DropdownMenuItem(value: 'widowed', child: Text('Widowed'))],
        onChanged: (v) => setState(() => _marital = v), validator: (v) => v == null ? 'Select an option' : null),
      const SizedBox(height: 18), _label('Country'),
      TextFormField(controller: _country, decoration: const InputDecoration(hintText: 'Country'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your country' : null),
      const SizedBox(height: 18), _label('City'), TextFormField(controller: _city, decoration: const InputDecoration(hintText: 'City')),
      const SizedBox(height: 18), _label('A short introduction (optional)'),
      TextFormField(controller: _bio, minLines: 3, maxLines: 5, maxLength: 500, decoration: const InputDecoration(hintText: 'Share a little about yourself...')),
      if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
      const SizedBox(height: 22), SizedBox(height: 54, child: FilledButton(onPressed: _saving ? null : _save,
        child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save and continue'))),
      const SizedBox(height: 14), const Text('Your date of birth is used to confirm the 18+ requirement and is not displayed publicly.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF849089), fontSize: 12, height: 1.45)),
    ]))));
}
