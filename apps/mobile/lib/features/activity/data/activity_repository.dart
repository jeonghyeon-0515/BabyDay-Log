import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/activity_event_summary.dart';

class ActivityRepository {
  ActivityRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

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
