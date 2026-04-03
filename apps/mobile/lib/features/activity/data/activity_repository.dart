import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/activity_create_baby_option.dart';
import '../domain/activity_event_summary.dart';

class ActivityRepository {
  ActivityRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<ActivityCreateBabyOption>> fetchCreateBabyOptions() async {
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
          (row) => ActivityCreateBabyOption(
            id: row['id'] as String,
            name: row['name'] as String? ?? 'unknown',
          ),
        )
        .toList();
  }

  Future<void> createActivityEvent({
    required String babyId,
    required String eventTypeSlug,
    required DateTime recordedAt,
    String? note,
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

    await _client.from('activity_events').insert({
      'household_id': baby['household_id'],
      'baby_id': babyId,
      'actor_user_id': user.id,
      'event_type_slug': eventTypeSlug,
      'status': 'completed',
      'source': 'app',
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'note': note,
    });
  }

  Future<List<ActivityEventSummary>> fetchRecentActivityEvents({
    int limit = 10,
  }) async {
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

    final events = await _client
        .from('activity_events')
        .select('id, baby_id, event_type_slug, status, recorded_at, note')
        .inFilter('household_id', householdIds)
        .isFilter('deleted_at', null)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(
      events,
    ).map(ActivityEventSummary.fromJson).toList();
  }
}
