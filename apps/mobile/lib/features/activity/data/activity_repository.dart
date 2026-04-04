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

    final summaries = List<Map<String, dynamic>>.from(
      events,
    ).map(ActivityEventSummary.fromJson).toList();

    return _enrichRecentActivityEvents(summaries);
  }

  Future<List<ActivityEventSummary>> _enrichRecentActivityEvents(
    List<ActivityEventSummary> events,
  ) async {
    if (events.isEmpty) return events;

    final eventIds = events.map((event) => event.id).toList();
    final detailSummaries = await _fetchDetailSummaries(eventIds);

    return events
        .map(
          (event) => event.copyWith(detailSummary: detailSummaries[event.id]),
        )
        .toList();
  }

  Future<Map<String, String>> _fetchDetailSummaries(
    List<String> eventIds,
  ) async {
    if (eventIds.isEmpty) return const {};

    final result = await Future.wait([
      _client
          .from('feeding_event_details')
          .select(
            'event_id, feeding_mode, breast_side, left_duration_sec, right_duration_sec, amount_value, amount_unit, content_type',
          )
          .inFilter('event_id', eventIds),
      _client
          .from('sleep_event_details')
          .select('event_id, sleep_type, location, fell_asleep_at, woke_up_at')
          .inFilter('event_id', eventIds),
      _client
          .from('diaper_event_details')
          .select(
            'event_id, diaper_type, stool_color, stool_texture, rash_observed',
          )
          .inFilter('event_id', eventIds),
    ]);
    final feedingRows = result[0];
    final sleepRows = result[1];
    final diaperRows = result[2];

    final summaries = <String, String>{};

    for (final row in List<Map<String, dynamic>>.from(feedingRows)) {
      final eventId = row['event_id'] as String? ?? '';
      if (eventId.isEmpty) continue;
      summaries[eventId] = _buildFeedingDetailSummary(row);
    }

    for (final row in List<Map<String, dynamic>>.from(sleepRows)) {
      final eventId = row['event_id'] as String? ?? '';
      if (eventId.isEmpty) continue;
      summaries[eventId] = _buildSleepDetailSummary(row);
    }

    for (final row in List<Map<String, dynamic>>.from(diaperRows)) {
      final eventId = row['event_id'] as String? ?? '';
      if (eventId.isEmpty) continue;
      summaries[eventId] = _buildDiaperDetailSummary(row);
    }

    return summaries;
  }

  String _buildFeedingDetailSummary(Map<String, dynamic> row) {
    final feedingMode = row['feeding_mode'] as String? ?? '';
    if (feedingMode == 'bottle') {
      final amountValue = row['amount_value'];
      final amountUnit = row['amount_unit'] as String? ?? '';
      final contentType = _feedingContentLabel(row['content_type'] as String?);
      final amountText = _formatNumericValue(amountValue);
      final parts = <String>[
        '젖병 $amountText${amountUnit.isEmpty ? '' : amountUnit}',
      ];
      if (contentType.isNotEmpty) {
        parts.add(contentType);
      }
      return parts.join(' · ');
    }

    if (feedingMode == 'breast') {
      final leftDurationSec = row['left_duration_sec'] as int? ?? 0;
      final rightDurationSec = row['right_duration_sec'] as int? ?? 0;
      final totalMinutes = (leftDurationSec + rightDurationSec) ~/ 60;
      final breastSide = _breastSideLabel(row['breast_side'] as String?);
      return '모유 ${_formatDurationMinutes(totalMinutes)} · $breastSide';
    }

    return '수유 기록';
  }

  String _buildSleepDetailSummary(Map<String, dynamic> row) {
    final sleepType = _sleepTypeLabel(row['sleep_type'] as String?);
    final fellAsleepAt = DateTime.tryParse(
      row['fell_asleep_at'] as String? ?? '',
    );
    final wokeUpAt = DateTime.tryParse(row['woke_up_at'] as String? ?? '');
    final location = (row['location'] as String? ?? '').trim();
    final durationMinutes = fellAsleepAt != null && wokeUpAt != null
        ? wokeUpAt.difference(fellAsleepAt).inMinutes
        : null;

    final parts = <String>[sleepType];
    if (durationMinutes != null && durationMinutes > 0) {
      parts.add(_formatDurationMinutes(durationMinutes));
    }
    if (location.isNotEmpty) {
      parts.add(location);
    }
    return parts.join(' · ');
  }

  String _buildDiaperDetailSummary(Map<String, dynamic> row) {
    final diaperType = _diaperTypeLabel(row['diaper_type'] as String?);
    final rashObserved = row['rash_observed'] as bool? ?? false;
    final stoolColor = (row['stool_color'] as String? ?? '').trim();
    final stoolTexture = (row['stool_texture'] as String? ?? '').trim();

    final parts = <String>[diaperType];
    if (stoolColor.isNotEmpty) {
      parts.add(stoolColor);
    }
    if (stoolTexture.isNotEmpty) {
      parts.add(stoolTexture);
    }
    parts.add(rashObserved ? '발진 있음' : '발진 없음');
    return parts.join(' · ');
  }

  String _feedingContentLabel(String? contentType) {
    switch (contentType) {
      case 'formula':
        return '분유';
      case 'breast_milk':
        return '모유';
      case 'mixed':
        return '혼합';
      default:
        return contentType ?? '';
    }
  }

  String _breastSideLabel(String? breastSide) {
    switch (breastSide) {
      case 'left':
        return '왼쪽';
      case 'right':
        return '오른쪽';
      case 'both':
        return '양쪽';
      default:
        return '양쪽';
    }
  }

  String _sleepTypeLabel(String? sleepType) {
    switch (sleepType) {
      case 'nap':
        return '낮잠';
      case 'night':
        return '밤잠';
      default:
        return sleepType ?? '수면';
    }
  }

  String _diaperTypeLabel(String? diaperType) {
    switch (diaperType) {
      case 'wet':
        return '소변';
      case 'dirty':
        return '대변';
      case 'mixed':
        return '혼합';
      case 'dry':
        return '건조';
      default:
        return diaperType ?? '기저귀';
    }
  }

  String _formatDurationMinutes(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes분';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '$hours시간';
    }
    return '$hours시간 $minutes분';
  }

  String _formatNumericValue(Object? value) {
    if (value is num) {
      return value == value.roundToDouble()
          ? value.toInt().toString()
          : value.toDouble().toStringAsFixed(1);
    }
    return value?.toString() ?? '0';
  }
}
