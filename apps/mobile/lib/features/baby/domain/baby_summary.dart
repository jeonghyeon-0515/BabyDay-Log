class BabySummary {
  const BabySummary({
    required this.id,
    required this.householdId,
    required this.name,
    required this.birthDate,
    required this.sex,
  });

  factory BabySummary.fromJson(Map<String, dynamic> json) {
    return BabySummary(
      id: json['id'] as String,
      householdId: json['household_id'] as String,
      name: json['name'] as String? ?? 'unknown',
      birthDate: json['birth_date'] as String? ?? 'unknown',
      sex: json['sex'] as String? ?? 'unknown',
    );
  }

  final String id;
  final String householdId;
  final String name;
  final String birthDate;
  final String sex;
}
