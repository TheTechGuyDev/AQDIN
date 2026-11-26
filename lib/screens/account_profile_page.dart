import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/aqdin_repository.dart';

const _forest = Color(0xFF07362A);
const _leaf = Color(0xFF176B55);
const _canvas = Color(0xFFF7F8F5);

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});
  @override
  State<AccountProfilePage> createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> {
  final _repo = AqdinRepository();
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _bio = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _country.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final row = await _repo.myProfile();
      if (!mounted) return;
      _profile = row;
      _name.text = row?['display_name']?.toString() ?? '';
      _city.text = row?['city']?.toString() ?? '';
      _country.text = row?['country_code']?.toString() ?? '';
      _bio.text = row?['bio']?.toString() ?? '';
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await _repo.saveMyProfile({
        'display_name': _name.text.trim(),
        'city': _city.text.trim(),
        'country_code': _country.text.trim(),
        'bio': _bio.text.trim(),
      });
      await _load();
      if (!mounted) return;
      setState(() => _editing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your profile has been updated.')),
      );
    } on PostgrestException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not save your profile. $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        foregroundColor: _forest,
        title: const Text('My profile', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => setState(() => _editing = !_editing),
            child: Text(_editing ? 'Cancel' : 'Edit'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _leaf))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2EC),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 86,
                        height: 86,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.person_rounded, color: _leaf, size: 48),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _name.text.isEmpty ? 'Your name' : _name.text,
                        style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: _forest),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [_city.text, _country.text].where((v) => v.trim().isNotEmpty).join(', '),
                        style: const TextStyle(color: Color(0xFF718078)),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF718078))),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (_editing) ...[
                  _field('Display name', _name),
                  _field('City', _city),
                  _field('Country', _country),
                  _field('About me', _bio, maxLines: 5),
                  if (_error != null) Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(backgroundColor: _leaf),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save profile'),
                    ),
                  ),
                ] else ...[
                  _section('About me', _bio.text.isEmpty ? 'Add a short introduction so members can understand what matters to you.' : _bio.text),
                  _section('Profile completion', _profile?['onboarding_complete'] == true ? 'Your basic profile is complete. Add photos, interests and marriage preferences to make your introduction more informative.' : 'Complete your profile setup to begin discovery.'),
                  _section('Privacy', 'Your date of birth is used for the 18+ requirement. You control profile visibility and whether to share online status.'),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit personal details'),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      );

  Widget _section(String title, String value) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE5EBE6)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: _forest)),
          const SizedBox(height: 7),
          Text(value, style: const TextStyle(height: 1.5, color: Color(0xFF718078))),
        ]),
      );
}
