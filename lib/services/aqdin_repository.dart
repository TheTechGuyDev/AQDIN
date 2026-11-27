import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Typed access to AQDIN member data. Queries are protected by Supabase RLS.
class AqdinRepository {
  AqdinRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw AuthException('Sign in to continue.');
    return id;
  }

  Future<Map<String, dynamic>?> myProfile() async {
    final row = await _client.from('user_profiles').select().eq('id', _uid).maybeSingle();
    if (row == null) return null;
    final profile = Map<String, dynamic>.from(row);
    final photos = await _client.from('profile_photos').select()
      .eq('user_id', _uid).order('sort_order');
    profile['photos'] = await Future.wait(photos.map((photo) async {
      final item = Map<String, dynamic>.from(photo);
      try {
        item['signed_url'] = await _client.storage.from('profile-photos')
          .createSignedUrl(item['storage_path'].toString(), 3600);
      } catch (_) {}
      return item;
    }));
    return profile;
  }

  Future<void> saveMyProfile(Map<String, dynamic> values) async {
    const allowed = {
      'display_name', 'date_of_birth', 'country_code', 'city', 'bio',
      'gender', 'marital_status', 'profile_visibility', 'onboarding_complete',
    };
    final payload = Map<String, dynamic>.fromEntries(
      values.entries.where((entry) => allowed.contains(entry.key)),
    );
    payload['id'] = _uid;
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _client.from('user_profiles').upsert(payload);
  }

  Future<List<Map<String, dynamic>>> discover({int limit = 30}) async {
    final memberRows = await _client
        .from('user_profiles')
        .select('id,display_name,date_of_birth,country_code,city,bio,gender,marital_status,occupation,last_active_at,show_online,profile_photos(storage_path,is_primary,moderation_status),profile_interests(interest)')
        .eq('profile_visibility', 'members')
        .eq('onboarding_complete', true)
        .neq('id', _uid)
        .limit(limit);
    final demoRows = await _client.from('aqdin_demo_profiles')
        .select('id,display_name,date_of_birth,country_code,city,bio,gender,marital_status,occupation,interests,image_url')
        .eq('is_active', true)
        .limit(limit);
    final rows = <Map<String, dynamic>>[
      ...memberRows.map((row) => Map<String, dynamic>.from(row)),
      ...demoRows.map((row) {
        final demo = Map<String, dynamic>.from(row);
        demo['id'] = 'demo:' + demo['id'].toString();
        demo['profile_photos'] = [];
        demo['profile_interests'] = ((demo['interests'] as List?) ?? [])
            .map((interest) => {'interest': interest}).toList();
        demo['primary_photo_url'] = demo['image_url'];
        demo['last_active_at'] = null;
        demo['show_online'] = false;
        demo['occupation'] = 'DEMO • ' + (demo['occupation'] ?? 'Member').toString();
        demo['bio'] = 'DEMO PROFILE — Not a real AQDIN member. ' + (demo['bio'] ?? '').toString();
        return demo;
      }),
    ];
    final blocked = await _client.from('user_blocks')
        .select('blocked_user_id').eq('blocker_user_id', _uid);
    final blockedIds = blocked.map((row) => row['blocked_user_id'] as String).toSet();
    final incoming = await _client.from('user_blocks')
        .select('blocker_user_id').eq('blocked_user_id', _uid);
    blockedIds.addAll(incoming.map((row) => row['blocker_user_id'] as String));
    final seen = await _client.from('profile_actions')
        .select('target_user_id').eq('actor_user_id', _uid);
    final seenIds = seen.map((row) => row['target_user_id'] as String).toSet();

    final visibleRows = rows.where((row) {
      final id = row['id'] as String;
      return !blockedIds.contains(id) && !seenIds.contains(id);
    }).toList();
    return await Future.wait(visibleRows.map((row) async {
      final profile = Map<String, dynamic>.from(row);
      final photos = (profile['profile_photos'] as List? ?? [])
          .where((photo) => photo['moderation_status'] == 'approved')
          .toList();
      photos.sort((a, b) =>
          (b['is_primary'] == true ? 1 : 0)
              .compareTo(a['is_primary'] == true ? 1 : 0));
      profile['primary_photo_path'] = photos.isEmpty ? null : photos.first['storage_path'];
      if (profile['primary_photo_path'] != null) {
        try { profile['primary_photo_url'] = await _client.storage.from('profile-photos').createSignedUrl(profile['primary_photo_path'] as String, 3600); } catch (_) {}
      }
      return profile;
    }));
  }

  Future<void> pass(String targetUserId) async {
    if (targetUserId.startsWith('demo:')) return;
    await _client.from('profile_actions').upsert({
      'actor_user_id': _uid,
      'target_user_id': targetUserId,
      'action': 'pass',
    }, onConflict: 'actor_user_id,target_user_id,action');
  }

  Future<String?> like(String targetUserId) async {
    if (targetUserId.startsWith('demo:')) return null;
    final result = await _client.rpc(
      'process_profile_like',
      params: {'target': targetUserId},
    );
    return result as String?;
  }

  Future<void> saveProfile(String targetUserId) async {
    if (targetUserId.startsWith('demo:')) return;
    await _client.from('profile_actions').upsert({
      'actor_user_id': _uid,
      'target_user_id': targetUserId,
      'action': 'save',
    }, onConflict: 'actor_user_id,target_user_id,action');
  }

  Future<List<Map<String, dynamic>>> myMatches() async {
    final rows = await _client.from('matches').select(
      'id,user_one,user_two,created_at,conversations(id)',
    ).or('user_one.eq.$_uid,user_two.eq.$_uid')
        .order('created_at', ascending: false);
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


  Future<List<Map<String, dynamic>>> myVerificationRecords() async {
    final rows = await _client.from('verification_records').select()
      .eq('user_id', _uid).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> requestVerification(String type) async {
    if (!['selfie', 'identity'].contains(type)) throw ArgumentError('Unsupported verification type.');
    await _client.from('verification_records').insert({
      'user_id': _uid, 'verification_type': type, 'status': 'pending',
    });
  }

  Future<List<Map<String, dynamic>>> myConversations() async {
    final memberships = await _client.from('conversation_members').select(
      'conversation_id,conversations(id,match_id,created_at)',
    ).eq('user_id', _uid);
    final output = <Map<String, dynamic>>[];
    for (final item in memberships) {
      final conversation = item['conversations'];
      if (conversation is Map<String, dynamic>) {
        final members = await _client.from('conversation_members').select('user_id')
          .eq('conversation_id', conversation['id']);
        final other = members.map((m) => m['user_id'].toString()).firstWhere((id) => id != _uid, orElse: () => '');
        if (other.isNotEmpty) {
          final profile = await _client.from('user_profiles').select('id,display_name,city')
            .eq('id', other).maybeSingle();
          final last = await _client.from('messages').select('body,created_at,sender_user_id')
            .eq('conversation_id', conversation['id']).order('created_at', ascending: false).limit(1).maybeSingle();
          output.add({...conversation, 'other_user_id': other, 'other_profile': profile, 'last_message': last});
        }
      }
    }
    output.sort((a,b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));
    return output;
  }

  Future<List<Map<String, dynamic>>> messages(String conversationId) async {
    final rows = await _client.from('messages').select()
        .eq('conversation_id', conversationId)
        .isFilter('deleted_at', null).order('created_at');
    return List<Map<String, dynamic>>.from(rows);
  }


  Future<void> saveMarriagePreferences(Map<String, dynamic> values) async {
    final payload = Map<String, dynamic>.from(values)..['user_id'] = _uid
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _client.from('marriage_preferences').upsert(payload);
  }

  Future<Map<String, dynamic>?> myMarriagePreferences() async =>
      _client.from('marriage_preferences').select().eq('user_id', _uid).maybeSingle();

  Future<void> saveInterests(List<String> interests) async {
    await _client.from('profile_interests').delete().eq('user_id', _uid);
    if (interests.isEmpty) return;
    await _client.from('profile_interests').insert(
      interests.map((value) => {'user_id': _uid, 'interest': value.trim()})
        .where((row) => (row['interest'] as String).isNotEmpty).toList(),
    );
  }

  Future<void> blockMember(String targetUserId) async {
    await _client.from('user_blocks').upsert({
      'blocker_user_id': _uid, 'blocked_user_id': targetUserId,
    });
  }

  Future<void> unblockMember(String targetUserId) async {
    await _client.from('user_blocks').delete()
      .eq('blocker_user_id', _uid).eq('blocked_user_id', targetUserId);
  }

  Future<List<Map<String, dynamic>>> blockedMembers() async {
    final rows = await _client.from('user_blocks').select(
      'blocked_user_id,created_at,user_profiles!user_blocks_blocked_user_id_fkey(display_name,city)',
    ).eq('blocker_user_id', _uid).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> reportMember({
    required String targetUserId,
    required String category,
    String? description,
  }) async {
    await _client.from('user_reports').insert({
      'reporter_user_id': _uid, 'reported_user_id': targetUserId,
      'category': category, 'description': description,
    });
  }

  Future<void> respondToIntroduction(String requestId, String status) async {
    if (!['accepted', 'declined'].contains(status)) {
      throw ArgumentError.value(status, 'status');
    }
    await _client.from('introduction_requests').update({
      'status': status, 'responded_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId).eq('recipient_user_id', _uid);
  }

  Future<void> inviteWali({
    required String waliUserId,
    String? relationship,
    Map<String, dynamic>? permissions,
  }) async {
    await _client.from('wali_relationships').insert({
      'member_user_id': _uid, 'wali_user_id': waliUserId,
      'relationship_label': relationship, 'status': 'pending',
      'permissions': permissions ?? {
        'view_profile': true, 'view_matches': false, 'view_messages': false,
      },
    });
  }

  Future<List<Map<String, dynamic>>> myWaliRelationships() async {
    final rows = await _client.from('wali_relationships').select()
      .or('member_user_id.eq.$_uid,wali_user_id.eq.$_uid')
      .order('invited_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> updateWaliPermissions(String relationshipId, Map<String, dynamic> permissions) async {
    await _client.rpc('update_wali_permissions', params: {
      'relationship_uuid': relationshipId, 'new_permissions': permissions,
    });
  }

  Future<void> respondToWaliInvitation(String relationshipId, {required bool accept}) async {
    await _client.rpc('respond_to_wali_invitation', params: {
      'relationship_uuid': relationshipId, 'decision': accept ? 'active' : 'declined',
    });
  }

  Future<void> revokeWali(String relationshipId) async {
    await _client.rpc('revoke_wali_relationship', params: {'relationship_uuid': relationshipId});
  }

  Future<void> saveUserSettings({
    Map<String, dynamic>? notifications,
    Map<String, dynamic>? privacy,
  }) async {
    final payload = <String, dynamic>{'user_id': _uid, 'updated_at': DateTime.now().toUtc().toIso8601String()};
    if (notifications != null) payload['notification_preferences'] = notifications;
    if (privacy != null) payload['privacy_preferences'] = privacy;
    await _client.from('user_settings').upsert(payload);
  }

  Future<Map<String, dynamic>?> userSettings() async =>
      _client.from('user_settings').select().eq('user_id', _uid).maybeSingle();

  Future<String> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final safeExtension = fileExtension.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(safeExtension)) {
      throw ArgumentError('Use a JPG, PNG or WEBP image.');
    }
    final path = '$_uid/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    await _client.storage.from('profile-photos').uploadBinary(path, bytes);
    await _client.from('profile_photos').insert({
      'user_id': _uid, 'storage_path': path, 'moderation_status': 'pending',
    });
    return path;
  }

  Future<String> signedPhotoUrl(String path) =>
      _client.storage.from('profile-photos').createSignedUrl(path, 3600);

  Future<void> setPrimaryPhoto(String photoId) async {
    await _client.from('profile_photos').update({'is_primary': false}).eq('user_id', _uid);
    await _client.from('profile_photos').update({'is_primary': true})
      .eq('id', photoId).eq('user_id', _uid);
  }

  Future<void> deleteProfilePhoto(String photoId, String storagePath) async {
    await _client.from('profile_photos').delete().eq('id', photoId).eq('user_id', _uid);
    await _client.storage.from('profile-photos').remove([storagePath]);
  }

  Future<void> updatePresence({bool? showOnline}) async {
    final values = <String, dynamic>{'last_active_at': DateTime.now().toUtc().toIso8601String()};
    if (showOnline != null) values['show_online'] = showOnline;
    await _client.from('user_profiles').update(values).eq('id', _uid);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) =>
      _client.from('messages').stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId).order('created_at');

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