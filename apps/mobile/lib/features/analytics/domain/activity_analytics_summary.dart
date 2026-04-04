class ActivityAnalyticsSummary {
  const ActivityAnalyticsSummary({
    required this.totalEvents,
    required this.distinctTypes,
    required this.latestEventType,
    required this.latestRecordedAt,
    required this.typeCounts,
  });

  final int totalEvents;
  final int distinctTypes;
  final String? latestEventType;
  final String? latestRecordedAt;
  final Map<String, int> typeCounts;
}
