# 인증 제공자 전략

작성일: 2026-04-03  
상태: Draft v1
전제: Flutter + Supabase

## 1. 결정 사항
사용자 요청 기준 로그인 제공자는 아래 순서로 진행한다.

1. **카카오 로그인**
2. **네이버 로그인**
3. **구글 로그인**

이 순서는 다음 두 의미를 가진다.
- **구현 우선순위**
- **앱 UI 노출 우선순위**

## 2. 왜 이 순서인가

### 방법 1. 구글 우선
- 장점: 구현이 쉬움
- 단점: 한국 육아 앱의 실제 체감/전환율과 맞지 않을 수 있음

### 방법 2. 카카오 → 네이버 → 구글
- 장점: 한국 사용자 친화성 높음
- 장점: 실제 서비스 사용성을 높이는 방향
- 단점: Supabase에서 네이버는 별도 구성이 필요할 수 있음

### 방법 3. 이메일 먼저, 소셜 로그인 후순위
- 장점: 구현 단순
- 단점: 초반 가입 전환율 저하 가능성 큼

## 3. 최종 선택
**선택: 카카오 → 네이버 → 구글**

## 4. 공식 문서 기반 기술 판단

### 카카오
- 카카오는 공식적으로 OpenID Connect 메타데이터를 제공한다.
- Supabase Auth는 소셜 로그인과 OIDC/SSO 구성을 지원한다.
- 따라서 카카오는 **Supabase Auth 기반 소셜 로그인**으로 연동하는 방향이 적합하다.

### 네이버
- 네이버는 공식 개발자 문서에서 OpenID Connect를 제공한다.
- Supabase 공식 문서상 OIDC/SSO 및 커스텀 프로바이더 구성이 가능하다.
- 따라서 네이버는 **Supabase의 커스텀 OIDC/SSO 구성**으로 붙이는 방향이 유력하다.

### 구글
- Supabase는 공식 문서상 Google 소셜 로그인을 기본 지원한다.
- 따라서 구글은 가장 구현 리스크가 낮은 보조 소셜 로그인으로 두면 된다.

## 5. 구현 전략

### Phase A. 카카오 로그인
목표:
- 한국 사용자 기준 가장 익숙한 로그인 채널 제공

작업:
- Kakao Developers 앱 생성
- Redirect URI 등록
- Supabase Auth provider 설정
- Flutter 로그인 버튼/콜백 처리

### Phase B. 네이버 로그인
목표:
- 카카오 미사용자를 위한 한국형 대체 채널 확보

작업:
- Naver Developers 앱 생성
- OIDC/로그인 설정 확인
- Supabase OIDC 또는 커스텀 provider 구성
- Flutter 로그인 버튼/콜백 처리

### Phase C. 구글 로그인
목표:
- 글로벌/안드로이드 친화 로그인 제공

작업:
- Google Cloud OAuth 앱 생성
- Supabase Google provider 설정
- Flutter 로그인 버튼/콜백 처리

## 6. 앱 UX 규칙
- 로그인 화면의 버튼 순서는 `카카오 > 네이버 > 구글`로 배치한다.
- Apple 로그인은 iOS 배포 시 추후 검토 대상으로 둔다.
- 이메일 로그인은 운영/복구 목적의 보조 수단으로만 둘지 여부를 별도 검토한다.

## 7. 데이터 모델 영향
현재 스키마에서는 소셜 로그인별 별도 테이블이 없어도 된다.
이유:
- 사용자 식별은 `auth.users` / `profiles`로 통합 가능
- 공급자별 정보는 Supabase Auth에서 관리 가능

단, 추후 아래가 필요하면 별도 테이블을 추가한다.
- 공급자 연동 상태 추적
- 마케팅/전환 분석
- 공급자별 재연결 오류 복구

후속 후보:
- `auth_provider_links`

## 8. 리스크와 대응

### 리스크 1. 네이버가 Supabase 기본 제공 provider가 아닐 수 있음
대응:
- 네이버는 OIDC/커스텀 provider 기준으로 설계한다.
- 초기 스파이크 구현에서 가장 먼저 검증한다.

### 리스크 2. 카카오/네이버 redirect 설정 오류
대응:
- dev/stage/prod 환경별 redirect URI 문서화
- Supabase Dashboard 설정값과 앱 설정값을 체크리스트화

### 리스크 3. 공급자별 사용자 정보 포맷 차이
대응:
- 가입 직후 `profiles` 정규화 로직으로 통일한다.
- 표시명/프로필 이미지는 공급자 원본과 분리 관리한다.

## 9. 당신이 해야 하는 것
제가 다음 구현 단계로 넘어가기 전에 아래 정보/준비가 필요합니다.

### 필수
1. **Kakao Developers 앱 생성**
2. **Naver Developers 앱 생성**
3. **Google Cloud OAuth 앱 생성**

### 저에게 필요해지는 값
환경별로 아래가 필요합니다.
- Client ID
- Client Secret
- Redirect URI
- Bundle ID / Package name
- iOS URL Scheme / Android SHA-1(구글 필요 시)

### 권장 정리 형식
환경별로 표 형태로 정리해주세요.
- dev
- stage
- prod

## 10. 참고 출처
- Supabase Auth 개요: https://supabase.com/docs/guides/auth
- Supabase Social Login: https://supabase.com/docs/guides/auth/social-login
- Supabase SSO / OIDC: https://supabase.com/docs/guides/auth/enterprise-sso/auth-sso-saml
- Kakao OpenID Connect: https://developers.kakao.com/docs/latest/ko/kakaologin/rest-api
- Naver Login / OIDC: https://developers.naver.com/docs/login/openid/openid.md
