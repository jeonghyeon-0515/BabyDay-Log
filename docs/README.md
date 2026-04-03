# BabyDay-Log 문서 인덱스

이 디렉토리는 BabyTime 벤치마크 기반의 제품/기술/실행 계획 문서를 모아둔 공간입니다.

## 문서 목록

### 리서치
- `docs/research/babytime-feature-benchmark.md`
  - BabyTime 공식 기능 분석
  - 기능 동등성 범위 정의
  - 우선순위 분류(P0/P1/P2)
- `docs/research/korean-growth-standard.md`
  - 한국 성장 백분위 기준 검토
  - 기본 기준값 `kr_2017` 결정

### 제품 계획
- `docs/plan/overall-product-plan.md`
  - 전체 제품 목표
  - 단계별 개발 로드맵
  - 팀 구성 제안
  - 릴리즈 전략
- `docs/plan/information-architecture.md`
  - 앱 정보 구조(IA)
  - 탭 구조
  - 화면 목록
  - 화면 간 관계
- `docs/plan/user-flows.md`
  - 핵심 사용자 여정별 상세 플로우
  - 정상 흐름 / 예외 흐름 / 상태 전환

### 아키텍처
- `docs/architecture/supabase-architecture.md`
  - Flutter + Supabase 기반 구조 설계
  - 도메인 모델 초안
  - Realtime / Storage / RLS / Edge Functions 역할 정의
- `docs/architecture/supabase-project-setup.md`
  - 현재 Supabase 프로젝트 적용 가이드
  - 비밀키 관리 원칙과 로컬 준비 항목
- `docs/architecture/auth-provider-strategy.md`
  - 카카오 / 네이버 / 구글 로그인 우선순위 및 구현 전략
- `docs/architecture/erd.md`
  - household / baby / activity / diary 중심 ERD 상세 정의
  - 핵심 테이블, 관계, enum/lookup 전략
- `docs/architecture/event-schema.md`
  - activity_events 및 세부 이벤트 타입 스키마 정의
  - 타임라인/집계/동기화 관점 설계
- `docs/architecture/backend-server-decision.md`
  - 별도 백엔드 서버 필요성 검토
  - 추천 방향 및 재검토 조건

## 보조 계획 산출물
- `.omx/plans/prd-babytime-clone-20260403.md`
- `.omx/plans/test-spec-babytime-clone-20260403.md`

위 2개는 에이전트 계획 워크플로 산출물이고, `docs/`는 팀 협업용 정리 문서입니다.

## 실행용 SQL 초안
- `supabase/migrations/20260403153000_init_core_schema.sql`
  - Supabase 초기 스키마 / RLS / 기본 seed SQL 초안
