import 'package:supabase_flutter/supabase_flutter.dart';

enum AppAuthProvider {
  kakao,
  naver,
  google;

  String get label => switch (this) {
    AppAuthProvider.kakao => '카카오 로그인',
    AppAuthProvider.naver => '네이버 로그인',
    AppAuthProvider.google => '구글 로그인',
  };

  String get shortLabel => switch (this) {
    AppAuthProvider.kakao => '카카오',
    AppAuthProvider.naver => '네이버',
    AppAuthProvider.google => '구글',
  };

  OAuthProvider? get oauthProvider => switch (this) {
    AppAuthProvider.kakao => OAuthProvider.kakao,
    AppAuthProvider.naver => null,
    AppAuthProvider.google => OAuthProvider.google,
  };

  bool get isDirectlySupportedByCurrentStack => oauthProvider != null;

  String get helperText => switch (this) {
    AppAuthProvider.kakao => 'Supabase OAuth provider 연결 후 바로 사용 가능',
    AppAuthProvider.naver => 'Supabase 커스텀 OIDC 구성 후 연결 예정',
    AppAuthProvider.google => 'Supabase 기본 Google provider 연결 후 사용 가능',
  };
}
