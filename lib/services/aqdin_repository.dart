import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed access to AQDIN's member data. All member-scoped queries rely on
/// Supabase RLS; this client never uses a service-role credential.
class AqdinRepository {
  AqdinRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const AuthException('Sign in to continue.');
    return id;
  }

  Future<Map<String, dynamic>?> myProfile() async {
    return _client.from('user_profiles').select().eq('id', _uid).maybeSingle();
  }

  Future<void> saveMyProfile(Map<String, dynamic> values) async {
    final allowed = <String>{
      'display_name', 'date_of_birth', 'country_code', 'city', 'bio',
      'gender', 'marital_status', 'profile_visibility', 'onboarding_complete',
    };
    final payload = Map<String, dynamic>.fromEntries(
      values.entries.where((e) => allowed.contains(e.key));
    payload['id'] = _uid;
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _client.from('user_profiles').upsert(payload);
  }

  Future<List<Map<String, dynamic>>> discover({int limit = 30}) async {
    final me = await myProfile();
    final query = _client
        .from('user_profiles')
        .select('id,display_name,date_of_birth,country_code,city,bio,gender,marital_status,profile_photos(storage_path,is_primary,moderation_status),profile_interests(interest)')
        .eq('profile_visibility', 'members')
        .eq('onboarding_complete', true)
        .neq('id', _uid)
        .limit(limit);
    final rows = await query;
    final blocked = await _client
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('blocker_user_id', _uid);
    final blockedIds = blocked.map((e) => e['blocked_user_id'] as String).toSet();
    final incomingBlocks = await _client
        .from('user_blocks')
        .select('blocker_user_id')
        .eq('blocked_user_id', _uid);
    blockedIds.addAll(incomingBlocks.map((e) => e['blocker_user_id'] as String));
    final seen = await _client
        .from('profile_actions')
        .select('target_user_id')
        .eq('actor_user_id', _uid);
    final seenIds = seen.map((e) => e['target_user_id'] as String).toSet();
    final currentCity = me?['city'];
    return rows.where((row) {
      final id = row['id'] as String;
      return !blockedIds.contains(id) && !seenIds.contains(id);
    }).map((row) {
      final photos = (row['profile_photos'] as List? ?? [])
          .where((p) => p['moderation_status'] == 'approved')
          .toList();
      photos.sort((a, b) =>
          (b['is_primary'] == true ? 1 : 0).compareTo(a['is_primary'] == true ? 1 : 0));
      row['primary_photo_path'] =
          photos.isEmpty ? null : photos.first['storage_path'];
      row['same_city'] = currentCity != null && currentCity == row['city'];
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  Future<void> pass(String targetUserId) async {
    await _client.from('profile_actions').upsert({
      'actor_user_id': _uid,
      'target_user_id': targetUserId,
      'action': 'pass',
    }, onConflict: 'actor_user_id,target_user_id,action');
  }

  Future<String?> like(String targetUserId) async {
    final result = await _client.rpc(
      'process_profile_like',
      params: {'target': targetUserId},
    );
    return result as String?;
  }

  Future<void> saveProfile(String targetUserId) async {
    await _client.from('profile_actions').upsert({
      'actor_user_id': _uid,
      'target_user_id': targetUserId,
      'action': 'save',
    }, onConflict: 'actor_user_id,target_user_id,action');
  }

  Future<List<Map<String, dynamic>>> myMatches() async {
    final rows = await _client.from('matches').select(
      'id,user_one,user_two,created_at,conversations(id)',
    ).or('user_one.eq.$_uid,user_two.eq.$_uid').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> myIntroductionRequests() async {
    final rows = await _client.from('introduction_requests').select()
        .or('sender_user_id.eq.$_uid,recipient_user_id.eq.$_uid')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> myNotifications() async {
    final rows = await _client.from('user_notifications').select()
        .eq('user_id', _uid).order('created_at', ascending: false).limit(50);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markNotificationRead(String id) async {
    await _client.from('user_notifications').update({
      'read_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).eq('user_id', _uid);
  }

  Future<void> sendIntroduction({
    required String recipientId,
    String? message,
  }) async {
    await _client.from('introduction_requests').insert({
      'sender_user_id': _uid,
      'recipient_user_id': recipientId,
      'message': message,
    });
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final rows = await _client.from('messages').select()
        .eq('conversation_id', conversationId)
        .isFilter('deleted_at', null)
        .order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final clean = body.trim();
    if (clean.isEmpty) return;
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_user_id': _uid,
      'body': clean,
    });
  }
}
