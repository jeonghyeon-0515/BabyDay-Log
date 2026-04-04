class ActivityFeedingDetails {
  const ActivityFeedingDetails({
    required this.feedingMode,
    this.breastSide,
    this.durationMinutes,
    this.amountValue,
    this.amountUnit,
    this.contentType,
  });

  final String feedingMode;
  final String? breastSide;
  final int? durationMinutes;
  final double? amountValue;
  final String? amountUnit;
  final String? contentType;
}

class ActivitySleepDetails {
  const ActivitySleepDetails({
    required this.sleepType,
    required this.durationMinutes,
    this.location,
  });

  final String sleepType;
  final int durationMinutes;
  final String? location;
}

class ActivityDiaperDetails {
  const ActivityDiaperDetails({
    required this.diaperType,
    required this.rashObserved,
    this.stoolColor,
    this.stoolTexture,
  });

  final String diaperType;
  final bool rashObserved;
  final String? stoolColor;
  final String? stoolTexture;
}
