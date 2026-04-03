# Supabase 프로젝트 적용 가이드

작성일: 2026-04-03  
상태: Draft v1

## 1. 현재 확정 정보
- Supabase Project Ref: `nnzwtoohzwubpigijjvj`
- Supabase URL: `https://nnzwtoohzwubpigijjvj.supabase.co`
- migration 초안 위치: `supabase/migrations/20260403153000_init_core_schema.sql`

## 2. 보안 원칙
1. **anon key는 클라이언트 앱에서만 사용한다.**
2. **service role key는 Flutter 앱에 넣지 않는다. 절대 클라이언트 번들에 포함하면 안 된다.**
3. service role key는 오직 아래 용도로만 사용한다.
   - Edge Functions
   - 서버 사이드 관리자 스크립트
   - 안전한 로컬 운영 작업
4. 실제 비밀키는 Git에 커밋하지 않는다.

## 3. 로컬 파일 전략
이 저장소에서는 실제 키를 커밋하지 않고, 아래 예시 파일만 버전 관리한다.
- `config/env/dev.example.json`
- `config/env/stage.example.json`
- `config/env/prod.example.json`
- `supabase/.env.example`

실제 로컬 파일은 예를 들어 다음처럼 둔다.
- `config/env/dev.json`
- `config/env/stage.json`
- `config/env/prod.json`
- `supabase/.env`

이 파일들은 `.gitignore`에 의해 무시된다.

## 4. Flutter 앱에서의 사용 원칙
### 클라이언트에서 사용 가능
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_PROJECT_REF`

### 클라이언트에서 사용 금지
- `SUPABASE_SERVICE_ROLE_KEY`

## 5. Edge Functions / 운영에서의 사용 원칙
### 서버 사이드에서만 사용
- `SUPABASE_SERVICE_ROLE_KEY`

사용 예:
- 관리자성 데이터 수정
- 커뮤니티 모더레이션 자동화
- 푸시 알림 발송 트리거
- 백분위 계산 배치/보정 작업(후속 검토)

## 6. migration 적용 준비 상태
현재 이 저장소에는 **SQL 초안은 준비되었지만, 아직 실제 DB에 적용되지는 않았다.**

### 적용 전 체크리스트
- [ ] Supabase CLI 설치
- [ ] 프로젝트 로그인 또는 access token 준비
- [ ] project ref 연결
- [ ] migration SQL 재검토
- [ ] dev 환경에서 먼저 적용

## 7. 당신이 해야 하는 것
현재 시점에서 명확하게 필요한 작업은 아래입니다.

### 지금 바로 필요
1. **Supabase CLI 설치**
2. **실제 로컬 비밀키 파일 생성**
   - `config/env/dev.json`
   - `supabase/.env`
3. **service role key는 로컬에만 저장**

### 이후 제가 이어서 할 수 있는 것
당신이 CLI 준비를 마치면, 다음을 이어서 진행할 수 있다.
1. migration 파일 분리/정리
2. Flutter Supabase bootstrap 코드 작성
3. Edge Functions 디렉토리 구조 설계
4. auth/profile/household 초기 repository/service 구조 작성

## 8. 추후 다시 물어볼 항목
지금은 보류하되, **auth 구현을 시작하는 시점**에 다시 꼭 확인할 항목:
- Kakao/Naver/Google의 실제 Client ID / Secret / Redirect URI

## 9. 관련 문서
- `docs/architecture/auth-provider-strategy.md`
- `docs/architecture/erd.md`
- `docs/architecture/event-schema.md`
- `supabase/migrations/20260403153000_init_core_schema.sql`
