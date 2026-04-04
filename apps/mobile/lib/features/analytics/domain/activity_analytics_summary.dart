class ActivityAnalyticsSummary {
  const ActivityAnalyticsSummary({
    required this.totalEvents,
    required this.distinctTypes,
    required this.latestEventType,
    required this.latestRecordedAt,
    required this.typeCounts,
    required this.recent24hCount,
    required this.recent7dCount,
    required this.recent24hTypeCounts,
    required this.recent7dTypeCounts,
    required this.feedingInsight,
    required this.sleepInsight,
    required this.diaperInsight,
    required this.dataInsight,
  });

  final int totalEvents;
  final int distinctTypes;
  final String? latestEventType;
  final String? latestRecordedAt;
  final Map<String, int> typeCounts;
  final int recent24hCount;
  final int recent7dCount;
  final Map<String, int> recent24hTypeCounts;
  final Map<String, int> recent7dTypeCounts;
  final String feedingInsight;
  final String sleepInsight;
  final String diaperInsight;
  final String dataInsight;

  bool get hasData => recent7dCount > 0;
  bool get hasEnoughRecentData => recent7dCount >= 3;
}
