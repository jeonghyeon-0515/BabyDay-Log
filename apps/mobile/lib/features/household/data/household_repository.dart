import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/household_summary.dart';

class HouseholdRepository {
  HouseholdRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> createHousehold({
    required String name,
    String locale = 'ko',
    String timezone = 'Asia/Seoul',
    String growthChartStandard = 'kr_2017',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('로그인된 사용자가 없습니다.');
    }

    await _client.from('households').insert({
      'name': name,
      'locale': locale,
      'timezone': timezone,
      'growth_chart_standard': growthChartStandard,
      'created_by_user_id': user.id,
    });
  }

  Future<List<HouseholdSummary>> fetchMyHouseholds() async {
    final user = currentUser;
    if (user == null) return const [];

    final memberships = await _client
        .from('household_memberships')
        .select('household_id, role, status')
        .eq('user_id', user.id)
        .order('created_at');

    final membershipRows = List<Map<String, dynamic>>.from(memberships);
    if (membershipRows.isEmpty) return const [];

    final householdIds = membershipRows
        .map((row) => row['household_id'] as String)
        .toList();

    final households = await _client
        .from('households')
        .select('id, name, locale, timezone, growth_chart_standard')
        .inFilter('id', householdIds);

    final householdRows = List<Map<String, dynamic>>.from(households);
    final householdById = {
      for (final row in householdRows) row['id'] as String: row,
    };

    return membershipRows
        .map((membership) {
          final householdId = membership['household_id'] as String;
          final household = householdById[householdId];
          if (household == null) return null;

          return HouseholdSummary(
            id: householdId,
            name: household['name'] as String? ?? 'unknown',
            locale: household['locale'] as String? ?? 'ko',
            timezone: household['timezone'] as String? ?? 'Asia/Seoul',
            growthChartStandard:
                household['growth_chart_standard'] as String? ?? 'kr_2017',
            role: membership['role'] as String? ?? 'viewer',
            status: membership['status'] as String? ?? 'unknown',
          );
        })
        .whereType<HouseholdSummary>()
        .toList();
  }
}
