import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity_event_summary.dart';
import '../domain/activity_analytics_summary.dart';

class AnalyticsRepository {
  AnalyticsRepository({ActivityRepository? activityRepository})
    : _activityRepository = activityRepository ?? ActivityRepository();

  final ActivityRepository _activityRepository;

  Future<ActivityAnalyticsSummary> fetchSummary() async {
    final events = await _activityRepository.fetchRecentActivityEvents(
      limit: 50,
    );
    return _buildSummary(events);
  }

  ActivityAnalyticsSummary _buildSummary(List<ActivityEventSummary> events) {
    final typeCounts = <String, int>{};
    for (final event in events) {
      typeCounts.update(
        event.eventTypeSlug,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final latestEvent = events.isEmpty ? null : events.first;

    return ActivityAnalyticsSummary(
      totalEvents: events.length,
      distinctTypes: typeCounts.length,
      latestEventType: latestEvent?.eventTypeSlug,
      latestRecordedAt: latestEvent?.recordedAt,
      typeCounts: typeCounts,
    );
  }
}
