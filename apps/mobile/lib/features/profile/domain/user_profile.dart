class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.locale,
    required this.timezone,
    this.avatarPath,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'unknown',
      locale: json['locale'] as String? ?? 'ko',
      timezone: json['timezone'] as String? ?? 'Asia/Seoul',
      avatarPath: json['avatar_path'] as String?,
    );
  }

  final String id;
  final String displayName;
  final String locale;
  final String timezone;
  final String? avatarPath;
}
