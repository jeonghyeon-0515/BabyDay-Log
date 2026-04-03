# Supabase 로컬 작업 메모

## 현재 포함 항목
- `migrations/20260403153000_init_core_schema.sql`
- `.env.example`

## 실제 적용 전에 필요한 것
1. Supabase CLI 설치
2. `supabase/.env` 생성
3. project ref 연결
4. dev 환경에서 migration 적용

## 주의
- service role key는 절대 앱 클라이언트에 넣지 않는다.
- `.env`는 커밋하지 않는다.
