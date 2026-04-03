class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.projectRef,
  });

  factory AppConfig.fromEnvironment() {
    const environment = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const projectRef = String.fromEnvironment('SUPABASE_PROJECT_REF');

    return AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      projectRef: projectRef.isNotEmpty
          ? projectRef
          : _projectRefFromUrl(supabaseUrl),
    );
  }

  final String environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String projectRef;

  bool get hasSupabaseCredentials =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  String get redactedAnonKey {
    if (supabaseAnonKey.length <= 8) return 'not-set';
    return '${supabaseAnonKey.substring(0, 4)}••••${supabaseAnonKey.substring(supabaseAnonKey.length - 4)}';
  }

  static String _projectRefFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final host = uri?.host ?? '';
    if (host.isEmpty) return 'unknown';

    final firstSegment = host.split('.').first;
    return firstSegment.isEmpty ? 'unknown' : firstSegment;
  }
}
