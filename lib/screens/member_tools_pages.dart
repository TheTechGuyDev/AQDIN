import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/aqdin_repository.dart';

const _green = Color(0xFF176B55);
const _deep = Color(0xFF07362A);
const _paper = Color(0xFFF7F8F5);

class MarriagePreferencesPage extends StatefulWidget {
  const MarriagePreferencesPage({super.key});
  @override State<MarriagePreferencesPage> createState() => _MarriagePreferencesPageState();
}
class _MarriagePreferencesPageState extends State<MarriagePreferencesPage> {
  final _repo = AqdinRepository();
  int _minAge = 22, _maxAge = 35;
  bool _relocation = false;
  bool _loading = true, _saving = false;
  String? _error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final row = await _repo.myMarriagePreferences();
      if (row != null && mounted) setState(() {
        _minAge = (row['min_age'] as num?)?.toInt() ?? 22;
        _maxAge = (row['max_age'] as num?)?.toInt() ?? 35;
        _relocation = row['open_to_relocation'] == true;
      });
    } catch (e) { _error = e.toString(); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      await _repo.saveMarriagePreferences({'min_age': _minAge, 'max_age': _maxAge, 'open_to_relocation': _relocation});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marriage preferences saved.')));
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper, appBar: AppBar(title: const Text('Marriage preferences')),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _green)) : ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Age range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deep)),
      Text('From $_minAge to $_maxAge years'),
      RangeSlider(values: RangeValues(_minAge.toDouble(), _maxAge.toDouble()), min: 18, max: 70, divisions: 52,
        onChanged: (v) => setState(() { _minAge = v.start.round(); _maxAge = v.end.round(); })),
      SwitchListTile(value: _relocation, activeColor: _green, contentPadding: EdgeInsets.zero,
        title: const Text('Open to relocation'), subtitle: const Text('Consider introductions from other countries or cities.'),
        onChanged: (v) => setState(() => _relocation = v)),
      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 20), FilledButton(onPressed: _saving ? null : _save,
        style: FilledButton.styleFrom(backgroundColor: _green), child: Text(_saving ? 'Saving…' : 'Save preferences')),
    ]),
  );
}

class WaliManagementPage extends StatefulWidget {
  const WaliManagementPage({super.key});
  @override State<WaliManagementPage> createState() => _WaliManagementPageState();
}
class _WaliManagementPageState extends State<WaliManagementPage> {
  final _repo = AqdinRepository();
  final _userId = TextEditingController();
  final _relationship = TextEditingController(text: 'Family representative');
  List<Map<String,dynamic>> _rows = [];
  bool _loading = true, _busy = false;
  String? _error;
  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _userId.dispose(); _relationship.dispose(); super.dispose(); }
  Future<void> _load() async {
    try { _rows = await _repo.myWaliRelationships(); }
    catch(e) { _error = e.toString(); }
    finally { if(mounted) setState(() => _loading = false); }
  }
  Future<void> _invite() async {
    if (_userId.text.trim().isEmpty) { setState(() => _error = 'Enter the invited person’s AQDIN user ID.'); return; }
    setState(() { _busy = true; _error = null; });
    try {
      await _repo.inviteWali(waliUserId: _userId.text.trim(), relationship: _relationship.text.trim());
      _userId.clear(); await _load();
    } catch(e) { if(mounted) setState(() => _error = e.toString()); }
    finally { if(mounted) setState(() => _busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper, appBar: AppBar(title: const Text('Wali & family')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(18)),
        child: const Text('Family participation is optional. Private conversations are never shared with a Wali by default. You can revoke access at any time.', style: TextStyle(height: 1.5, color: _deep))),
      const SizedBox(height: 18),
      const Text('Invite a trusted representative', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _deep)),
      const SizedBox(height: 10),
      TextField(controller: _userId, decoration: const InputDecoration(labelText: 'AQDIN user ID', hintText: 'Paste the member UUID')),
      const SizedBox(height: 10),
      TextField(controller: _relationship, decoration: const InputDecoration(labelText: 'Relationship')),
      const SizedBox(height: 10),
      FilledButton(onPressed: _busy ? null : _invite, style: FilledButton.styleFrom(backgroundColor: _green), child: Text(_busy ? 'Sending…' : 'Send invitation')),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: Colors.red))),
      const SizedBox(height: 22), const Text('Your connections', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: _deep)),
      if (_loading) const Center(child: CircularProgressIndicator(color: _green)),
      if (!_loading && _rows.isEmpty) const Padding(padding: EdgeInsets.all(18), child: Text('No Wali or family connections yet.')),
      ..._rows.map((r) => Card(color: Colors.white, child: ListTile(
        leading: const Icon(Icons.family_restroom, color: _green),
        title: Text(r['relationship_label']?.toString() ?? 'Trusted representative'),
        subtitle: Text('Status: ${r['status']}'),
        trailing: r['member_user_id'] != Supabase.instance.client.auth.currentUser?.id ? const SizedBox.shrink() : TextButton(
          onPressed: () async { await _repo.revokeWali(r['id'].toString()); await _load(); },
          child: const Text('Revoke')),
      ))),
    ]),
  );}

class SafetyCenterPage extends StatefulWidget {
  const SafetyCenterPage({super.key});
  @override State<SafetyCenterPage> createState() => _SafetyCenterPageState();
}
class _SafetyCenterPageState extends State<SafetyCenterPage> {
  final _repo = AqdinRepository();
  final _target = TextEditingController();
  final _description = TextEditingController();
  String _category = 'Inappropriate behaviour';
  bool _busy = false;
  String? _message;
  Future<void> _block() async {
    try { await _repo.blockMember(_target.text.trim()); setState(() => _message = 'Member blocked. They will no longer appear in discovery.'); }
    catch(e) { setState(() => _message = e.toString()); }
  }
  Future<void> _report() async {
    try {
      await _repo.reportMember(targetUserId: _target.text.trim(), category: _category, description: _description.text.trim());
      setState(() => _message = 'Report submitted for review.');
    } catch(e) { setState(() => _message = e.toString()); }
  }
  @override void dispose() { _target.dispose(); _description.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper, appBar: AppBar(title: const Text('Safety centre')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Your safety matters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _deep)),
      const SizedBox(height: 8), const Text('Block or report a member using their AQDIN user ID. Reports are private and submitted to the moderation queue.', style: TextStyle(height: 1.5)),
      const SizedBox(height: 18), TextField(controller: _target, decoration: const InputDecoration(labelText: 'Member user ID')),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Report reason'),
        items: const ['Inappropriate behaviour','Harassment','Impersonation','Scam or fraud','Underage user','Other'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(), onChanged:(v)=>setState(()=>_category=v??_category)),
      const SizedBox(height: 12), TextField(controller: _description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Additional details (optional)')),
      const SizedBox(height: 14), FilledButton(onPressed: _report, style: FilledButton.styleFrom(backgroundColor: _green), child: const Text('Submit report')),
      OutlinedButton(onPressed: _block, child: const Text('Block this member')),
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_message!, style: const TextStyle(color: _green))),
    ]),
  );
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});
  @override State<NotificationsPage> createState() => _NotificationsPageState();
}
class _NotificationsPageState extends State<NotificationsPage> {
  final _repo = AqdinRepository();
  List<Map<String,dynamic>> _rows = [];
  bool _loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { _rows = await _repo.myNotifications(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper, appBar: AppBar(title: const Text('Notifications')),
    body: _loading ? const Center(child: CircularProgressIndicator(color: _green)) :
      _rows.isEmpty ? const Center(child: Text('You’re all caught up.')) :
      ListView.builder(padding: const EdgeInsets.all(16), itemCount: _rows.length, itemBuilder: (context,i) {
        final row = _rows[i]; final read = row['read_at'] != null;
        return Card(color: Colors.white, child: ListTile(
          leading: Icon(read ? Icons.notifications_none : Icons.notifications_active, color: _green),
          title: Text(row['title']?.toString() ?? 'AQDIN update', style: TextStyle(fontWeight: read ? FontWeight.normal : FontWeight.w800)),
          subtitle: Text(row['body']?.toString() ?? ''),
          onTap: () async { await _repo.markNotificationRead(row['id'].toString()); await _load(); },
        ));
      }),
  );
}


class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});
  @override State<VerificationPage> createState() => _VerificationPageState();
}
class _VerificationPageState extends State<VerificationPage> {
  final _repo = AqdinRepository();
  List<Map<String,dynamic>> _records = [];
  bool _loading = true;
  String? _error;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try { _records = await _repo.myVerificationRecords(); }
    catch(e) { _error = e.toString(); }
    finally { if(mounted) setState(() => _loading = false); }
  }
  Future<void> _request(String type) async {
    try {
      await _repo.requestVerification(type);
      await _load();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification request recorded. It is not a verified badge.')));
    } catch(e) { if(mounted) setState(() => _error = e.toString()); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper, appBar: AppBar(title: const Text('Verification')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(18)),
        child: const Text('Verification badges will only describe checks actually completed by an approved provider. A pending request does not mean your identity has been verified.', style: TextStyle(height: 1.5, color: _deep))),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: () => _request('selfie'), icon: const Icon(Icons.face_retouching_natural), label: const Text('Request selfie verification'), style: FilledButton.styleFrom(backgroundColor: _green)),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: () => _request('identity'), icon: const Icon(Icons.badge_outlined), label: const Text('Request identity verification')),
      const SizedBox(height: 20), const Text('Verification history', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _deep)),
      if(_loading) const Center(child: CircularProgressIndicator(color: _green)),
      if(!_loading && _records.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No verification requests yet.')),
      ..._records.map((r) => Card(color: Colors.white, child: ListTile(
        leading: const Icon(Icons.verified_user_outlined, color: _green),
        title: Text(r['verification_type'].toString().toUpperCase()),
        subtitle: Text('Status: ${r['status']} • Requested ${r['created_at'].toString().split('T').first}'),
      ))),
      if(_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
      const SizedBox(height: 12),
      const Text('Live selfie/ID checks require AQDIN to configure a verification provider and its secure server-side credentials before launch.', style: TextStyle(color: Colors.black54, height: 1.5, fontSize: 12)),
    ]),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.conversationId, required this.title});
  final String conversationId;
  final String title;
  @override State<ChatPage> createState() => _ChatPageState();
}
class _ChatPageState extends State<ChatPage> {
  final _repo = AqdinRepository();
  final _controller = TextEditingController();
  bool _sending = false;
  @override void dispose() { _controller.dispose(); super.dispose(); }
  Future<void> _send() async {
    final body = _controller.text.trim();
    if(body.isEmpty || _sending) return;
    setState(() => _sending = true);
    try { await _repo.sendMessage(widget.conversationId, body); _controller.clear(); }
    catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Message not sent: $e'))); }
    finally { if(mounted) setState(() => _sending = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(title: Text(widget.title)),
    body: Column(children: [
      Expanded(child: StreamBuilder<List<Map<String,dynamic>>>(
        stream: _repo.watchMessages(widget.conversationId),
        builder: (context,snapshot) {
          if(snapshot.hasError) return Center(child: Text('Could not load messages: ${snapshot.error}'));
          if(!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: _green));
          final rows = snapshot.data!;
          if(rows.isEmpty) return const Center(child: Text('Start with a respectful introduction.'));
          return ListView.builder(reverse: false, padding: const EdgeInsets.all(16), itemCount: rows.length, itemBuilder: (context,i) {
            final row = rows[i];
            final mine = row['sender_user_id'] == Supabase.instance.client.auth.currentUser?.id;
            return Align(alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: const BoxConstraints(maxWidth: 290),
                decoration: BoxDecoration(color: mine ? const Color(0xFFDCEDE3) : Colors.white, borderRadius: BorderRadius.circular(17)),
                child: Text(row['body']?.toString() ?? '', style: const TextStyle(height: 1.4))),
            );
          });
        },
      )),
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(12,8,12,12), child: Row(children: [
        Expanded(child: TextField(controller: _controller, minLines: 1, maxLines: 4, decoration: const InputDecoration(hintText: 'Write a message', filled: true, fillColor: Colors.white))),
        const SizedBox(width: 8),
        IconButton.filled(onPressed: _sending ? null : _send, style: IconButton.styleFrom(backgroundColor: _green), icon: const Icon(Icons.send_rounded)),
      ]))),
    ]),
  );
}
