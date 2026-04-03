class HouseholdSummary {
  const HouseholdSummary({
    required this.id,
    required this.name,
    required this.locale,
    required this.timezone,
    required this.growthChartStandard,
    required this.role,
    required this.status,
  });

  final String id;
  final String name;
  final String locale;
  final String timezone;
  final String growthChartStandard;
  final String role;
  final String status;
}
