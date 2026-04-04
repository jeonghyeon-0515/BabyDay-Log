class DiaryEntrySummary {
  const DiaryEntrySummary({
    required this.id,
    required this.babyId,
    required this.visibility,
    required this.body,
    this.title,
    this.eventDate,
  });

  factory DiaryEntrySummary.fromJson(Map<String, dynamic> json) {
    return DiaryEntrySummary(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      visibility: json['visibility'] as String? ?? 'private',
      body: json['body'] as String? ?? '',
      title: json['title'] as String?,
      eventDate: json['event_date'] as String?,
    );
  }

  final String id;
  final String babyId;
  final String visibility;
  final String body;
  final String? title;
  final String? eventDate;
}
