class DiaryEntrySummary {
  const DiaryEntrySummary({
    required this.id,
    required this.babyId,
    required this.authorUserId,
    required this.visibility,
    required this.body,
    this.title,
    this.eventDate,
  });

  factory DiaryEntrySummary.fromJson(Map<String, dynamic> json) {
    return DiaryEntrySummary(
      id: json['id'] as String,
      babyId: json['baby_id'] as String,
      authorUserId: json['author_user_id'] as String?,
      visibility: json['visibility'] as String? ?? 'private',
      body: json['body'] as String? ?? '',
      title: json['title'] as String?,
      eventDate: json['event_date'] as String?,
    );
  }

  final String id;
  final String babyId;
  final String? authorUserId;
  final String visibility;
  final String body;
  final String? title;
  final String? eventDate;

  String get titleDisplay => title?.isNotEmpty == true ? title! : '(제목 없음)';

  String get visibilityLabel {
    switch (visibility) {
      case 'private':
        return '비공개';
      case 'household':
        return '가족 공유';
      case 'public':
        return '공개';
      default:
        return visibility;
    }
  }

  String authorLabel({String? currentUserId}) {
    if (authorUserId == null) {
      return '작성자: 미상';
    }

    if (currentUserId != null && authorUserId == currentUserId) {
      return '작성자: 나';
    }

    return '작성자: 다른 사용자';
  }

  String get eventDateLabel =>
      eventDate?.isNotEmpty == true ? eventDate! : '미지정';
}
