class ActivityEventTypeInfo {
  const ActivityEventTypeInfo({required this.slug, required this.label});

  final String slug;
  final String label;
}

const List<ActivityEventTypeInfo> activityEventTypes = [
  ActivityEventTypeInfo(slug: 'bottle_feeding', label: '젖병/분유'),
  ActivityEventTypeInfo(slug: 'breastfeeding', label: '모유수유'),
  ActivityEventTypeInfo(slug: 'sleep', label: '수면'),
  ActivityEventTypeInfo(slug: 'diaper', label: '기저귀'),
];

const Map<String, String> activityEventTypeLabels = {
  'bottle_feeding': '젖병/분유',
  'breastfeeding': '모유수유',
  'sleep': '수면',
  'diaper': '기저귀',
};

String activityEventTypeLabel(String slug) {
  return activityEventTypeLabels[slug] ?? slug;
}
