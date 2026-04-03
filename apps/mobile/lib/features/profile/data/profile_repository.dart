import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_profile.dart';

class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<UserProfile?> fetchMyProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return null;

    return UserProfile.fromJson(data);
  }

  Future<void> upsertMyProfile({
    required String displayName,
    String locale = 'ko',
    String timezone = 'Asia/Seoul',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName,
      'locale': locale,
      'timezone': timezone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
