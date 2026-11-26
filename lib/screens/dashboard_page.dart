import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'account_profile_page.dart';

const _green = Color(0xFF176B55);
const _deep = Color(0xFF07362A);
const _ink = Color(0xFF17211D);
const _muted = Color(0xFF75817A);
const _paper = Color(0xFFF7F8F5);
const _line = Color(0xFFE7ECE7);
const _gold = Color(0xFFD6B56D);
const _rose = Color(0xFFE65D79);

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  int _tab = 0;
  int _cardIndex = 0;
  double _dragX = 0;
  double _dragY = 0;
  int _exitDirection = 0;
  bool _busy = false;
  final Set<int> _liked = {};
  final Set<int> _saved = {};
  final Set<int> _passed = {};

  static const _profiles = [
    _Profile(name:'Amina',age:27,city:'Lagos, Nigeria',role:'Product Designer',online:true,verified:true,
      about:'Grounded in faith, close to family and happiest when learning something new. I value kindness, honest communication and building a peaceful home.',
      values:['Family-minded','Growth','Kindness'],photo:'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=1200&auto=format&fit=crop&q=85'),
    _Profile(name:'Maryam',age:25,city:'Abuja, Nigeria',role:'Healthcare Professional',online:false,verified:true,
      about:'A thoughtful person who enjoys volunteering, books and meaningful conversations. Looking for a sincere partnership built on respect.',
      values:['Compassion','Service','Respect'],photo:'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=1200&auto=format&fit=crop&q=85'),
    _Profile(name:'Zainab',age:29,city:'Ilorin, Nigeria',role:'Business Owner',online:true,verified:false,
      about:'Ambitious but intentional about balance. I enjoy cooking for loved ones, exploring new places and growing together through every season.',
      values:['Purpose','Family','Balance'],photo:'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=1200&auto=format&fit=crop&q=85'),
    _Profile(name:'Hafsa',age:26,city:'Ibadan, Nigeria',role:'Architect',online:false,verified:true,
      about:'I appreciate calm conversations, creative spaces and showing up for the people who matter. Hoping to build a home rooted in mercy.',
      values:['Creativity','Mercy','Family'],photo:'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=1200&auto=format&fit=crop&q=85'),
    _Profile(name:'Safiya',age:28,city:'Kano, Nigeria',role:'Entrepreneur',online:true,verified:true,
      about:'Curious, warm and focused on meaningful growth. I value sincerity, mutual support and a marriage built with intention.',
      values:['Sincerity','Purpose','Support'],photo:'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=1200&auto=format&fit=crop&q=85'),
  ];

  _Profile get _current => _profiles[_cardIndex % _profiles.length];
  String get _firstName => Supabase.instance.client.auth.currentUser?.email?.split('@').first ?? 'there';

  void _open(String title, {String? detail}) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => FeaturePage(title:title,subtitle:detail)));

  void _openMember(_Profile profile) => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => _MemberProfileDetail(profile: profile)));

  Future<void> _swipe(bool liked) async {
    if (_busy) return;
    _busy = true;
    final index = _cardIndex;
    setState(() { _exitDirection = liked ? 1 : -1; _dragX = liked ? 520 : -520; });
    HapticFeedback.mediumImpact();
    SystemSound.play(liked ? SystemSoundType.alert : SystemSoundType.click);
    if (liked) { _liked.add(index); } else { _passed.add(index); }
    await Future.delayed(const Duration(milliseconds: 310));
    if (!mounted) return;
    setState(() { _cardIndex++; _dragX = 0; _dragY = 0; _exitDirection = 0; _busy = false; });
  }

  void _save() {
    setState(() => _saved.add(_cardIndex));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profile saved'),duration:Duration(milliseconds:900)));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_home(), _discover(), _matches(), _messages(), _profile()];
    return Scaffold(
      backgroundColor:_paper,
      extendBody:true,
      body:SafeArea(bottom:false,child:IndexedStack(index:_tab,children:pages)),
      bottomNavigationBar:_AqdinTabBar(selected:_tab,onSelect:(v)=>setState(()=>_tab=v)),
    );
  }

  Widget _header(String eyebrow,String title,{Widget? trailing}) => Padding(
    padding:const EdgeInsets.fromLTRB(21,15,18,12),
    child:Row(children:[
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(eyebrow.toUpperCase(),style:const TextStyle(fontSize:10,letterSpacing:1.7,fontWeight:FontWeight.w800,color:_green)),
        const SizedBox(height:4),
        Text(title,style:const TextStyle(fontFamily:'serif',fontSize:27,height:1.1,fontWeight:FontWeight.w700,color:_deep)),
      ])),
      if(trailing!=null) trailing!,
    ]),
  );

  Widget _roundAction(IconData icon,VoidCallback action) => Container(
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),border:Border.all(color:_line)),
    child:IconButton(onPressed:action,icon:Icon(icon,color:_deep,size:21)));

  Widget _home() => Column(children:[
    _header('AQDIN • YOUR JOURNEY','Assalamu alaikum, ${_firstName[0].toUpperCase()}${_firstName.substring(1)}',
      trailing:_roundAction(Icons.notifications_none_rounded,()=>_open('Notifications'))),
    Padding(padding:const EdgeInsets.fromLTRB(20,0,20,10),child:Row(children:[
      const Icon(Icons.auto_awesome,color:_gold,size:17),
      const SizedBox(width:7),
      const Expanded(child:Text('Thoughtful introductions, chosen by you',style:TextStyle(color:_muted,fontSize:12))),
      Text('${_liked.length} likes',style:const TextStyle(color:_green,fontWeight:FontWeight.w700,fontSize:11)),
    ])),
    Expanded(child:_swipeDeck(showHeader:false)),
    Padding(padding:const EdgeInsets.fromLTRB(20,0,20,100),child:Row(children:[
      const Icon(Icons.lock_outline_rounded,color:_green,size:15),
      const SizedBox(width:7),
      const Expanded(child:Text('Your privacy, your pace. Wali access is always optional.',style:TextStyle(fontSize:10,color:_muted))),
      TextButton(onPressed:()=>_open('Wali & family'),child:const Text('Wali settings',style:TextStyle(fontSize:11))),
    ])),
  ]);

  Widget _discover() => Column(children:[
    _header('FIND YOUR PERSON','Discover',trailing:_roundAction(Icons.tune_rounded,()=>_open('Discovery filters',detail:'Adjust age range, location, distance, marital status, relocation, education and other preferences.'))),
    Padding(padding:const EdgeInsets.fromLTRB(20,0,20,12),child:Row(children:[
      const Expanded(child:Text('People open to a meaningful introduction',style:TextStyle(color:_muted,fontSize:12))),
      Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:const Color(0xFFEAF2EC),borderRadius:BorderRadius.circular(20)),child:const Text('For you',style:TextStyle(color:_green,fontWeight:FontWeight.w800,fontSize:10))),
    ])),
    Expanded(child:GridView.builder(
      padding:const EdgeInsets.fromLTRB(16,0,16,120),
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:13,crossAxisSpacing:12,childAspectRatio:.66),
      itemCount:_profiles.length,
      itemBuilder:(context,index){
        final p=_profiles[index];
        return GestureDetector(onTap:()=>_openMember(p),child:ClipRRect(
          borderRadius:BorderRadius.circular(22),
          child:Stack(fit:StackFit.expand,children:[
            Image.network(p.photo,fit:BoxFit.cover,errorBuilder:(_,__,___)=>Container(color:const Color(0xFFE7E1D8),child:const Icon(Icons.person,size:60,color:_green))),
            const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xCC000000)],stops:[.45,1]))),
            Positioned(top:12,left:11,child:_presenceBadge(p.online)),
            Positioned(left:13,right:10,bottom:13,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text('${p.name}, ${p.age}',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800,fontSize:17)),
              const SizedBox(height:3),
              Text(p.city,style:const TextStyle(color:Colors.white70,fontSize:10)),
              const SizedBox(height:7),
              Wrap(spacing:5,children:p.values.take(2).map((v)=>Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:Colors.white.withOpacity(.2),borderRadius:BorderRadius.circular(12)),child:Text(v,style:const TextStyle(color:Colors.white,fontSize:9)))).toList()),
            ])),
            if(p.verified) const Positioned(right:11,top:12,child:Icon(Icons.verified_rounded,color:Colors.white,size:19)),
          ]),
        ));
      },
    )),
  ]);

  Widget _swipeDeck({bool showHeader=true}) {
    final p=_current;
    return LayoutBuilder(builder:(context,constraints){
      return Padding(padding:const EdgeInsets.fromLTRB(14,0,14,0),child:Column(children:[
        if(showHeader) _header('MEET WITH INTENTION','Discover'),
        Expanded(child:Stack(clipBehavior:Clip.none,children:[
          if(_profiles.length>1) Positioned.fill(child:Padding(padding:const EdgeInsets.only(top:9,left:7,right:7,bottom:3),child:ClipRRect(borderRadius:BorderRadius.circular(30),child:Container(color:const Color(0xFFE7EAE4))))),
          Positioned.fill(child:GestureDetector(
            onPanStart:(_)=>HapticFeedback.selectionClick(),
            onPanUpdate:(d){if(!_busy)setState(() { _dragX+=d.delta.dx; _dragY+=d.delta.dy; });},
            onPanEnd:(d){if(_dragX>105){_swipe(true);}else if(_dragX < -105){_swipe(false);}else{setState(() { _dragX=0; _dragY=0; });}},
            onTap:()=>_openMember(p),
            child:Transform.translate(offset:Offset(_dragX,_dragY*.18),child:Transform.rotate(
              angle:(_dragX/900).clamp(-.22,.22),
              child:_fullPhotoCard(p),
            )),
          )),
          if(_dragX.abs()>18) Positioned(
            top:24,
            left:_dragX<0?20:null,
            right:_dragX>0?20:null,
            child:Transform.rotate(angle:_dragX<0?-.16:.16,child:Container(
              padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),
              decoration:BoxDecoration(border:Border.all(color:_dragX<0?const Color(0xFFFF6B6B):const Color(0xFF69D6A3),width:4),borderRadius:BorderRadius.circular(12),color:Colors.black.withOpacity(.12)),
              child:Text(_dragX<0?'PASS':'LIKE',style:TextStyle(fontSize:25,fontWeight:FontWeight.w900,letterSpacing:2,color:_dragX<0?const Color(0xFFFF6B6B):const Color(0xFF69D6A3))),
            )),
          ),
          if(_exitDirection!=0) Positioned.fill(child:IgnorePointer(child:Center(child:AnimatedScale(
            scale:1.0,duration:const Duration(milliseconds:180),child:Container(
              width:112,height:112,decoration:BoxDecoration(color:Colors.white.withOpacity(.96),shape:BoxShape.circle,boxShadow:const [BoxShadow(color:Colors.black26,blurRadius:25)]),
              child:Icon(_exitDirection<0?Icons.close_rounded:Icons.favorite_rounded,size:66,color:_exitDirection<0?const Color(0xFFE65D65):_rose),
            ),
          )))),
        ])),

      ]));
    });
  }

  Widget _fullPhotoCard(_Profile p)=>ClipRRect(
    borderRadius:BorderRadius.circular(30),
    child:Stack(fit:StackFit.expand,children:[
      Image.network(p.photo,fit:BoxFit.cover,alignment:Alignment.topCenter,
        loadingBuilder:(context,child,progress)=>progress==null?child:Container(color:const Color(0xFFE9E4DE),child:const Center(child:CircularProgressIndicator(color:_green,strokeWidth:2))),
        errorBuilder:(_,__,___)=>Container(color:const Color(0xFFE7E1D8),child:const Center(child:Icon(Icons.person,color:_green,size:110)))),
      const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,stops:[0,.35,.7,1],colors:[Color(0x55000000),Colors.transparent,Color(0x22000000),Color(0xE6000000)]))),
      Positioned(top:17,left:16,child:Container(padding:const EdgeInsets.symmetric(horizontal:11,vertical:7),decoration:BoxDecoration(color:Colors.black.withOpacity(.35),borderRadius:BorderRadius.circular(30)),child:Row(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.auto_awesome,color:_gold,size:13),const SizedBox(width:5),const Text('AQDIN INTRODUCTION',style:TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w800,letterSpacing:1))]))),
      Positioned(top:17,right:15,child:Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:Colors.black.withOpacity(.35),shape:BoxShape.circle),child:const Icon(Icons.more_horiz,color:Colors.white))),
      Positioned(left:19,right:18,bottom:18,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Text('${p.name}, ${p.age}',style:const TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900,shadows:[Shadow(color:Colors.black45,blurRadius:9)])),
          if(p.verified)...[const SizedBox(width:7),const Icon(Icons.verified_rounded,color:Color(0xFF8FE0B7),size:21)],
        ]),
        const SizedBox(height:6),
        Row(children:[Icon(Icons.work_outline,color:Colors.white.withOpacity(.9),size:15),const SizedBox(width:6),Text(p.role,style:const TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w600))]),
        const SizedBox(height:5),
        Row(children:[const Icon(Icons.location_on_outlined,color:Colors.white70,size:14),const SizedBox(width:5),Text(p.city,style:const TextStyle(color:Colors.white70,fontSize:12)),const SizedBox(width:12),_presenceBadge(p.online)]),
        const SizedBox(height:12),
        Text(p.about,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,height:1.35,fontSize:12)),
        const SizedBox(height:10),
        Wrap(spacing:6,children:p.values.map((v)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white.withOpacity(.2),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white24)),child:Text(v,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w700)))).toList()),
        const SizedBox(height:4),
        const Text('Preview profile • Sample data',style:TextStyle(color:Colors.white60,fontSize:9)),
        const SizedBox(height:10),
        Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,children:[
          _photoAction(Icons.close_rounded,const Color(0xFFE35F67),()=>_swipe(false),54),
          _photoAction(_saved.contains(_cardIndex)?Icons.bookmark:Icons.bookmark_border,_gold,_save,46),
          _photoAction(Icons.favorite_rounded,_rose,()=>_swipe(true),60),
          _photoAction(Icons.handshake_rounded,_gold,()=>_open('Request introduction',detail:'Send a respectful introduction request and choose whether to involve a Wali.'),46),
        ]),
      ])),
    ]),
  );

  Widget _photoAction(IconData icon,Color color,VoidCallback action,double size)=>Material(
    elevation:5,color:Colors.white,shape:const CircleBorder(),
    child:InkWell(customBorder:const CircleBorder(),onTap:action,child:SizedBox(width:size,height:size,child:Icon(icon,color:color,size:size*.5))),
  );

  Widget _presenceBadge(bool online)=>Container(
    padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
    decoration:BoxDecoration(color:Colors.black.withOpacity(.34),borderRadius:BorderRadius.circular(20),border:Border.all(color:Colors.white30)),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Container(width:7,height:7,decoration:BoxDecoration(color:online?const Color(0xFF69E09B):const Color(0xFFB7C0BA),shape:BoxShape.circle)),
      const SizedBox(width:5),
      Text(online?'Online':'Offline',style:const TextStyle(color:Colors.white,fontSize:9,fontWeight:FontWeight.w700)),
    ]),
  );

  Widget _actionCircle(IconData icon,String label,Color color,VoidCallback action,double size)=>Column(children:[
    Material(elevation:4,color:Colors.white,shape:const CircleBorder(),child:InkWell(customBorder:const CircleBorder(),onTap:action,child:SizedBox(width:size,height:size,child:Icon(icon,color:color,size:size*.47)))),
    const SizedBox(height:5),Text(label,style:const TextStyle(fontSize:10,color:_muted,fontWeight:FontWeight.w700)),
  ]);

  Widget _matches()=>ListView(padding:const EdgeInsets.only(bottom:120),children:[
    _header('MUTUAL INTEREST','Likes & matches'),
    _emptyCard(Icons.favorite_border_rounded,'Your connections begin with a yes','When interest is mutual, your matches and introductions will appear here.'),
    _sectionHeading('Your activity'),
    _simpleRows([
      ('People who liked you',Icons.favorite_border,'See incoming interest'),
      ('Your likes',Icons.favorite,'${_liked.length} profiles liked in this preview'),
      ('Passed profiles',Icons.close,'${_passed.length} profiles passed in this preview'),
      ('Saved profiles',Icons.bookmark_border,'${_saved.length} profiles saved in this preview'),
      ('Introduction requests',Icons.handshake_outlined,'Track requests and replies'),
      ('Compatibility insights',Icons.insights_outlined,'Explore shared values and differences'),
    ]),
  ]);

  Widget _messages()=>ListView(padding:const EdgeInsets.only(bottom:120),children:[
    _header('PRIVATE CONVERSATIONS','Messages',trailing:_roundAction(Icons.tune_rounded,()=>_open('Message settings'))),
    _emptyCard(Icons.forum_outlined,'Your conversations start here','Messages become available when an introduction is accepted. Your private chats are not shared with a Wali by default.'),
    _sectionHeading('Your conversations'),
    _simpleRows([
      ('Message requests',Icons.mark_chat_unread_outlined,'Review requests before accepting'),
      ('Archived conversations',Icons.archive_outlined,'Find conversations you archived'),
      ('Muted conversations',Icons.notifications_off_outlined,'Manage muted chats'),
      ('Blocked members',Icons.block_outlined,'Manage who can contact you'),
      ('Safety in conversations',Icons.shield_outlined,'Report or block when needed'),
    ]),
  ]);

  Widget _profile(){
    final email=Supabase.instance.client.auth.currentUser?.email??'Signed-in member';
    return ListView(padding:const EdgeInsets.only(bottom:120),children:[
      _header('YOUR SPACE','Profile & settings',trailing:_roundAction(Icons.settings_outlined,()=>_open('Settings'))),
      Padding(padding:const EdgeInsets.symmetric(horizontal:20),child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(21),border:Border.all(color:_line)),child:Row(children:[
        Container(width:56,height:56,decoration:const BoxDecoration(shape:BoxShape.circle,color:Color(0xFFEAF1E9)),child:const Icon(Icons.person_outline,color:_green,size:30)),
        const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Your AQDIN profile',style:TextStyle(fontSize:16,fontWeight:FontWeight.w800,color:_deep)),const SizedBox(height:3),Text(email,style:const TextStyle(fontSize:11,color:_muted))])),
        IconButton(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const AccountProfilePage())),icon:const Icon(Icons.edit_outlined,color:_green)),
      ]))),
      _sectionHeading('Your profile'),
      _simpleRows([
        ('Personal details',Icons.person_outline,'Name, age, location and introduction'),
        ('Photos & introductions',Icons.photo_library_outlined,'Manage profile media'),
        ('Marriage preferences',Icons.tune_rounded,'Age, location, family and life goals'),
        ('Faith & values',Icons.spa_outlined,'Describe what matters to you'),
        ('Verification',Icons.verified_user_outlined,'Review identity verification'),
        ('Compatibility answers',Icons.fact_check_outlined,'Update your preferences and answers'),
      ]),
      _sectionHeading('People you trust'),
      _simpleRows([('Wali & family access',Icons.family_restroom,'Invite and manage permissions'),('Introduction settings',Icons.handshake_outlined,'Choose how introductions work')]),
      _sectionHeading('Privacy & support'),
      _simpleRows([
        ('Privacy controls',Icons.lock_outline,'Profile visibility and activity'),
        ('Safety centre',Icons.health_and_safety_outlined,'Blocking, reporting and guidance'),
        ('Notifications',Icons.notifications_none,'Choose the updates you receive'),
        ('Account security',Icons.security,'Password and active sessions'),
        ('Language & accessibility',Icons.language,'Language and display preferences'),
        ('Help & support',Icons.support_agent,'Get help from AQDIN'),
        ('Terms & privacy',Icons.policy_outlined,'Platform terms and privacy policy'),
        ('Delete account',Icons.delete_outline,'Review account deletion'),
      ]),
      Padding(padding:const EdgeInsets.fromLTRB(20,10,20,20),child:OutlinedButton.icon(onPressed:()async{await Supabase.instance.client.auth.signOut();},icon:const Icon(Icons.logout),label:const Text('Sign out'))),
    ]);
  }

  Widget _sectionHeading(String title)=>Padding(padding:const EdgeInsets.fromLTRB(22,24,22,10),child:Text(title,style:const TextStyle(fontFamily:'serif',fontSize:20,fontWeight:FontWeight.w700,color:_deep)));

  Widget _simpleRows(List<(String,IconData,String)> items)=>Padding(padding:const EdgeInsets.symmetric(horizontal:18),child:Column(children:items.map((item)=>Container(
    margin:const EdgeInsets.only(bottom:8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:_line)),
    child:ListTile(dense:true,onTap:()=>_open(item.$1,detail:item.$3),leading:Container(width:38,height:38,decoration:BoxDecoration(color:const Color(0xFFEAF2EC),borderRadius:BorderRadius.circular(12)),child:Icon(item.$2,color:_green,size:19)),title:Text(item.$1,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w700,color:_ink)),subtitle:Text(item.$3,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:10,color:_muted)),trailing:const Icon(Icons.chevron_right,color:_muted,size:19)),
  )).toList()));

  Widget _emptyCard(IconData icon,String title,String detail)=>Padding(padding:const EdgeInsets.fromLTRB(20,8,20,8),child:Container(padding:const EdgeInsets.fromLTRB(24,27,24,27),decoration:BoxDecoration(color:const Color(0xFFEAF2EC),borderRadius:BorderRadius.circular(22)),child:Column(children:[
    Container(width:54,height:54,decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle),child:Icon(icon,color:_green,size:25)),
    const SizedBox(height:13),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontFamily:'serif',fontSize:19,fontWeight:FontWeight.w700,color:_deep)),
    const SizedBox(height:7),Text(detail,textAlign:TextAlign.center,style:const TextStyle(fontSize:12,height:1.5,color:_muted)),
  ])));

  @override
  void dispose(){super.dispose();}
}

class _Profile {
  const _Profile({required this.name,required this.age,required this.city,required this.role,required this.about,required this.values,required this.photo,required this.online,required this.verified});
  final String name,city,role,about,photo;
  final int age;
  final List<String> values;
  final bool online,verified;
}

class _AqdinTabBar extends StatelessWidget {
  const _AqdinTabBar({required this.selected,required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  static const _items=[
    (Icons.home_outlined,Icons.home_rounded,'Home'),
    (Icons.explore_outlined,Icons.explore_rounded,'Discover'),
    (Icons.favorite_border_rounded,Icons.favorite_rounded,'Likes'),
    (Icons.chat_bubble_outline_rounded,Icons.chat_bubble_rounded,'Chats'),
    (Icons.person_outline_rounded,Icons.person_rounded,'You'),
  ];
  @override
  Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(13,0,13,13),child:ClipRRect(
    borderRadius:BorderRadius.circular(32),
    child:BackdropFilter(filter:ImageFilter.blur(sigmaX:24,sigmaY:24),child:Container(
      height:75,
      decoration:BoxDecoration(color:Colors.white.withOpacity(.72),borderRadius:BorderRadius.circular(32),border:Border.all(color:Colors.white.withOpacity(.18)),boxShadow:const [BoxShadow(color:Color(0x26000000),blurRadius:25,offset:Offset(0,7))]),
      child:Row(children:List.generate(_items.length,(index){
        final item=_items[index];final active=selected==index;
        return Expanded(child:GestureDetector(behavior:HitTestBehavior.opaque,onTap:()=>onSelect(index),child:AnimatedContainer(
          duration:const Duration(milliseconds:220),margin:const EdgeInsets.all(5),decoration:BoxDecoration(color:active?const Color(0xFFE5EFE8).withOpacity(.95):Colors.transparent,borderRadius:BorderRadius.circular(27)),
          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(active?item.$2:item.$1,color:active?_green:const Color(0xFF78857D),size:23),
            const SizedBox(height:4),Text(item.$3,style:TextStyle(fontSize:10,fontWeight:active?FontWeight.w800:FontWeight.w600,color:active?_deep:_muted)),
          ]),
        )));
      })),
    )),
  ));
}

class FeaturePage extends StatefulWidget {
  const FeaturePage({super.key,required this.title,this.subtitle});
  final String title;
  final String? subtitle;
  @override State<FeaturePage> createState()=>_FeaturePageState();
}
class _FeaturePageState extends State<FeaturePage> {
  final Map<String,bool> _toggles={};
  final Set<String> _selected={};
  final TextEditingController _note=TextEditingController();
  @override void dispose(){_note.dispose();super.dispose();}
  List<(String,IconData,bool)> _items(){
    final t=widget.title.toLowerCase();
    if(t.contains('filter')) return [('Verified profiles',Icons.verified_outlined,true),('Online members',Icons.circle,true),('Relocation considered',Icons.travel_explore,true),('Age range',Icons.cake_outlined,false),('Countries and cities',Icons.public,false),('Marital status',Icons.family_restroom,false),('Education and profession',Icons.school_outlined,false)];
    if(t.contains('wali')||t.contains('family')) return [('Invite a Wali or trusted family member',Icons.person_add_alt_1,false),('Choose shared profile details',Icons.visibility_outlined,false),('Approve introductions together',Icons.handshake_outlined,true),('Meeting planner',Icons.event_outlined,false),('Review or revoke access',Icons.admin_panel_settings,false)];
    if(t.contains('privacy')) return [('Profile visible in discovery',Icons.visibility_outlined,true),('Show online status',Icons.circle,true),('Show distance',Icons.location_on_outlined,true),('Allow introduction requests',Icons.handshake_outlined,true),('Pause discovery',Icons.pause_circle_outline,true)];
    if(t.contains('faith')||t.contains('value')) return [('Prayer and faith practices',Icons.menu_book_outlined,false),('Values important to me',Icons.favorite_border,false),('Tradition or school (optional)',Icons.menu_book_outlined,false),('Marriage hopes and expectations',Icons.home_outlined,false)];
    if(t.contains('marriage')||t.contains('compatibility')) return [('Preferred age range',Icons.cake_outlined,false),('Location and relocation',Icons.public,false),('Family and children',Icons.family_restroom,false),('Education and career',Icons.school_outlined,false),('Living arrangements',Icons.home_outlined,false),('Marriage timeline',Icons.event_outlined,false),('Important deal-breakers',Icons.rule_outlined,false)];
    if(t.contains('verification')) return [('Email and phone verification',Icons.phone_android,false),('Selfie and liveness check',Icons.face_retouching_natural,false),('Identity document verification',Icons.badge_outlined,false),('Verification status and appeal',Icons.fact_check_outlined,false)];
    if(t.contains('notification')) return [('Likes and matches',Icons.favorite_border,true),('New messages',Icons.chat_bubble_outline,true),('Introduction updates',Icons.handshake_outlined,true),('Wali activity',Icons.family_restroom,true),('Product announcements',Icons.campaign_outlined,true)];
    if(t.contains('security')) return [('Two-step verification',Icons.security,true),('Active sessions and devices',Icons.devices,false),('Change password',Icons.lock_outline,false),('Sign out other devices',Icons.logout,false)];
    if(t.contains('photo')||t.contains('media')) return [('Add profile photos',Icons.add_a_photo_outlined,false),('Reorder photos',Icons.swap_vert,false),('Choose primary photo',Icons.star_border,false),('Optional audio or video introduction',Icons.mic_none,false)];
    if(t.contains('language')) return [('App language',Icons.language,false),('Arabic right-to-left layout',Icons.format_textdirection_r_to_l,true),('Text size and accessibility',Icons.accessibility_new,false)];
    if(t.contains('safety')||t.contains('block')) return [('Report a member',Icons.flag_outlined,false),('Block a member',Icons.block_outlined,false),('Manage blocked accounts',Icons.person_off_outlined,false),('Read safety guidance',Icons.shield_outlined,false)];
    if(t.contains('message')||t.contains('chat')) return [('Message request permissions',Icons.mark_chat_unread_outlined,false),('Read receipts',Icons.done_all,true),('Typing indicators',Icons.more_horiz,true),('Archived conversations',Icons.archive_outlined,false),('Muted conversations',Icons.notifications_off_outlined,false)];
    if(t.contains('introduction')||t.contains('request')) return [('Send an introduction request',Icons.send_outlined,false),('Include a Wali',Icons.family_restroom,true),('Suggest a family meeting',Icons.event_outlined,false),('Add a personal note',Icons.edit_outlined,false)];
    if(t.contains('terms')||t.contains('help')||t.contains('support')) return [('Frequently asked questions',Icons.help_outline,false),('Contact support',Icons.support_agent,false),('Privacy and data rights',Icons.privacy_tip_outlined,false),('Community guidelines',Icons.groups_outlined,false)];
    if(t.contains('settings')) return [('Account and login',Icons.manage_accounts_outlined,false),('Privacy controls',Icons.lock_outline,false),('Notifications',Icons.notifications_none,false),('Language and accessibility',Icons.language,false),('Safety centre',Icons.health_and_safety_outlined,false),('Help and support',Icons.support_agent,false)];
    return [('Shared values and priorities',Icons.favorite_border,false),('Topics to discuss before marriage',Icons.forum_outlined,false),('Family expectations',Icons.family_restroom,false),('Life goals and plans',Icons.flag_outlined,false),('Personal notes',Icons.edit_outlined,false)];
  }
  @override Widget build(BuildContext context)=>Scaffold(
    backgroundColor:const Color(0xFFF7F8F5),
    appBar:AppBar(backgroundColor:const Color(0xFFF7F8F5),foregroundColor:const Color(0xFF07362A),title:Text(widget.title,style:const TextStyle(fontFamily:'serif',fontWeight:FontWeight.w700))),
    body:ListView(padding:const EdgeInsets.fromLTRB(19,8,19,30),children:[
      if(widget.subtitle!=null&&widget.subtitle!.isNotEmpty) Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:const Color(0xFFEAF2EC),borderRadius:BorderRadius.circular(18)),child:Text(widget.subtitle!,style:const TextStyle(color:Color(0xFF75817A),height:1.5))),
      const SizedBox(height:12),
      ..._items().map((e)=>Container(margin:const EdgeInsets.only(bottom:9),padding:const EdgeInsets.symmetric(horizontal:13,vertical:5),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(15),border:Border.all(color:const Color(0xFFE7ECE7))),child:Row(children:[
        Container(width:38,height:38,decoration:BoxDecoration(color:const Color(0xFFEAF2EC),borderRadius:BorderRadius.circular(11)),child:Icon(e.$2,color:const Color(0xFF176B55),size:19)),
        const SizedBox(width:11),Expanded(child:Text(e.$1,style:const TextStyle(color:Color(0xFF17211D),fontWeight:FontWeight.w600,fontSize:13))),
        if(e.$3) Switch(value:_toggles[e.$1]??true,activeColor:const Color(0xFF176B55),onChanged:(v)=>setState(()=>_toggles[e.$1]=v))
        else IconButton(onPressed:()=>setState(()=>_selected.add(e.$1)),icon:Icon(_selected.contains(e.$1)?Icons.check_circle:Icons.chevron_right,color:_selected.contains(e.$1)?const Color(0xFF176B55):const Color(0xFF75817A))),
      ]))),
      if(widget.title.toLowerCase().contains('edit')||widget.title.toLowerCase().contains('personal')||widget.title.toLowerCase().contains('request')||widget.title.toLowerCase().contains('support')) ...[
        const SizedBox(height:8),TextField(controller:_note,minLines:2,maxLines:4,decoration:InputDecoration(labelText:'Your note',hintText:'Write here',filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(14)))),
      ],
      const SizedBox(height:18),
      SizedBox(height:52,child:FilledButton(onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Saved in this preview. Secure account sync will be connected before launch.'))),style:FilledButton.styleFrom(backgroundColor:const Color(0xFF176B55)),child:const Text('Save changes'))),
    ]),
  );
}


class _MemberProfileDetail extends StatelessWidget {
  const _MemberProfileDetail({required this.profile});
  final _Profile profile;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    body: CustomScrollView(slivers: [
      SliverAppBar(
        pinned: true,
        expandedHeight: 490,
        backgroundColor: _paper,
        foregroundColor: _deep,
        title: Text('${profile.name}, ${profile.age}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(fit: StackFit.expand, children: [
            Image.network(profile.photo, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFE7E1D8),
                    child: const Icon(Icons.person, size: 100, color: _green))),
            const DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.transparent, Color(0xDD000000)],
                stops: [0, .48, 1]))),
            Positioned(left: 22, right: 22, bottom: 28, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text('${profile.name}, ${profile.age}',
                    style: const TextStyle(color: Colors.white, fontSize: 30,
                      fontWeight: FontWeight.w900))),
                  if (profile.verified) ...[
                    const SizedBox(width: 7),
                    const Icon(Icons.verified_rounded, color: Color(0xFF9DE2BB))
                  ]
                ]),
                const SizedBox(height: 7),
                Text(profile.city.toUpperCase(),
                  style: const TextStyle(color: Colors.white70,
                    letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _presenceBadge(profile.online),
              ])),
          ]),
        ),
      ),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFEAF2EC),
              borderRadius: BorderRadius.circular(20)),
            child: Text(profile.about, style: const TextStyle(
              fontSize: 16, height: 1.55, color: Color(0xFF718078)))),
          const SizedBox(height: 22),
          const Text('About', style: TextStyle(fontSize: 19,
            fontWeight: FontWeight.w800, color: _deep)),
          const SizedBox(height: 8),
          Text(profile.role, style: const TextStyle(color: _muted, fontSize: 14)),
          const SizedBox(height: 22),
          const Text('Shared values and priorities', style: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w800, color: _deep)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: profile.values.map((value) =>
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _line)),
              child: Text(value, style: const TextStyle(color: _green,
                fontWeight: FontWeight.w700)))).toList()),
          const SizedBox(height: 22),
          _detailRow(Icons.favorite_border, 'Shared values and priorities'),
          _detailRow(Icons.forum_outlined, 'Topics to discuss before marriage'),
          _detailRow(Icons.family_restroom, 'Family expectations'),
          _detailRow(Icons.flag_outlined, 'Life goals and plans'),
          _detailRow(Icons.edit_note, 'Personal notes'),
          const SizedBox(height: 12),
          const Text('AQDIN introduction', style: TextStyle(color: _muted,
            fontSize: 12, height: 1.5)),
        ]),
      )),
    ]),
    bottomNavigationBar: SafeArea(child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
      child: Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded), label: const Text('Pass'))),
        const SizedBox(width: 9),
        Expanded(child: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _green),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Like this profile from the Home swipe deck.'))),
          icon: const Icon(Icons.favorite), label: const Text('Like')),
        ),
      ]),
    )),
  );

  Widget _detailRow(IconData icon, String title) => Container(
    margin: const EdgeInsets.only(bottom: 9),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
    child: Row(children: [
      Container(width: 42, height: 42,
        decoration: BoxDecoration(color: const Color(0xFFEAF2EC),
          borderRadius: BorderRadius.circular(13)),
        child: Icon(icon, color: _green)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(
        fontWeight: FontWeight.w700, color: _ink))),
      const Icon(Icons.chevron_right, color: _muted),
    ]),
  );
}
