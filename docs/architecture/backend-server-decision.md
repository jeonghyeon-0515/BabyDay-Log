# 별도 백엔드 서버 필요성 검토

작성일: 2026-04-03  
상태: Draft v1
전제: 제품 기본 스택은 **Flutter + Supabase**

## 1. 질문
Supabase를 사용하더라도, 별도의 백엔드 서버(NestJS/Go/Node API 서버 등)가 처음부터 필요한가?

## 2. 검토한 3가지 방식

### 방식 1. Flutter → Supabase 직접 연결만 사용
#### 구성
- 앱이 Auth / DB / Storage / Realtime에 직접 접근
- RLS로 권한 통제
- 서버는 없음

#### 장점
- 개발 속도 가장 빠름
- 운영 복잡도 낮음
- MVP와 핵심 로그 앱에 유리

#### 단점
- 비밀키가 필요한 외부 연동은 어려움
- 복잡한 도메인 로직이 앱/DB에 흩어질 위험
- 관리자/운영 API가 약함

### 방식 2. Flutter → Supabase + Edge Functions
#### 구성
- 기본 CRUD와 조회는 앱이 직접 Supabase 접근
- 비밀키/민감 로직/배치/웹훅은 Edge Functions 처리

#### 장점
- Supabase 장점 유지
- 별도 상시 서버 없이도 서버사이드 로직 가능
- BabyTime류 서비스의 초기/중기 범위에 균형이 좋음

#### 단점
- 함수 런타임/메모리/시간 제한 존재
- 장시간 배치나 복잡한 큐 작업에는 제약이 있음

### 방식 3. Flutter → 별도 백엔드 서버 + Supabase
#### 구성
- 앱은 별도 API 서버만 호출
- 서버가 Supabase를 내부 데이터/인증 저장소로 활용

#### 장점
- 로직 집중화
- 복잡한 운영 기능과 외부 연동에 강함
- 대형 서비스로 갈수록 통제력 높음

#### 단점
- 초기 개발/운영 비용 가장 큼
- 속도가 느려짐
- 지금 단계에선 과설계일 수 있음

## 3. 최종 판단
### 현재 추천
**방식 2: Flutter + Supabase + Edge Functions**

## 4. 판단 근거
이 판단은 **Supabase 공식 기능 범위와 우리 제품 요구사항을 대조한 설계 판단**이다.

### 4.1 Supabase만으로 충분한 영역
- 로그인/세션
- 아기/양육자/활동 CRUD
- 사진 업로드
- RLS 기반 권한 분리
- Realtime 기반 공동양육 동기화
- 기본 리마인더용 예약 작업

### 4.2 Edge Functions로 해결 가능한 영역
- 푸시 알림 트리거
- 과금 검증
- 서드파티 API 호출
- 공개 커뮤니티 후처리
- 관리자용 제한 기능

### 4.3 그래서 왜 별도 서버를 당장 안 두는가
1. BabyTime 동등화의 초기 핵심은 **로그/공유/분석**이다.
2. 이 범위는 Supabase + Edge Functions로 충분히 커버 가능하다.
3. 별도 서버를 먼저 두면 제품 검증보다 인프라 유지비가 먼저 커진다.

## 5. 별도 백엔드 서버가 필요해지는 시점
아래 중 3개 이상이 현실화되면 별도 서버를 재검토하는 것이 좋다.

### 조건 A. 고급 배치/워크플로 증가
예:
- 대규모 알림 스케줄링
- 복잡한 통계 ETL
- 미디어 후처리 파이프라인

### 조건 B. 커뮤니티 운영 기능이 커짐
예:
- 신고/차단/제재 자동화
- 콘텐츠 모더레이션 파이프라인
- 관리자 리뷰 도구

### 조건 C. 외부 연동이 많아짐
예:
- 병원/보험/헬스케어 API
- 결제/구독/CRM
- 이메일/메시징/마케팅 자동화

### 조건 D. 정책/감사/컴플라이언스 요구 강화
예:
- 세밀한 감사 로그
- 백오피스 승인 프로세스
- 데이터 마스킹/권한 대행

### 조건 E. 실시간 트래픽/성능 요구 상승
예:
- 커뮤니티 규모 급증
- Realtime 이벤트 종류 증가
- 분석 API의 계산 부하 증가

## 6. 현재 권장 아키텍처 분리 기준

### 앱 직접 호출
- 개인 기록 CRUD
- 개인 분석 조회
- 아기 전환
- 개인 사진 조회/업로드

### Edge Functions 호출
- 초대 코드 생성/검증 일부 민감 로직
- 과금 검증
- 푸시 발송 트리거
- 공개 일기 전환 처리
- 관리자 승인 훅

### 별도 서버로 넘길 수 있는 후보(후속)
- 커뮤니티 피드 랭킹/추천
- 대형 운영 백오피스
- 멀티 시스템 통합 오케스트레이션
- 고급 데이터 파이프라인

## 7. 개선 제안 3가지
1. **초기에는 별도 서버 없이 시작하되, 서버 분리 기준을 문서화한다.**
2. **모든 민감 로직은 앱에서 직접 처리하지 않고 Edge Functions로 보낸다.**
3. **커뮤니티와 운영 기능은 핵심 육아 로그 도메인과 서비스 경계를 분리한다.**

### 이번에 선택해 반영한 개선안
- 1번과 2번을 반영했다.
- 즉, 지금은 별도 서버 없이 시작하되, Edge Functions를 서버 경계로 사용한다.

## 8. 결론
### 현재 결정
- **별도 상시 백엔드 서버는 지금 당장 필요하지 않다.**
- **Supabase + Edge Functions로 시작하는 것이 최적**이다.

### 단서
- 이 결론은 **v1~v1.5 범위 기준**이다.
- 커뮤니티, 과금, 고급 운영 기능이 커지면 별도 서버를 재검토한다.

## 9. 참고 출처
- Supabase Docs: https://supabase.com/docs
- Supabase Flutter Quickstart: https://supabase.com/docs/guides/getting-started/quickstarts/flutter
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Realtime: https://supabase.com/docs/guides/realtime
- Supabase Broadcast/Database changes: https://supabase.com/docs/guides/realtime/subscribing-to-database-changes
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Supabase Edge Function Limits: https://supabase.com/docs/guides/functions/limits
- Supabase Scheduled Functions: https://supabase.com/docs/guides/functions/schedule-functions
