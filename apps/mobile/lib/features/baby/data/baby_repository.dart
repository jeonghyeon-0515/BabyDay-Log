import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/baby_summary.dart';

class BabyRepository {
  BabyRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<BabySummary>> fetchMyBabies() async {
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
        .select('id, household_id, name, birth_date, sex')
        .inFilter('household_id', householdIds)
        .order('birth_date');

    return List<Map<String, dynamic>>.from(
      babies,
    ).map(BabySummary.fromJson).toList();
  }
}
