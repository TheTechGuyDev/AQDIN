import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _green = Color(0xFF176B55);
const _deep = Color(0xFF07362A);
const _ink = Color(0xFF17211D);
const _muted = Color(0xFF68746E);
const _pale = Color(0xFFEAF4EE);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  int _discoverIndex = 0;
  final Set<String> _liked = {};
  final Set<String> _passed = {};

  static const _demoProfiles = [
    {'name':'Amina','age':'27','city':'Lagos, Nigeria','about':'Family-oriented, thoughtful and enjoys learning, reading and exploring new places.','tag':'Values family'},
    {'name':'Maryam','age':'25','city':'Abuja, Nigeria','about':'Kind-hearted, career-minded and intentional about building a peaceful home.','tag':'Open to relocation'},
    {'name':'Zainab','age':'29','city':'Ilorin, Nigeria','about':'Enjoys community service, cooking and meaningful conversations.','tag':'Marriage-minded'},
  ];

  void _open(String title, {String? subtitle}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeaturePage(title: title, subtitle: subtitle)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _discover(), _matches(), _messages(), _profile()];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Discover'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Matches'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _header(String title, {String? subtitle, Widget? action}) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _deep)),
        if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: _muted))],
      ])),
      if (action != null) action,
    ]),
  );

  Widget _home() {
    final name = Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'Member';
    return ListView(padding: EdgeInsets.zero, children: [
      _header('Assalamu alaikum', subtitle: name, action: IconButton(onPressed: () => _open('Notifications'), icon: const Icon(Icons.notifications_none))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: const LinearGradient(colors: [_deep, _green]), borderRadius: BorderRadius.circular(22)),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('A meaningful connection starts with intention.', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w700, height: 1.25)),
          SizedBox(height: 9), Text('Take your time. Explore thoughtfully and keep your marriage goals in focus.', style: TextStyle(color: Color(0xFFDCEBE3), height: 1.45)),
        ]),
      )),
      const SizedBox(height: 22),
      _sectionTitle('Your journey'),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
        _stat('Profile','Started',Icons.person_outline),
        const SizedBox(width: 10), _stat('Discover','Explore',Icons.travel_explore),
        const SizedBox(width: 10), _stat('Privacy','In control',Icons.shield_outlined),
      ])),
      const SizedBox(height: 24),
      _sectionTitle('Quick actions'),
      _featureGrid([
        ('Complete your profile',Icons.edit_note,'Add more details so people can understand who you are.'),
        ('Marriage preferences',Icons.tune,'Set the qualities and practical preferences that matter to you.'),
        ('Invite a Wali',Icons.family_restroom,'Invite a trusted representative with permissions you control.'),
        ('Safety centre',Icons.security,'Review privacy, blocking, reporting and verification guidance.'),
      ]),
      const SizedBox(height: 22),
      _sectionTitle('Explore AQDIN'),
      _featureGrid(_featureItems),
      const SizedBox(height: 24),
    ]);
  }

  Widget _discover() {
    final profile = _demoProfiles[_discoverIndex % _demoProfiles.length];
    return ListView(padding: EdgeInsets.zero, children: [
      _header('Discover', subtitle: 'Explore with intention', action: IconButton(onPressed: () => _open('Discovery filters'), icon: const Icon(Icons.tune))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Container(
        height: 430, padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFFE3EAE5)), boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 18, offset: Offset(0, 7))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(width: double.infinity, decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(20)), child: const Center(child: Icon(Icons.person, size: 100, color: _green)))),
          const SizedBox(height: 17),
          Row(children: [Expanded(child: Text('${profile['name']}, ${profile['age']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _ink))), const Icon(Icons.verified_user_outlined, color: _green)]),
          const SizedBox(height: 4), Text(profile['city']!, style: const TextStyle(color: _muted)),
          const SizedBox(height: 10), Text(profile['about']!, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 12), Chip(label: Text(profile['tag']!), backgroundColor: _pale, side: BorderSide.none),
          const Text('Illustrative preview profile — not a real member.', style: TextStyle(fontSize: 11, color: _muted)),
        ]),
      )),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        _roundAction(Icons.close, 'Pass', Colors.grey, () => setState(() { _passed.add(profile['name']!); _discoverIndex++; })),
        _roundAction(Icons.favorite_border, 'Like', _green, () => setState(() { _liked.add(profile['name']!); _discoverIndex++; })),
        _roundAction(Icons.handshake_outlined, 'Introduce', _deep, () => _open('Request an introduction', subtitle: 'Review a profile and send a respectful introduction request.')),
      ]),
      const SizedBox(height: 20),
      Center(child: Text('Preview actions: ${_liked.length} liked · ${_passed.length} passed', style: const TextStyle(color: _muted))),
      const SizedBox(height: 20),
    ]);
  }

  Widget _matches() => ListView(padding: EdgeInsets.zero, children: [
    _header('Matches & likes', subtitle: 'Manage mutual interest and introductions'),
    _emptyPanel(Icons.favorite_border, 'Your matches will appear here', 'When two members express interest, a match can be created.'),
    _featureGrid([
      ('People who liked you',Icons.favorite,'Review incoming likes when matching services are connected.'),
      ('Sent likes',Icons.favorite_outline,'See the profiles you have expressed interest in.'),
      ('Saved profiles',Icons.bookmark_outline,'Return to profiles you want to consider later.'),
      ('Introduction requests',Icons.handshake_outlined,'Track requests and responses.'),
      ('Compatibility insights',Icons.insights,'Understand shared preferences and discussion points.'),
      ('Recently viewed',Icons.history,'Return to profiles you viewed recently.'),
    ]),
  ]);

  Widget _messages() => ListView(padding: EdgeInsets.zero, children: [
    _header('Messages', subtitle: 'Conversations begin after an accepted connection'),
    _emptyPanel(Icons.chat_bubble_outline, 'No conversations yet', 'Your private conversations will be listed here after an introduction is accepted.'),
    _featureGrid([
      ('Message requests',Icons.mark_chat_unread_outlined,'Review incoming requests before opening a conversation.'),
      ('Archived chats',Icons.archive_outlined,'Keep your inbox organised.'),
      ('Muted conversations',Icons.notifications_off_outlined,'Control message notifications.'),
      ('Blocked members',Icons.block,'Manage members you have blocked.'),
      ('Share contact details',Icons.share_outlined,'Share contact information only with consent.'),
      ('Conversation safety',Icons.shield_outlined,'Report or block from a conversation.'),
    ]),
  ]);

  Widget _profile() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Signed-in member';
    return ListView(padding: EdgeInsets.zero, children: [
      _header('Your profile', subtitle: 'Account and privacy controls', action: IconButton(onPressed: () => _open('Settings'), icon: const Icon(Icons.settings_outlined))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE3EAE5))),
        child: Row(children: [const CircleAvatar(radius: 28, backgroundColor: _pale, child: Icon(Icons.person, color: _green, size: 30)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('AQDIN member', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)), Text(email, style: const TextStyle(color: _muted))]))]),
      )),
      const SizedBox(height: 16),
      _featureGrid([
        ('Edit profile',Icons.edit_outlined,'Update your introduction and personal details.'),
        ('Photos & media',Icons.photo_library_outlined,'Manage profile photos and optional introductions.'),
        ('Marriage preferences',Icons.tune,'Set your preferred age range, location and life goals.'),
        ('Faith & values',Icons.mosque_outlined,'Describe your values in your own words.'),
        ('Verification',Icons.verified_user_outlined,'Review available identity verification steps.'),
        ('Wali & family access',Icons.family_restroom,'Invite trusted people and manage their permissions.'),
        ('Privacy controls',Icons.lock_outline,'Control profile visibility and activity settings.'),
        ('Account security',Icons.security,'Manage password, sessions and sign-in security.'),
        ('Language & accessibility',Icons.language,'Language, text and accessibility options.'),
        ('Help & support',Icons.support_agent,'Get help with your account and safety concerns.'),
        ('Download my data',Icons.download_outlined,'Request a copy of your account information.'),
        ('Delete account',Icons.delete_outline,'Review the account deletion process.'),
      ]),
      Padding(padding: const EdgeInsets.all(20), child: OutlinedButton.icon(
        onPressed: () async { await Supabase.instance.client.auth.signOut(); },
        icon: const Icon(Icons.logout), label: const Text('Sign out'),
      )),
    ]);
  }

  Widget _sectionTitle(String title) => Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _ink)));
  Widget _stat(String title, String value, IconData icon) => Expanded(child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE3EAE5))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _green), const SizedBox(height: 8), Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), Text(value, style: const TextStyle(fontSize: 11, color: _muted))])));
  Widget _featureGrid(List<(String, IconData, String)> items) => Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: items.map((item) => Card(
    elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFE8EEE9))),
    child: ListTile(onTap: () => _open(item.$1, subtitle: item.$3), leading: CircleAvatar(backgroundColor: _pale, child: Icon(item.$2, color: _green)), title: Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w600)), subtitle: Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis), trailing: const Icon(Icons.chevron_right)),
  )).toList()));
  Widget _emptyPanel(IconData icon, String title, String detail) => Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), child: Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(18)), child: Column(children: [Icon(icon, color: _green, size: 36), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), const SizedBox(height: 6), Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: _muted, height: 1.4))])));
  Widget _roundAction(IconData icon, String label, Color color, VoidCallback onTap) => Column(children: [IconButton.filledTonal(onPressed: onTap, icon: Icon(icon, color: color), iconSize: 27, style: IconButton.styleFrom(backgroundColor: _pale, fixedSize: const Size(58,58))), const SizedBox(height: 5), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]);
}

const List<(String, IconData, String)> _featureItems = [
  ('Profile completeness',Icons.check_circle_outline,'See which profile details you can add.'),
  ('Discovery filters',Icons.filter_alt_outlined,'Filter by age, location and stated preferences.'),
  ('Compatibility questionnaire',Icons.quiz_outlined,'Answer questions about goals and expectations.'),
  ('Profile prompts',Icons.notes,'Use guided prompts to introduce yourself.'),
  ('Audio introduction',Icons.mic_none,'Add an optional voice introduction.'),
  ('Video introduction',Icons.videocam_outlined,'Add an optional video introduction.'),
  ('Marriage readiness',Icons.flag_outlined,'Work through a personal readiness checklist.'),
  ('Premarital questions',Icons.question_answer_outlined,'Prepare meaningful questions for introductions.'),
  ('Meeting planner',Icons.event_available_outlined,'Plan a family-aware first meeting.'),
  ('Nikah checklist',Icons.checklist,'Keep track of practical marriage milestones.'),
  ('Wali invitation',Icons.mail_outline,'Invite a trusted representative.'),
  ('Wali permissions',Icons.admin_panel_settings_outlined,'Choose what a representative can access.'),
  ('Family introduction planner',Icons.groups_outlined,'Prepare a respectful family introduction.'),
  ('Notification preferences',Icons.notifications_active_outlined,'Choose which updates you receive.'),
  ('Blocked accounts',Icons.block,'Review and manage blocked accounts.'),
  ('Report a concern',Icons.flag_outlined,'Send a safety report to the moderation team.'),
  ('Profile visibility',Icons.visibility_outlined,'Pause or hide your profile from discovery.'),
  ('Pause discovery',Icons.pause_circle_outline,'Take a break without deleting your account.'),
  ('Password recovery',Icons.password,'Recover access to your account.'),
  ('Two-step verification',Icons.verified_user_outlined,'Review additional sign-in protection.'),
  ('Active sessions',Icons.devices_outlined,'Review devices signed in to your account.'),
  ('Subscription plans',Icons.workspace_premium_outlined,'Review future membership options.'),
  ('Payment history',Icons.receipt_long_outlined,'Review membership payment records.'),
  ('Community guidelines',Icons.menu_book_outlined,'Read standards for respectful conduct.'),
  ('Privacy policy',Icons.privacy_tip_outlined,'Understand how account information is handled.'),
  ('Terms of service',Icons.gavel_outlined,'Review platform terms and responsibilities.'),
  ('Safety resources',Icons.health_and_safety_outlined,'Find guidance for safer introductions.'),
  ('Translation preferences',Icons.translate,'Choose language support preferences.'),
  ('Accessibility settings',Icons.accessibility_new,'Adjust the experience for your needs.'),
  ('Feedback',Icons.feedback_outlined,'Share suggestions with the AQDIN team.'),
];

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: _pale, borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: _green, size: 30),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _deep)),
        const SizedBox(height: 8),
        Text(subtitle ?? 'This AQDIN feature is part of the product workspace.', style: const TextStyle(height: 1.5, color: _muted)),
      ])),
      const SizedBox(height: 18),
      const Text('This section is a preview shell. Its data actions and security controls will be connected to the backend before public launch.', style: TextStyle(height: 1.5)),
    ]),
  );
}
