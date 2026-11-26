import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _green = Color(0xFF176B55);
const _deep = Color(0xFF07362A);
const _ink = Color(0xFF17211D);
const _muted = Color(0xFF75817A);
const _paper = Color(0xFFF7F8F5);
const _line = Color(0xFFE7ECE7);
const _gold = Color(0xFFD6B56D);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 1;
  int _cardIndex = 0;
  double _dragX = 0;
  final Set<int> _liked = {};
  final Set<int> _saved = {};

  static const _profiles = [
    _Profile(name: 'Amina', age: 27, city: 'Lagos, Nigeria', role: 'Product Designer',
      about: 'Grounded in faith, close to family and happiest when learning something new. I value kindness, honest communication and building a peaceful home.',
      values: ['Family-minded', 'Growth', 'Kindness'], initials: 'A', tint: Color(0xFFD7B9A1)),
    _Profile(name: 'Maryam', age: 25, city: 'Abuja, Nigeria', role: 'Healthcare Professional',
      about: 'A thoughtful person who enjoys volunteering, books and meaningful conversations. Looking for a sincere partnership built on respect.',
      values: ['Compassion', 'Service', 'Respect'], initials: 'M', tint: Color(0xFFB9C9B5)),
    _Profile(name: 'Zainab', age: 29, city: 'Ilorin, Nigeria', role: 'Business Owner',
      about: 'Ambitious but intentional about balance. I enjoy cooking for loved ones, exploring new places and growing together through every season.',
      values: ['Purpose', 'Family', 'Balance'], initials: 'Z', tint: Color(0xFFD8C6A1)),
  ];

  _Profile get _current => _profiles[_cardIndex % _profiles.length];
  String get _firstName => Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'there';

  void _open(String title, {String? detail}) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FeaturePage(title: title, subtitle: detail)));

  void _advance() => setState(() { _cardIndex++; _dragX = 0; });

  void _like() { _liked.add(_cardIndex); _advance(); }
  void _pass() => _advance();
  void _save() { setState(() { _saved.add(_cardIndex); }); }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _discover(), _matches(), _messages(), _profile()];
    return Scaffold(
      backgroundColor: _paper,
      extendBody: true,
      body: SafeArea(bottom: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: _AqdinTabBar(
        selected: _tab,
        onSelect: (value) => setState(() => _tab = value),
      ),
    );
  }

  Widget _topBar(String eyebrow, String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(eyebrow.toUpperCase(), style: const TextStyle(fontSize: 10, letterSpacing: 1.8, fontWeight: FontWeight.w800, color: _green)),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 27, height: 1.1, fontWeight: FontWeight.w700, color: _deep)),
      ])),
      if (trailing != null) trailing,
    ]),
  );

  Widget _iconButton(IconData icon, VoidCallback onTap) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)),
    child: IconButton(onPressed: onTap, icon: Icon(icon, color: _deep, size: 21)),
  );

  Widget _home() => ListView(padding: const EdgeInsets.only(bottom: 120), children: [
    _topBar('AQDIN • YOUR JOURNEY', 'Assalamu alaikum, ${_firstName[0].toUpperCase()}${_firstName.substring(1)}',
      trailing: _iconButton(Icons.notifications_none_rounded, () => _open('Notifications'))),
    Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 0), child: Container(
      padding: const EdgeInsets.fromLTRB(21, 22, 21, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_deep, Color(0xFF155B46), Color(0xFF24745B)]),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('A thoughtful path to marriage.', style: TextStyle(fontFamily: 'serif', color: Colors.white, fontSize: 23, height: 1.2, fontWeight: FontWeight.w700))),
          Container(width: 43, height: 43, decoration: BoxDecoration(color: Colors.white.withOpacity(.12), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome, color: _gold)),
        ]),
        const SizedBox(height: 9),
        const Text('Meet with intention. Move at your pace. Keep the people you trust involved.', style: TextStyle(color: Color(0xFFDCE9E1), height: 1.45, fontSize: 13)),
        const SizedBox(height: 18),
        Align(alignment: Alignment.centerLeft, child: FilledButton(
          onPressed: () => setState(() => _tab = 1),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE8D6A9), foregroundColor: _deep, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
          child: const Text('Explore introductions', style: TextStyle(fontWeight: FontWeight.w800)),
        )),
      ]),
    )),
    const SizedBox(height: 25),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(children: [
      const Expanded(child: Text('Your AQDIN', style: TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w700, color: _deep))),
      TextButton(onPressed: () => _open('Your journey'), child: const Text('View journey')),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
      _journeyTile(Icons.person_outline, 'Profile', 'Build your story', () => setState(() => _tab = 4)),
      const SizedBox(width: 10),
      _journeyTile(Icons.tune_rounded, 'Preferences', 'What matters', () => _open('Marriage preferences')),
      const SizedBox(width: 10),
      _journeyTile(Icons.family_restroom, 'Wali', 'Your choice', () => _open('Wali & family')),
    ])),
    const SizedBox(height: 25),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: Row(children: [
      const Expanded(child: Text('A good place to begin', style: TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w700, color: _deep))),
      TextButton(onPressed: () => setState(() => _tab = 1), child: const Text('Discover')),
    ])),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: GestureDetector(
      onTap: () => setState(() => _tab = 1),
      child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Container(width: 49, height: 49, decoration: BoxDecoration(color: const Color(0xFFF2EBDD), borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.favorite_border_rounded, color: _green)),
          const SizedBox(width: 13),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Explore thoughtful introductions', style: TextStyle(fontWeight: FontWeight.w800, color: _ink)),
            SizedBox(height: 4),
            Text('See people whose stated goals may align with yours.', style: TextStyle(fontSize: 12, color: _muted, height: 1.35)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: _muted),
        ]),
      ),
    )),
    const SizedBox(height: 25),
    Padding(padding: const EdgeInsets.symmetric(horizontal: 22), child: const Text('A little reassurance', style: TextStyle(fontFamily: 'serif', fontSize: 21, fontWeight: FontWeight.w700, color: _deep))),
    Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 10), child: Row(children: [
      const Icon(Icons.lock_outline_rounded, size: 18, color: _green),
      const SizedBox(width: 9),
      const Expanded(child: Text('Your privacy, your pace. Wali access is optional and controlled by you.', style: TextStyle(fontSize: 12, color: _muted, height: 1.4))),
    ])),
  ]);

  Widget _journeyTile(IconData icon, String title, String subtitle, VoidCallback onTap) => Expanded(child: GestureDetector(
    onTap: onTap,
    child: Container(height: 112, padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: _line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: _green, size: 21),
        const Spacer(),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: _ink)),
        const SizedBox(height: 2),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
      ]),
    ),
  ));

  Widget _discover() {
    final profile = _current;
    return Column(children: [
      _topBar('MEET WITH INTENTION', 'Discover',
        trailing: _iconButton(Icons.tune_rounded, () => _open('Discovery preferences', detail: 'Adjust age, location, marital status, relocation and other preferences.'))),
      Padding(padding: const EdgeInsets.fromLTRB(22, 0, 22, 12), child: Row(children: [
        const Icon(Icons.place_outlined, color: _green, size: 17),
        const SizedBox(width: 5),
        const Expanded(child: Text('Recommended introductions', style: TextStyle(color: _muted, fontSize: 12))),
        Text('${_cardIndex + 1} of many', style: const TextStyle(color: _muted, fontSize: 11)),
      ])),
      Expanded(child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 0, 17, 8),
        child: GestureDetector(
          onPanUpdate: (details) => setState(() => _dragX += details.delta.dx),
          onPanEnd: (_) { if (_dragX > 75) { _like(); } else if (_dragX < -75) { _pass(); } else { setState(() => _dragX = 0); } },
          onTap: () => _open('${profile.name} • Profile', detail: profile.about),
          child: Transform.translate(
            offset: Offset(_dragX.clamp(-90, 90), 0),
            child: Transform.rotate(
              angle: _dragX / 1500,
              child: _profileCard(profile),
            ),
          ),
        ),
      )),
      Padding(padding: const EdgeInsets.fromLTRB(18, 5, 18, 9), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _swipeButton(Icons.close_rounded, 'Pass', const Color(0xFFB45D57), _pass, size: 54),
          _swipeButton(Icons.bookmark_border_rounded, 'Save', _green, _save, size: 48),
          _swipeButton(Icons.favorite_rounded, 'Like', const Color(0xFFB77B65), _like, size: 62),
          _swipeButton(Icons.handshake_outlined, 'Introduce', _deep, () => _open('Request introduction', detail: 'Send a respectful introduction request. You can choose whether to involve a Wali.'), size: 48),
        ],
      )),
      const Padding(padding: EdgeInsets.only(bottom: 102), child: Text('Swipe right to like  •  Swipe left to pass', style: TextStyle(fontSize: 11, color: _muted))),
    ]);
  }

  Widget _profileCard(_Profile p) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(27), border: Border.all(color: _line), boxShadow: const [BoxShadow(color: Color(0x160B3023), blurRadius: 22, offset: Offset(0, 9))]),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 6, child: Stack(fit: StackFit.expand, children: [
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p.tint, Color.lerp(p.tint, _deep, .45)!]))),
        Positioned(top: 20, left: 20, child: Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: Colors.white.withOpacity(.9), borderRadius: BorderRadius.circular(30)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.auto_awesome, color: _green, size: 13), SizedBox(width: 5), Text('Thoughtful introduction', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _deep))]))),
        Center(child: Stack(alignment: Alignment.center, children: [
          Container(width: 170, height: 170, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.35), width: 1.5))),
          Container(width: 140, height: 140, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(.16))),
          Text(p.initials, style: TextStyle(fontFamily: 'serif', fontSize: 92, fontWeight: FontWeight.w700, color: Colors.white.withOpacity(.94))),
        ])),
        Positioned(left: 20, right: 20, bottom: 18, child: Row(children: [
          Expanded(child: Text('${p.name}, ${p.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, shadows: [Shadow(color: Colors.black26, blurRadius: 8)]))),
          const Icon(Icons.verified_user_outlined, color: Colors.white, size: 22),
        ])),
      ])),
      Expanded(flex: 4, child: Padding(padding: const EdgeInsets.fromLTRB(20, 15, 20, 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.work_outline, size: 15, color: _green), const SizedBox(width: 6), Expanded(child: Text(p.role, style: const TextStyle(fontSize: 12, color: _muted))), const Icon(Icons.location_on_outlined, size: 15, color: _green), const SizedBox(width: 3), Text(p.city, style: const TextStyle(fontSize: 11, color: _muted))]),
        const SizedBox(height: 12),
        Text(p.about, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.42, color: _ink)),
        const Spacer(),
        Wrap(spacing: 7, runSpacing: 5, children: p.values.map((v) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFF0F4EF), borderRadius: BorderRadius.circular(30)), child: Text(v, style: const TextStyle(fontSize: 10, color: _green, fontWeight: FontWeight.w700)))).toList()),
        const SizedBox(height: 8),
        const Text('Sample profile for preview only', style: TextStyle(fontSize: 9, color: _muted)),
      ]))),
    ]),
  );

  Widget _swipeButton(IconData icon, String label, Color color, VoidCallback onTap, {required double size}) => Column(children: [
    Material(elevation: 2, color: Colors.white, shape: const CircleBorder(), child: InkWell(
      customBorder: const CircleBorder(), onTap: onTap,
      child: SizedBox(width: size, height: size, child: Icon(icon, color: color, size: size * .45)),
    )),
    const SizedBox(height: 5),
    Text(label, style: const TextStyle(fontSize: 10, color: _muted, fontWeight: FontWeight.w600)),
  ]);

  Widget _matches() => ListView(padding: const EdgeInsets.only(bottom: 120), children: [
    _topBar('MUTUAL INTEREST', 'Connections'),
    _emptyCard(Icons.favorite_border_rounded, 'Good connections take time', 'When interest is mutual, your introductions and matches will appear here.'),
    _sectionHeading('Your activity'),
    _simpleRows([
      ('People who liked you', Icons.favorite_border, 'See incoming interest'),
      ('Your likes', Icons.favorite, '${_liked.length} profiles liked in this preview'),
      ('Saved profiles', Icons.bookmark_border, '${_saved.length} profiles saved in this preview'),
      ('Introduction requests', Icons.handshake_outlined, 'Track requests and replies'),
      ('Compatibility insights', Icons.insights_outlined, 'Explore shared values and differences'),
    ]),
  ]);

  Widget _messages() => ListView(padding: const EdgeInsets.only(bottom: 120), children: [
    _topBar('PRIVATE CONVERSATIONS', 'Messages', trailing: _iconButton(Icons.tune_rounded, () => _open('Message settings'))),
    _emptyCard(Icons.forum_outlined, 'Your conversations start here', 'Messages become available when an introduction is accepted. Your private chats are not shared with a Wali by default.'),
    _sectionHeading('Keep your space comfortable'),
    _simpleRows([
      ('Message requests', Icons.mark_chat_unread_outlined, 'Review requests before accepting'),
      ('Archived conversations', Icons.archive_outlined, 'Find conversations you archived'),
      ('Muted conversations', Icons.notifications_off_outlined, 'Manage muted chats'),
      ('Blocked members', Icons.block_outlined, 'Manage who can contact you'),
      ('Safety in conversations', Icons.shield_outlined, 'Report or block when needed'),
    ]),
  ]);

  Widget _profile() {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Signed-in member';
    return ListView(padding: const EdgeInsets.only(bottom: 120), children: [
      _topBar('YOUR SPACE', 'Profile & settings', trailing: _iconButton(Icons.settings_outlined, () => _open('Settings'))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
        padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21), border: Border.all(color: _line)),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAF1E9)), child: const Icon(Icons.person_outline, color: _green, size: 30)),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your AQDIN profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _deep)),
            const SizedBox(height: 3), Text(email, style: const TextStyle(fontSize: 11, color: _muted)),
          ])),
          IconButton(onPressed: () => _open('Edit profile'), icon: const Icon(Icons.edit_outlined, color: _green)),
        ]),
      )),
      _sectionHeading('Your profile'),
      _simpleRows([
        ('Personal details', Icons.person_outline, 'Name, age, location and introduction'),
        ('Photos & introductions', Icons.photo_library_outlined, 'Manage profile media'),
        ('Marriage preferences', Icons.tune_rounded, 'Age, location, family and life goals'),
        ('Faith & values', Icons.spa_outlined, 'Describe what matters to you'),
        ('Verification', Icons.verified_user_outlined, 'Review identity verification'),
        ('Compatibility answers', Icons.fact_check_outlined, 'Update your preferences and answers'),
      ]),
      _sectionHeading('People you trust'),
      _simpleRows([
        ('Wali & family access', Icons.family_restroom, 'Invite and manage permissions'),
        ('Introduction settings', Icons.handshake_outlined, 'Choose how introductions work'),
      ]),
      _sectionHeading('Privacy & support'),
      _simpleRows([
        ('Privacy controls', Icons.lock_outline, 'Profile visibility and activity'),
        ('Safety centre', Icons.health_and_safety_outlined, 'Blocking, reporting and guidance'),
        ('Notifications', Icons.notifications_none, 'Choose the updates you receive'),
        ('Account security', Icons.security, 'Password and active sessions'),
        ('Language & accessibility', Icons.language, 'Language and display preferences'),
        ('Help & support', Icons.support_agent, 'Get help from AQDIN'),
        ('Terms & privacy', Icons.policy_outlined, 'Platform terms and privacy policy'),
        ('Delete account', Icons.delete_outline, 'Review account deletion'),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(20, 10, 20, 20), child: OutlinedButton.icon(
        onPressed: () async { await Supabase.instance.client.auth.signOut(); },
        icon: const Icon(Icons.logout), label: const Text('Sign out'),
      )),
    ]);
  }

  Widget _sectionHeading(String title) => Padding(padding: const EdgeInsets.fromLTRB(22, 24, 22, 10), child: Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700, color: _deep)));

  Widget _simpleRows(List<(String, IconData, String)> items) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 18),
    child: Column(children: items.map((item) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)),
      child: ListTile(
        dense: true, onTap: () => _open(item.$1, detail: item.$3),
        leading: Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(12)), child: Icon(item.$2, color: _green, size: 19)),
        title: Text(item.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _ink)),
        subtitle: Text(item.$3, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
        trailing: const Icon(Icons.chevron_right, color: _muted, size: 19),
      ),
    )).toList()),
  );

  Widget _emptyCard(IconData icon, String title, String detail) => Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 8), child: Container(
    padding: const EdgeInsets.fromLTRB(24, 27, 24, 27),
    decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(22)),
    child: Column(children: [
      Container(width: 54, height: 54, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(icon, color: _green, size: 25)),
      const SizedBox(height: 13), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'serif', fontSize: 19, fontWeight: FontWeight.w700, color: _deep)),
      const SizedBox(height: 7), Text(detail, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.5, color: _muted)),
    ]),
  ));

  @override
  void dispose() { super.dispose(); }
}

class _Profile {
  const _Profile({required this.name, required this.age, required this.city, required this.role, required this.about, required this.values, required this.initials, required this.tint});
  final String name, city, role, about, initials;
  final int age;
  final List<String> values;
  final Color tint;
}

class _AqdinTabBar extends StatelessWidget {
  const _AqdinTabBar({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Discover'),
    (Icons.favorite_border_rounded, Icons.favorite_rounded, 'Likes'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFFDFEFC).withOpacity(.88),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(.95), width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x180B3023), blurRadius: 22, offset: Offset(0, 7))],
          ),
          child: Row(children: List.generate(_items.length, (index) {
            final item = _items[index];
            final active = selected == index;
            return Expanded(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 190),
                margin: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: active ? _deep : Colors.transparent, borderRadius: BorderRadius.circular(24)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(active ? item.$2 : item.$1, color: active ? const Color(0xFFE7D5A8) : const Color(0xFF87928B), size: 22),
                  const SizedBox(height: 4),
                  Text(item.$3, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: active ? Colors.white : const Color(0xFF7D8881))),
                ]),
              ),
            ));
          })),
        ),
      ),
    ),
  );
}

class FeaturePage extends StatelessWidget {
  const FeaturePage({super.key, required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(backgroundColor: _paper, foregroundColor: _deep, title: Text(title, style: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w700))),
    body: ListView(padding: const EdgeInsets.all(22), children: [
      Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(color: const Color(0xFFEAF2EC), borderRadius: BorderRadius.circular(21)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.auto_awesome, color: _green, size: 28), const SizedBox(height: 13),
        Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 23, fontWeight: FontWeight.w700, color: _deep)),
        const SizedBox(height: 8), Text(subtitle ?? 'A considered part of your AQDIN marriage journey.', style: const TextStyle(color: _muted, height: 1.5)),
      ])),
      const SizedBox(height: 18),
      const Text('This section is being prepared. Account-specific actions will be connected to the secure AQDIN backend before launch.', style: TextStyle(color: _ink, height: 1.55)),
    ]),
  );
}
