import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/activity_event_inputs.dart';
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
    ActivityFeedingDetails? feedingDetails,
    ActivitySleepDetails? sleepDetails,
    ActivityDiaperDetails? diaperDetails,
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

    final baseEventPayload = <String, Object?>{
      'household_id': baby['household_id'],
      'baby_id': babyId,
      'actor_user_id': user.id,
      'event_type_slug': eventTypeSlug,
      'status': 'completed',
      'source': 'app',
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'note': note,
    };

    late final String eventId;

    switch (eventTypeSlug) {
      case 'bottle_feeding':
      case 'breastfeeding':
        final details = feedingDetails;
        if (details == null) {
          throw StateError('feeding 이벤트 세부 정보가 필요합니다.');
        }

        if (eventTypeSlug == 'bottle_feeding' &&
            details.feedingMode != 'bottle') {
          throw StateError('bottle_feeding 이벤트에는 bottle 수유 세부 정보가 필요합니다.');
        }

        if (eventTypeSlug == 'breastfeeding' &&
            details.feedingMode != 'breast') {
          throw StateError('breastfeeding 이벤트에는 breast 수유 세부 정보가 필요합니다.');
        }

        if (details.feedingMode == 'bottle' && details.amountValue == null) {
          throw StateError('bottle 수유에는 수유량이 필요합니다.');
        }

        if (details.feedingMode == 'breast' &&
            details.durationMinutes == null) {
          throw StateError('breast 수유에는 수유 시간이 필요합니다.');
        }

        final breastDuration = details.feedingMode == 'breast'
            ? details.durationMinutes
            : null;

        if (breastDuration != null) {
          final startedAt = recordedAt.toUtc();
          final endedAt = startedAt.add(Duration(minutes: breastDuration));
          baseEventPayload['started_at'] = startedAt.toIso8601String();
          baseEventPayload['ended_at'] = endedAt.toIso8601String();
        }

        eventId = await _insertBaseActivityEvent(baseEventPayload);

        final breastDurationSplit = breastDuration == null
            ? null
            : _splitDurationForBreastfeeding(
                breastDuration,
                details.breastSide,
              );

        final feedingDetailPayload = <String, Object?>{
          'event_id': eventId,
          'feeding_mode': details.feedingMode,
          'breast_side': details.breastSide,
          'left_duration_sec': breastDurationSplit?.leftDurationSec,
          'right_duration_sec': breastDurationSplit?.rightDurationSec,
          'amount_value': details.amountValue,
          'amount_unit': details.amountUnit,
          'content_type': details.contentType,
          'spit_up_level': null,
        };

        await _client
            .from('feeding_event_details')
            .insert(feedingDetailPayload);
        return;
      case 'sleep':
        final details = sleepDetails;
        if (details == null) {
          throw StateError('sleep 이벤트 세부 정보가 필요합니다.');
        }

        final startedAt = recordedAt.toUtc();
        final endedAt = startedAt.add(
          Duration(minutes: details.durationMinutes),
        );
        baseEventPayload['started_at'] = startedAt.toIso8601String();
        baseEventPayload['ended_at'] = endedAt.toIso8601String();

        eventId = await _insertBaseActivityEvent(baseEventPayload);

        await _client.from('sleep_event_details').insert({
          'event_id': eventId,
          'sleep_type': details.sleepType,
          'location': details.location,
          'fell_asleep_at': startedAt.toIso8601String(),
          'woke_up_at': endedAt.toIso8601String(),
          'metadata': <String, Object?>{},
        });
        return;
      case 'diaper':
        final details = diaperDetails;
        if (details == null) {
          throw StateError('diaper 이벤트 세부 정보가 필요합니다.');
        }

        eventId = await _insertBaseActivityEvent(baseEventPayload);

        await _client.from('diaper_event_details').insert({
          'event_id': eventId,
          'diaper_type': details.diaperType,
          'stool_color': details.stoolColor,
          'stool_texture': details.stoolTexture,
          'rash_observed': details.rashObserved,
          'metadata': <String, Object?>{},
        });
        return;
      default:
        throw UnsupportedError(
          '지원하지 않는 activity event type입니다: $eventTypeSlug',
        );
    }
  }

  Future<String> _insertBaseActivityEvent(Map<String, Object?> payload) async {
    final createdEvent = await _client
        .from('activity_events')
        .insert(payload)
        .select('id')
        .single();

    return createdEvent['id'] as String;
  }

  ({int leftDurationSec, int rightDurationSec}) _splitDurationForBreastfeeding(
    int durationMinutes,
    String? breastSide,
  ) {
    final totalDurationSec = durationMinutes * 60;

    if (breastSide == 'left') {
      return (leftDurationSec: totalDurationSec, rightDurationSec: 0);
    }

    if (breastSide == 'right') {
      return (leftDurationSec: 0, rightDurationSec: totalDurationSec);
    }

    final leftDurationSec = totalDurationSec ~/ 2;
    return (
      leftDurationSec: leftDurationSec,
      rightDurationSec: totalDurationSec - leftDurationSec,
    );
  }

  Future<List<ActivityEventSummary>> fetchRecentActivityEvents({
    int limit = 10,
    String? babyId,
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

    var query = _client
        .from('activity_events')
        .select('id, baby_id, event_type_slug, status, recorded_at, note')
        .inFilter('household_id', householdIds);

    if (babyId != null) {
      query = query.eq('baby_id', babyId);
    }

    final events = await query
        .isFilter('deleted_at', null)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(
      events,
    ).map(ActivityEventSummary.fromJson).toList();
  }
}
