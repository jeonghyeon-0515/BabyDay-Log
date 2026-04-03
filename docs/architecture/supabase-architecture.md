# Supabase 기반 아키텍처 초안

작성일: 2026-04-03  
상태: Draft v1
전제: Flutter + Supabase를 기본 기술 스택으로 사용한다.

## 1. 아키텍처 목표
1. BabyTime 수준의 핵심 기록/공유/분석 경험을 빠르게 구현한다.
2. 아기/양육자/일기 데이터에 대해 강한 권한 제어를 제공한다.
3. 다자녀/공동양육/사진 업로드를 안정적으로 지원한다.
4. 이후 커뮤니티, 과금, 웨어러블 기능으로 확장 가능해야 한다.

## 2. Supabase 공식 기능과 우리 요구사항의 대응

### Auth
공식 문서상 Supabase는 인증/세션 관리를 제공한다.
우리 서비스에서의 역할:
- 이메일/소셜 로그인
- 세션 복구
- 공동양육 참여 사용자 식별

### Database (Postgres)
공식 문서상 Supabase는 프로젝트마다 Postgres를 제공한다.
우리 서비스에서의 역할:
- 아기/양육자/활동/일기/리마인더/초대 코드 저장
- 분석 집계의 원시 데이터 저장소

### Row Level Security (RLS)
공식 문서상 공개 스키마의 테이블은 RLS를 활성화해 세밀한 권한 제어를 적용할 수 있다.
우리 서비스에서의 역할:
- 본인 소유 아기만 조회 가능
- 공동양육자로 초대된 아기만 접근 가능
- 비공개 일기는 작성자/권한자만 접근
- 공개 일기만 커뮤니티 피드에 노출

### Storage
공식 문서상 Storage는 `storage.objects`에 대한 RLS 정책으로 업로드/조회 권한을 제어한다.
우리 서비스에서의 역할:
- 아기 프로필 사진
- 이벤트 첨부 이미지
- 성장일기 사진
- 커뮤니티 공개 이미지

### Realtime
공식 문서상 Realtime은 Broadcast / Presence / Postgres Changes를 제공하며,
문서에서는 **Broadcast가 확장성과 보안 측면에서 권장 방식**으로 안내된다.
우리 서비스에서의 역할:
- 공동양육 실시간 기록 반영
- 현재 편집/진행 상태 동기화
- 초대 수락 후 상태 반영

### Edge Functions
공식 문서상 Edge Functions는 서버 사이드 TypeScript 함수이며, 웹훅/서드파티 연동/저지연 엔드포인트에 적합하다.
또한 긴 작업은 백그라운드 워커로 옮기라고 안내한다.
우리 서비스에서의 역할:
- 비공개 시크릿이 필요한 연산
- 푸시/이메일 연동
- 외부 API 연동
- 공개 일기 후처리/모더레이션 훅
- 과금/영수증 검증

## 3. 권장 시스템 구성

```text
Flutter App
 ├─ Supabase Auth
 ├─ Supabase Postgres
 ├─ Supabase Storage
 ├─ Supabase Realtime
 └─ Supabase Edge Functions
```

### 모바일 앱에서 직접 접근 가능한 영역
- 인증
- 사용자의 own data CRUD
- RLS로 보호되는 테이블 조회/저장
- 사진 업로드(정책 허용 범위)
- Realtime 구독

### Edge Functions를 반드시 거치는 영역
- 서비스 role 권한이 필요한 처리
- 서드파티 비밀키 사용
- 과금/영수증 검증
- 관리자용 비공개 연산
- 주기 실행 작업

## 4. 도메인 모델 초안

## 4.1 핵심 테이블
- `profiles`
- `babies`
- `caregiver_memberships`
- `invite_codes`
- `activity_events`
- `activity_attachments`
- `growth_entries`
- `development_checks`
- `diary_entries`
- `community_posts`
- `reminder_rules`
- `notification_logs`
- `devices`
- `audit_logs`

## 4.2 관계 개요
- user 1:N babies (직접 소유 기준)
- baby N:M users (`caregiver_memberships`로 연결)
- baby 1:N activity_events
- baby 1:N growth_entries
- baby 1:N diary_entries
- diary_entry 0..1:1 community_post

## 4.3 이벤트 모델 전략
### 권장 방식
- 활동별 완전 개별 테이블보다 **공통 이벤트 테이블 + 타입별 세부 필드** 전략을 우선 검토한다.

### 이유
- 타임라인/통계/공동양육 실시간 반영을 하나의 모델로 다루기 쉽다.
- 다양한 활동 타입 추가 시 확장 비용이 낮다.

### 공통 컬럼 예시
- `id`
- `baby_id`
- `actor_user_id`
- `event_type`
- `started_at`
- `ended_at`
- `quantity`
- `unit`
- `payload_json`
- `memo`
- `created_at`
- `updated_at`
- `deleted_at`

## 5. RLS 정책 방향

## 5.1 babies
- 소유자 조회/수정 가능
- 멤버십이 있는 양육자는 조회 가능
- 쓰기 권한은 역할에 따라 제한

## 5.2 activity_events
- 해당 baby에 대한 편집 권한이 있는 사용자만 생성/수정 가능
- soft delete 사용 권장

## 5.3 diary_entries
- 기본은 비공개
- 본인/권한 있는 공동양육자만 접근
- 공개 전환 시 별도 커뮤니티 정책 적용

## 5.4 storage.objects
버킷 분리 권장:
- private-baby-media
- private-diary-media
- public-community-media

이유:
- 동일한 Storage라도 공개/비공개 정책을 분리하기 쉽다.

## 6. Realtime 전략

### 권장
- 핵심 동기화는 **Broadcast 우선 검토**
- 단순 CRUD 반영은 Postgres Changes로 빠르게 시작 가능
- 트래픽 증가 시 Broadcast로 전환/확장

### 적용 대상
- 새 기록 생성/수정/삭제
- 진행 중 타이머 상태 변화
- 초대 수락
- 공동양육자 상태 반영

### Presence 적용 후보
- 현재 접속 중 공동양육자 표시
- 현재 누가 기록 중인지 표시

## 7. 파일/미디어 전략
- 원본 업로드 저장
- 앱에는 썸네일 우선 표시
- 공개 이미지와 비공개 이미지를 물리적으로 분리
- 업로드 실패 시 메타데이터와 실제 파일 상태 불일치 방지 필요

## 8. 분석 전략

### 원칙
- 원시 이벤트는 수정 없이 최대한 보존
- 분석은 파생 집계로 계산

### 권장 구조
- raw: `activity_events`
- derived: 일/주/월 집계 뷰 또는 materialized view 또는 집계 테이블

### 후보 방식
1. 앱에서 즉시 계산
2. DB view/materialized view
3. Edge Functions 또는 scheduled jobs로 집계

### 추천
- 초기에는 DB view + 필요한 일부 집계 테이블
- 데이터량 증가 시 scheduled aggregation 추가

## 9. 오프라인/동기화 전략
이 부분은 Supabase 공식 문서의 직접 제공 범위라기보다 **우리 앱 설계가 필요한 영역**이다.

### 권장 정책
- 앱 로컬에 pending queue 유지
- 네트워크 복귀 시 순차 업로드
- 서버 시각 기준 정렬
- 충돌 시 최신 수정 우선 + 감사 로그 저장

## 10. 알림/스케줄링 전략
공식 문서상 Supabase는 `pg_cron` + `pg_net` + Edge Functions를 조합한 예약 실행 구성을 제공한다.

### 적용 후보
- 리마인더 계산 배치
- 미전송 알림 보정
- 공개 게시물 후처리
- 오래된 임시 데이터 정리

## 11. 관측/운영 전략
- Flutter: 크래시/네트워크/성능 로깅
- Supabase: 함수 로그, DB 에러, 인증 에러 모니터링
- 핵심 KPI:
  - 기록 저장 성공률
  - Realtime 지연
  - 이미지 업로드 실패율
  - 알림 성공률

## 12. 초기 구현 권장순서
1. Auth
2. babies / caregiver_memberships
3. activity_events
4. Realtime 반영
5. Storage 업로드
6. 분석 조회
7. reminders / notifications
8. diary / community

## 13. 이 문서의 결론
현재 기준으로는 **Flutter + Supabase만으로 v1 핵심 범위를 충분히 시작할 수 있다.**
다만 서비스가 커질수록 다음을 분리 검토해야 한다.
- 고급 모더레이션
- 대규모 배치/백그라운드 작업
- 복잡한 서드파티 연동
- 고급 관리자/운영 API

그 판단은 `docs/architecture/backend-server-decision.md`에서 상세히 다룬다.

## 14. 참고 출처
- Supabase Flutter Quickstart: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Supabase Docs 메인: https://supabase.com/docs
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Storage Access Control: https://supabase.com/docs/guides/storage/security/access-control
- Supabase Realtime: https://supabase.com/docs/guides/realtime
- Supabase Database Changes: https://supabase.com/docs/guides/realtime/subscribing-to-database-changes
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Supabase Scheduled Functions: https://supabase.com/docs/guides/functions/schedule-functions
- Supabase Edge Function Limits: https://supabase.com/docs/guides/functions/limits
