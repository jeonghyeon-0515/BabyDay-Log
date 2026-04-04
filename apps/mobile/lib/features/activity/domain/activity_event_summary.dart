import 'activity_event_type.dart';

class ActivityEventSummary {
  const ActivityEventSummary({
    required this.id,
    required this.babyId,
    required this.eventTypeSlug,
    required this.status,
    required this.recordedAt,
    this.note,
  });

  factory ActivityEventSummary.fromJson(Map<String, dynamic> json) {
    return ActivityEventSummary(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      eventTypeSlug: json['event_type_slug'] as String? ?? 'unknown',
      status: json['status'] as String? ?? 'unknown',
      recordedAt: json['recorded_at'] as String? ?? 'unknown',
      note: json['note'] as String?,
    );
  }

  final String id;
  final String babyId;
  final String eventTypeSlug;
  final String status;
  final String recordedAt;
  final String? note;

  String get eventTypeLabel => activityEventTypeLabel(eventTypeSlug);
}
