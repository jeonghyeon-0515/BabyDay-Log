import 'activity_event_type.dart';

class ActivityEventSummary {
  const ActivityEventSummary({
    required this.id,
    required this.babyId,
    required this.eventTypeSlug,
    required this.status,
    required this.recordedAt,
    this.note,
    this.detailSummary,
  });

  factory ActivityEventSummary.fromJson(Map<String, dynamic> json) {
    return ActivityEventSummary(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      eventTypeSlug: json['event_type_slug'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      recordedAt: json['recorded_at'] as String? ?? 'unknown',
      note: json['note'] as String?,
      detailSummary: json['detail_summary'] as String?,
    );
  }

  ActivityEventSummary copyWith({
    String? id,
    String? babyId,
    String? eventTypeSlug,
    String? status,
    String? recordedAt,
    String? note,
    String? detailSummary,
  }) {
    return ActivityEventSummary(
      id: id ?? this.id,
      babyId: babyId ?? this.babyId,
      eventTypeSlug: eventTypeSlug ?? this.eventTypeSlug,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
      note: note ?? this.note,
      detailSummary: detailSummary ?? this.detailSummary,
    );
  }

  final String id;
  final String babyId;
  final String eventTypeSlug;
  final String status;
  final String recordedAt;
  final String? note;
  final String? detailSummary;

  String get eventTypeLabel => activityEventTypeLabel(eventTypeSlug);

  bool get isFeeding =>
      eventTypeSlug == 'bottle_feeding' || eventTypeSlug == 'breastfeeding';

  bool get isSleep => eventTypeSlug == 'sleep';

  bool get isDiaper => eventTypeSlug == 'diaper';

  DateTime? get recordedAtDateTime => DateTime.tryParse(recordedAt)?.toLocal();

  String get displayDetailSummary => detailSummary?.trim().isNotEmpty == true
      ? detailSummary!.trim()
      : '세부 정보 없음';

  String get displayNote =>
      note?.trim().isNotEmpty == true ? note!.trim() : '메모 없음';
}
