import 'package:supabase_flutter/supabase_flutter.dart';

import '../../activity/domain/activity_event_summary.dart';
import '../domain/activity_analytics_summary.dart';

class AnalyticsRepository {
  AnalyticsRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<ActivityAnalyticsSummary> fetchSummary({String? babyId}) async {
    final user = currentUser;
    if (user == null) return _emptySummary();

    final householdIds = await _fetchActiveHouseholdIds(user.id);
    if (householdIds.isEmpty) return _emptySummary();

    final nowUtc = DateTime.now().toUtc();
    final since7d = nowUtc.subtract(const Duration(days: 7));
    final since24h = nowUtc.subtract(const Duration(days: 1));

    final events = await _fetchEvents(
      householdIds: householdIds,
      since: since7d,
      babyId: babyId,
    );

    if (events.isEmpty) return _emptySummary();

    final recent24hEvents = events.where((event) {
      final recordedAt = _parseRecordedAt(event.recordedAt);
      return recordedAt != null && !recordedAt.isBefore(since24h);
    }).toList();

    final recent24hTypeCounts = _countByType(recent24hEvents);
    final recent7dTypeCounts = _countByType(events);

    final feedingEvents = events
        .where(
          (event) =>
              event.eventTypeSlug == 'bottle_feeding' ||
              event.eventTypeSlug == 'breastfeeding',
        )
        .toList();
    final sleepEvents = events
        .where((event) => event.eventTypeSlug == 'sleep')
        .toList();
    final diaperEvents = events
        .where((event) => event.eventTypeSlug == 'diaper')
        .toList();

    final feedingDetails = await _fetchFeedingDetails(feedingEvents);
    final sleepDetails = await _fetchSleepDetails(sleepEvents);
    final diaperDetails = await _fetchDiaperDetails(diaperEvents);
    final recent24hFeedingCount = _countRecentEvents(feedingEvents, since24h);
    final recent24hSleepCount = _countRecentEvents(sleepEvents, since24h);
    final recent24hDiaperCount = _countRecentEvents(diaperEvents, since24h);

    return ActivityAnalyticsSummary(
      totalEvents: events.length,
      distinctTypes: recent7dTypeCounts.length,
      latestEventType: events.first.eventTypeSlug,
      latestRecordedAt: _formatRecordedAt(events.first.recordedAt),
      typeCounts: recent7dTypeCounts,
      recent24hCount: recent24hEvents.length,
      recent7dCount: events.length,
      recent24hTypeCounts: recent24hTypeCounts,
      recent7dTypeCounts: recent7dTypeCounts,
      feedingInsight: _buildFeedingInsight(
        events: feedingEvents,
        detailRows: feedingDetails,
        recent24hCount: recent24hFeedingCount,
      ),
      sleepInsight: _buildSleepInsight(
        events: sleepEvents,
        detailRows: sleepDetails,
        recent24hCount: recent24hSleepCount,
      ),
      diaperInsight: _buildDiaperInsight(
        events: diaperEvents,
        detailRows: diaperDetails,
        recent24hCount: recent24hDiaperCount,
      ),
      dataInsight: _buildDataInsight(events.length, recent24hEvents.length),
    );
  }

  Future<List<String>> _fetchActiveHouseholdIds(String userId) async {
    final memberships = await _client
        .from('household_memberships')
        .select('household_id')
        .eq('user_id', userId)
        .eq('status', 'active');

    return List<Map<String, dynamic>>.from(
      memberships,
    ).map((row) => row['household_id'] as String).toList();
  }

  Future<List<ActivityEventSummary>> _fetchEvents({
    required List<String> householdIds,
    required DateTime since,
    String? babyId,
  }) async {
    var query = _client
        .from('activity_events')
        .select('id, baby_id, event_type_slug, status, recorded_at, note')
        .inFilter('household_id', householdIds)
        .isFilter('deleted_at', null)
        .gte('recorded_at', since.toIso8601String());

    if (babyId != null) {
      query = query.eq('baby_id', babyId);
    }

    final events = await query.order('recorded_at', ascending: false);

    return List<Map<String, dynamic>>.from(
      events,
    ).map(ActivityEventSummary.fromJson).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchFeedingDetails(
    List<ActivityEventSummary> events,
  ) async {
    if (events.isEmpty) return const [];

    final eventIds = events.map((event) => event.id).toList();
    final rows = await _client
        .from('feeding_event_details')
        .select(
          'event_id, feeding_mode, breast_side, left_duration_sec, right_duration_sec, amount_value, amount_unit, content_type',
        )
        .inFilter('event_id', eventIds);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> _fetchSleepDetails(
    List<ActivityEventSummary> events,
  ) async {
    if (events.isEmpty) return const [];

    final eventIds = events.map((event) => event.id).toList();
    final rows = await _client
        .from('sleep_event_details')
        .select('event_id, sleep_type, location, fell_asleep_at, woke_up_at')
        .inFilter('event_id', eventIds);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> _fetchDiaperDetails(
    List<ActivityEventSummary> events,
  ) async {
    if (events.isEmpty) return const [];

    final eventIds = events.map((event) => event.id).toList();
    final rows = await _client
        .from('diaper_event_details')
        .select(
          'event_id, diaper_type, stool_color, stool_texture, rash_observed',
        )
        .inFilter('event_id', eventIds);

    return List<Map<String, dynamic>>.from(rows);
  }

  ActivityAnalyticsSummary _emptySummary() {
    return ActivityAnalyticsSummary(
      totalEvents: 0,
      distinctTypes: 0,
      latestEventType: null,
      latestRecordedAt: null,
      typeCounts: const {},
      recent24hCount: 0,
      recent7dCount: 0,
      recent24hTypeCounts: const {},
      recent7dTypeCounts: const {},
      feedingInsight: '최근 7일 수유 기록이 아직 없습니다. 수유 패턴은 기록이 쌓이면 자동으로 보입니다.',
      sleepInsight: '최근 7일 수면 기록이 아직 없습니다. 수면 패턴은 기록이 쌓이면 자동으로 보입니다.',
      diaperInsight: '최근 7일 기저귀 기록이 아직 없습니다. 기저귀 패턴은 기록이 쌓이면 자동으로 보입니다.',
      dataInsight: '기록이 아직 없어 24시간/7일 요약과 패턴 분석을 보여드리기 어렵습니다.',
    );
  }

  Map<String, int> _countByType(List<ActivityEventSummary> events) {
    final counts = <String, int>{};
    for (final event in events) {
      counts.update(
        event.eventTypeSlug,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return counts;
  }

  int _countRecentEvents(List<ActivityEventSummary> events, DateTime since) {
    return events.where((event) {
      final recordedAt = _parseRecordedAt(event.recordedAt);
      return recordedAt != null && !recordedAt.isBefore(since);
    }).length;
  }

  String _buildFeedingInsight({
    required List<ActivityEventSummary> events,
    required List<Map<String, dynamic>> detailRows,
    required int recent24hCount,
  }) {
    if (events.isEmpty) {
      return '최근 7일 수유 기록이 아직 없습니다. 수유 패턴은 기록이 쌓이면 자동으로 보입니다.';
    }

    final modeCounts = <String, int>{};
    final contentCounts = <String, int>{};
    final bottleAmounts = <double>[];
    final breastDurationsMinutes = <double>[];
    final timeBucketCounts = <String, int>{};

    final detailByEventId = {
      for (final row in detailRows) row['event_id'] as String: row,
    };

    for (final event in events) {
      final detail = detailByEventId[event.id];
      if (detail == null) continue;

      final mode = _stringValue(detail['feeding_mode']);
      if (mode.isNotEmpty) {
        modeCounts.update(mode, (count) => count + 1, ifAbsent: () => 1);
      }

      final contentType = _stringValue(detail['content_type']);
      if (contentType.isNotEmpty) {
        contentCounts.update(
          contentType,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final amountValue = _doubleValue(detail['amount_value']);
      if (mode == 'bottle' && amountValue != null) {
        bottleAmounts.add(amountValue);
      }

      final leftDuration = _intValue(detail['left_duration_sec']) ?? 0;
      final rightDuration = _intValue(detail['right_duration_sec']) ?? 0;
      final durationSeconds = leftDuration + rightDuration;
      if (mode == 'breast' && durationSeconds > 0) {
        breastDurationsMinutes.add(durationSeconds / 60);
      }

      _incrementTimeBucket(
        timeBucketCounts,
        _timeBucketLabel(event.recordedAt),
      );
    }

    final parts = <String>[
      '최근 7일 수유 기록 ${events.length}건(최근 24시간 $recent24hCount건)입니다.',
    ];

    final modeSentence = _describeCounts(
      modeCounts,
      labels: const {'bottle': '젖병/분유', 'breast': '모유수유'},
      fallbackLabel: '수유',
    );
    if (modeSentence.isNotEmpty) {
      parts.add(modeSentence);
    }

    final contentSentence = _describeCounts(
      contentCounts,
      labels: const {'formula': '분유', 'breast_milk': '모유', 'mixed': '혼합'},
      fallbackLabel: '수유 내용',
    );
    if (contentSentence.isNotEmpty) {
      parts.add(contentSentence);
    }

    final avgBottle = _average(bottleAmounts);
    if (avgBottle != null) {
      parts.add('젖병 수유 평균량은 ${avgBottle.toStringAsFixed(0)}ml입니다.');
    }

    final avgBreastMinutes = _average(breastDurationsMinutes);
    if (avgBreastMinutes != null) {
      parts.add('모유수유 평균 시간은 ${avgBreastMinutes.toStringAsFixed(1)}분입니다.');
    }

    final topBucket = _topBucketLabel(timeBucketCounts);
    if (topBucket != null) {
      parts.add('가장 자주 기록된 시간대는 $topBucket입니다.');
    }

    return parts.join(' ');
  }

  String _buildSleepInsight({
    required List<ActivityEventSummary> events,
    required List<Map<String, dynamic>> detailRows,
    required int recent24hCount,
  }) {
    if (events.isEmpty) {
      return '최근 7일 수면 기록이 아직 없습니다. 수면 패턴은 기록이 쌓이면 자동으로 보입니다.';
    }

    final typeCounts = <String, int>{};
    final locationCounts = <String, int>{};
    final durationMinutes = <double>[];
    final timeBucketCounts = <String, int>{};
    final detailByEventId = {
      for (final row in detailRows) row['event_id'] as String: row,
    };

    for (final event in events) {
      final detail = detailByEventId[event.id];
      if (detail == null) continue;

      final sleepType = _stringValue(detail['sleep_type']);
      if (sleepType.isNotEmpty) {
        typeCounts.update(sleepType, (count) => count + 1, ifAbsent: () => 1);
      }

      final location = _stringValue(detail['location']);
      if (location.isNotEmpty) {
        locationCounts.update(
          location,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      final fellAsleepAt = _parseRecordedAt(
        _stringValue(detail['fell_asleep_at']),
      );
      final wokeUpAt = _parseRecordedAt(_stringValue(detail['woke_up_at']));
      if (fellAsleepAt != null && wokeUpAt != null) {
        final duration = wokeUpAt.difference(fellAsleepAt);
        if (!duration.isNegative) {
          durationMinutes.add(duration.inSeconds / 60);
        }
      }

      _incrementTimeBucket(
        timeBucketCounts,
        _timeBucketLabel(event.recordedAt),
      );
    }

    final parts = <String>[
      '최근 7일 수면 기록 ${events.length}건(최근 24시간 $recent24hCount건)입니다.',
    ];

    final typeSentence = _describeCounts(
      typeCounts,
      labels: const {'nap': '낮잠', 'night': '밤잠'},
      fallbackLabel: '수면',
    );
    if (typeSentence.isNotEmpty) {
      parts.add(typeSentence);
    }

    final avgDuration = _average(durationMinutes);
    if (avgDuration != null) {
      parts.add('평균 수면 시간은 ${_formatDuration(avgDuration)}입니다.');
    }

    final locationSentence = _describeTopLabel(
      locationCounts,
      formatter: (value) => value,
    );
    if (locationSentence != null) {
      parts.add('가장 많이 기록된 장소는 $locationSentence입니다.');
    }

    final topBucket = _topBucketLabel(timeBucketCounts);
    if (topBucket != null) {
      parts.add('수면 기록이 가장 많은 시간대는 $topBucket입니다.');
    }

    return parts.join(' ');
  }

  String _buildDiaperInsight({
    required List<ActivityEventSummary> events,
    required List<Map<String, dynamic>> detailRows,
    required int recent24hCount,
  }) {
    if (events.isEmpty) {
      return '최근 7일 기저귀 기록이 아직 없습니다. 기저귀 패턴은 기록이 쌓이면 자동으로 보입니다.';
    }

    final typeCounts = <String, int>{};
    final colorCounts = <String, int>{};
    final textureCounts = <String, int>{};
    int rashObservedCount = 0;
    final timeBucketCounts = <String, int>{};
    final detailByEventId = {
      for (final row in detailRows) row['event_id'] as String: row,
    };

    for (final event in events) {
      final detail = detailByEventId[event.id];
      if (detail == null) continue;

      final diaperType = _stringValue(detail['diaper_type']);
      if (diaperType.isNotEmpty) {
        typeCounts.update(diaperType, (count) => count + 1, ifAbsent: () => 1);
      }

      final stoolColor = _stringValue(detail['stool_color']);
      if (stoolColor.isNotEmpty) {
        colorCounts.update(stoolColor, (count) => count + 1, ifAbsent: () => 1);
      }

      final stoolTexture = _stringValue(detail['stool_texture']);
      if (stoolTexture.isNotEmpty) {
        textureCounts.update(
          stoolTexture,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      if (detail['rash_observed'] == true) {
        rashObservedCount += 1;
      }

      _incrementTimeBucket(
        timeBucketCounts,
        _timeBucketLabel(event.recordedAt),
      );
    }

    final parts = <String>[
      '최근 7일 기저귀 기록 ${events.length}건(최근 24시간 $recent24hCount건)입니다.',
    ];

    final typeSentence = _describeCounts(
      typeCounts,
      labels: const {'wet': '젖은 기저귀', 'dirty': '대변', 'mixed': '혼합'},
      fallbackLabel: '기저귀',
    );
    if (typeSentence.isNotEmpty) {
      parts.add(typeSentence);
    }

    if (rashObservedCount > 0) {
      parts.add('발진 관찰 기록은 $rashObservedCount건입니다.');
    }

    final colorSentence = _describeTopLabel(
      colorCounts,
      formatter: (value) => value,
    );
    if (colorSentence != null) {
      parts.add('가장 많이 기록된 대변 색상은 $colorSentence입니다.');
    }

    final textureSentence = _describeTopLabel(
      textureCounts,
      formatter: (value) => value,
    );
    if (textureSentence != null) {
      parts.add('가장 많이 기록된 대변 질감은 $textureSentence입니다.');
    }

    final topBucket = _topBucketLabel(timeBucketCounts);
    if (topBucket != null) {
      parts.add('기저귀 기록이 가장 많은 시간대는 $topBucket입니다.');
    }

    return parts.join(' ');
  }

  String _buildDataInsight(int recent7dCount, int recent24hCount) {
    if (recent7dCount == 0) {
      return '기록이 아직 없어 24시간/7일 요약과 패턴 분석을 보여드리기 어렵습니다.';
    }

    if (recent7dCount < 3) {
      return '최근 7일 기록이 $recent7dCount건이라 패턴은 참고용입니다. 기록이 더 쌓이면 24시간/7일 비교와 시간대 분석이 더 선명해집니다.';
    }

    if (recent24hCount == 0) {
      return '최근 24시간 기록이 없어서 오늘의 변화는 아직 보이지 않습니다. 하지만 최근 7일 패턴은 충분히 참고할 수 있습니다.';
    }

    return '최근 7일 기록을 기준으로 24시간/7일 비교와 수유·수면·기저귀 패턴을 함께 볼 수 있습니다.';
  }

  String _describeCounts(
    Map<String, int> counts, {
    required Map<String, String> labels,
    required String fallbackLabel,
  }) {
    if (counts.isEmpty) return '';

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final parts = sortedEntries.take(3).map((entry) {
      final label = labels[entry.key] ?? entry.key;
      return '$label ${entry.value}건';
    }).toList();

    return '$fallbackLabel 분포는 ${parts.join(', ')}입니다.';
  }

  String? _describeTopLabel(
    Map<String, int> counts, {
    required String Function(String value) formatter,
  }) {
    if (counts.isEmpty) return null;

    final topEntry = counts.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );

    return formatter(topEntry.key);
  }

  void _incrementTimeBucket(Map<String, int> counts, String bucket) {
    counts.update(bucket, (count) => count + 1, ifAbsent: () => 1);
  }

  String? _topBucketLabel(Map<String, int> counts) {
    if (counts.isEmpty) return null;
    final topEntry = counts.entries.reduce(
      (current, next) => next.value > current.value ? next : current,
    );
    return topEntry.key;
  }

  String _timeBucketLabel(String recordedAt) {
    final parsed = _parseRecordedAt(recordedAt);
    if (parsed == null) return '기타';

    final hour = parsed.hour;
    if (hour >= 5 && hour < 11) return '오전(05:00~10:59)';
    if (hour >= 11 && hour < 17) return '오후(11:00~16:59)';
    if (hour >= 17 && hour < 22) return '저녁(17:00~21:59)';
    return '밤/새벽(22:00~04:59)';
  }

  DateTime? _parseRecordedAt(String recordedAt) {
    try {
      return DateTime.parse(recordedAt).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _formatRecordedAt(String recordedAt) {
    final parsed = _parseRecordedAt(recordedAt);
    if (parsed == null) return recordedAt;

    final year = parsed.year.toString().padLeft(4, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final day = parsed.day.toString().padLeft(2, '0');
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  double? _average(List<double> values) {
    if (values.isEmpty) return null;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    return total / values.length;
  }

  String _formatDuration(double totalMinutes) {
    final roundedMinutes = totalMinutes.round();
    final hours = roundedMinutes ~/ 60;
    final minutes = roundedMinutes % 60;

    if (hours == 0) {
      return '$minutes분';
    }

    return minutes == 0 ? '$hours시간' : '$hours시간 $minutes분';
  }

  String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  double? _doubleValue(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  int? _intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
