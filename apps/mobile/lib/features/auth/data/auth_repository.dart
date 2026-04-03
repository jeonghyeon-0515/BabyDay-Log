import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/app_auth_provider.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> authStateChanges() => _client.auth.onAuthStateChange;

  Future<bool> signInWithProvider(AppAuthProvider provider) async {
    final oauthProvider = provider.oauthProvider;

    if (oauthProvider == null) {
      throw UnsupportedError(
        '${provider.shortLabel} 로그인은 Supabase 커스텀 OIDC 구성이 필요합니다.',
      );
    }

    return _client.auth.signInWithOAuth(oauthProvider);
  }

  Future<void> signOut() => _client.auth.signOut();
}
