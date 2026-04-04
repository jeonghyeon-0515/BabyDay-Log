import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/diary_create_baby_option.dart';
import '../domain/diary_entry_summary.dart';

class DiaryRepository {
  DiaryRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<DiaryEntrySummary>> fetchRecentDiaries({
    int limit = 20,
    String? babyId,
  }) async {
    final user = currentUser;
    if (user == null) return const [];

    var query = _client
        .from('diary_entries')
        .select(
          'id, baby_id, author_user_id, visibility, body, title, event_date',
        )
        .eq('author_user_id', user.id);

    if (babyId != null) {
      query = query.eq('baby_id', babyId);
    }

    final diaries = await query
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(
      diaries,
    ).map(DiaryEntrySummary.fromJson).toList();
  }

  Future<List<DiaryEntrySummary>> fetchPublicDiaries({
    int limit = 20,
    String? babyId,
  }) async {
    var query = _client
        .from('diary_entries')
        .select(
          'id, baby_id, author_user_id, visibility, body, title, event_date',
        )
        .eq('visibility', 'public');

    if (babyId != null) {
      query = query.eq('baby_id', babyId);
    }

    final diaries = await query
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(
      diaries,
    ).map(DiaryEntrySummary.fromJson).toList();
  }

  Future<List<DiaryCreateBabyOption>> fetchCreateBabyOptions() async {
    final user = currentUser;
    if (user == null) return const [];

    final memberships = await _client
        .from('household_memberships')
        .select('household_id')
        .eq('user_id', user.id)
        .eq('status', 'active');

    final householdIds = List<Map<String, dynamic>>.from(
      memberships,
    ).map((row) => row['household_id'] as String).toList();

    if (householdIds.isEmpty) return const [];

    final babies = await _client
        .from('babies')
        .select('id, name')
        .inFilter('household_id', householdIds)
        .order('birth_date');

    return List<Map<String, dynamic>>.from(babies)
        .map(
          (row) => DiaryCreateBabyOption(
            id: row['id'] as String,
            name: row['name'] as String? ?? 'unknown',
          ),
        )
        .toList();
  }

  Future<void> createDiaryEntry({
    required String babyId,
    required String body,
    String visibility = 'private',
    String? title,
    String? eventDate,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    final baby = await _client
        .from('babies')
        .select('household_id')
        .eq('id', babyId)
        .single();

    await _client.from('diary_entries').insert({
      'household_id': baby['household_id'],
      'baby_id': babyId,
      'author_user_id': user.id,
      'title': title,
      'body': body,
      'visibility': visibility,
      'event_date': eventDate,
    });
  }

  Future<void> updateDiaryVisibility({
    required String diaryEntryId,
    required String visibility,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    await _client
        .from('diary_entries')
        .update({'visibility': visibility})
        .eq('id', diaryEntryId)
        .eq('author_user_id', user.id);
  }
}
