import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/baby_create_household_option.dart';
import '../domain/baby_summary.dart';

class BabyRepository {
  BabyRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<List<BabyCreateHouseholdOption>> fetchCreateHouseholdOptions() async {
    final user = currentUser;
    if (user == null) return const [];

    final memberships = await _client
        .from('household_memberships')
        .select('household_id, households(id, name)')
        .eq('user_id', user.id)
        .eq('status', 'active');

    return List<Map<String, dynamic>>.from(memberships).map((row) {
      final household = row['households'] as Map<String, dynamic>? ?? const {};
      return BabyCreateHouseholdOption(
        id: household['id'] as String? ?? row['household_id'] as String,
        name: household['name'] as String? ?? 'unknown',
      );
    }).toList();
  }

  Future<void> createBaby({
    required String householdId,
    required String name,
    required String birthDate,
    String sex = 'unknown',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    await _client.from('babies').insert({
      'household_id': householdId,
      'name': name,
      'birth_date': birthDate,
      'sex': sex,
      'created_by_user_id': user.id,
    });
  }

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
