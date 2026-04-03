# 이벤트 스키마 상세 설계

작성일: 2026-04-03  
상태: Draft v1
전제: 본 문서는 `docs/architecture/erd.md`의 `activity_events` 도메인을 상세화한다.

## 1. 목표
이벤트 스키마는 아래 요구를 만족해야 한다.

1. BabyTime 수준의 여러 활동 타입을 한 타임라인에 섞어 보여줄 수 있어야 한다.
2. 통계/인터벌/패턴 계산이 쉬워야 한다.
3. 공동양육 환경에서 실시간 동기화가 쉬워야 한다.
4. 미래 활동 타입 추가 비용이 과도하게 커지면 안 된다.
5. Supabase/Postgres 구조에 맞게 무결성과 확장성을 같이 가져가야 한다.

## 2. 공식 문서에서 가져온 설계 제약

### 2.1 JSONB 사용 원칙
Supabase 공식 문서상 JSONB는 가변 구조에 적합하지만 과도하게 사용하면 관계형 DB의 장점이 약해진다.

**따라서 원칙:**
- 집계, 필터, 권한, 인덱싱에 중요한 필드는 정규 컬럼으로 둔다.
- 타입별 잔여 세부값만 JSONB에 둔다.

### 2.2 enum 사용 원칙
Supabase 공식 문서상 enum은 작은 고정 집합에 적합하고, 잦은 변화가 있는 값에는 불리하다.

**따라서 원칙:**
- `membership_role`, `event_status` 같은 안정적 값은 enum 사용
- `event_type` 같이 앞으로 늘어날 값은 lookup table 사용

## 3. 이벤트 모델 3안 검토

### 안 1. 활동 타입별 개별 테이블
예:
- `breastfeeding_events`
- `sleep_events`
- `diaper_events`

#### 장점
- 타입별 무결성이 강하다.
- 컬럼이 명확하다.

#### 단점
- 공통 타임라인 구현이 번거롭다.
- Realtime/검색/집계가 복잡해진다.
- 활동이 늘수록 코드와 SQL이 분산된다.

### 안 2. 단일 이벤트 테이블 + 대형 JSONB payload
예:
- `activity_events(payload jsonb)`만 사용

#### 장점
- 추가가 빠르다.
- 타임라인 구조는 단순하다.

#### 단점
- 무결성이 약하다.
- 집계/조건 필터가 어려워진다.
- 잘못 쓰면 사실상 문서 DB처럼 변한다.

### 안 3. 공통 이벤트 테이블 + 타입별 세부 테이블 + 제한적 JSONB
#### 장점
- 타임라인과 분석 기준을 하나로 통합할 수 있다.
- 타입별 구조를 유지할 수 있다.
- JSONB를 최소 범위로만 써서 유연성도 확보한다.

#### 단점
- 초기 설계가 조금 더 필요하다.

## 4. 최종 선택
**선택: 안 3. 공통 이벤트 테이블 + 타입별 세부 테이블 + 제한적 JSONB**

### 선택 이유
이 방식이 아래 균형을 가장 잘 맞춘다.
- 타임라인 단순성
- 분석 가능성
- 데이터 무결성
- 향후 확장성

## 5. 이벤트 스키마 핵심 원칙
1. **모든 육아 로그는 우선 `activity_events` 한 줄을 가진다.**
2. 이벤트 공통 성질은 base table에 둔다.
3. 활동별 전문 속성은 detail table로 분리한다.
4. 남는 필드만 JSONB를 사용한다.
5. 이벤트 상태는 `draft`, `running`, `completed`, `cancelled`만 허용한다.
6. 모든 시간은 UTC `timestamptz` 기준 저장한다.
7. 사용자가 본 “기록 기준 시각”과 실제 시작/종료 시각을 분리한다.
8. 모바일 재시도 대비 `client_uid`로 idempotency를 지원한다.
9. 수정/삭제는 soft delete + audit log를 우선한다.

## 6. Base 이벤트 구조

## 6.1 `activity_events`

| 컬럼 | 타입 | 필수 | 설명 |
|---|---|---|---|
| id | uuid | Y | 이벤트 PK |
| household_id | uuid | Y | household 범위 |
| baby_id | uuid | Y | 대상 아기 |
| actor_user_id | uuid | Y | 기록한 사용자 |
| event_type_slug | text | Y | 이벤트 종류 |
| status | event_status enum | Y | 상태 |
| source | event_source enum | Y | 생성 출처 |
| started_at | timestamptz | N | 시작 시각 |
| ended_at | timestamptz | N | 종료 시각 |
| recorded_at | timestamptz | Y | UI 기준 기록 시각 |
| note | text | N | 메모 |
| metadata | jsonb | N | 비핵심 추가 정보 |
| client_uid | uuid | N | 중복 방지 키 |
| deleted_at | timestamptz | N | soft delete |
| created_at | timestamptz | Y | 생성 시각 |
| updated_at | timestamptz | Y | 수정 시각 |

## 6.2 왜 `recorded_at`이 필요한가?
예:
- 부모가 타이머를 늦게 종료했지만 실제 수면 종료는 20분 전일 수 있다.
- 병원 방문을 나중에 회상해서 기록할 수 있다.

따라서:
- `started_at`, `ended_at`은 실제 사건 시각
- `recorded_at`은 사용자가 기록한 기준 시각

## 6.3 상태 전이 규칙

### `draft`
- 작성 시작 후 아직 확정 전
- 임시 저장 상태

### `running`
- 타이머형 이벤트 진행 중
- 예: 수면, 유축, 모유수유 세션

### `completed`
- 정상 완료

### `cancelled`
- 사용자가 폐기

### 삭제 처리
- hard delete보다 `deleted_at` 사용 우선
- 타임라인에서는 기본 제외
- 감사 로그와 집계 정합성에 유리

## 7. 이벤트 타입 카탈로그 설계

## 7.1 `event_types`
대표 초기 값 예시:

| slug | category | 설명 |
|---|---|---|
| breastfeeding | feeding | 모유수유 |
| bottle_feeding | feeding | 젖병/분유 |
| solid_food | feeding | 이유식 |
| sleep | sleep | 수면 |
| diaper | diaper | 기저귀 |
| pumping | pump | 유축 |
| temperature | health | 체온 |
| medication | health | 약 복용 |
| symptom | health | 증상 |
| doctor_visit | health | 병원 방문 |
| bath | care | 목욕 |
| tummy_time | care | tummy time |
| custom_care | care | 기타 육아 활동 |

## 7.2 왜 lookup table인가?
- BabyTime 유사 앱은 후속 기능에서 활동 타입이 늘 가능성이 높다.
- enum보다 운영/마이그레이션 부담이 낮다.
- 관리자/AB테스트/국가별 기능 조정도 쉽다.

## 8. 이벤트 세부 스키마

## 8.1 Feeding
대상:
- 모유수유
- 젖병 수유
- 이유식

### `feeding_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| feeding_mode | text | breast / bottle / solid |
| breast_side | text nullable | left / right / both |
| left_duration_sec | integer nullable | 좌측 시간 |
| right_duration_sec | integer nullable | 우측 시간 |
| amount_value | numeric nullable | 양 |
| amount_unit | text nullable | ml / oz / g |
| content_type | text nullable | formula / breast_milk / mixed / puree / solid |
| spit_up_level | smallint nullable | 0~3 정도 |
| metadata | jsonb nullable | 추가 세부값 |

### 입력 규칙
- 모유수유는 duration 중심, 양은 optional
- 젖병/분유는 amount 중심
- 이유식은 양 + 음식 종류 중심

## 8.2 Sleep
### `sleep_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| sleep_type | text | nap / night |
| location | text nullable | 침대/유모차 등 |
| fell_asleep_at | timestamptz nullable | 실제 수면 시작 |
| woke_up_at | timestamptz nullable | 실제 기상 시각 |
| metadata | jsonb nullable | 기타 정보 |

### 계산 규칙
- 기본 지속시간 = `ended_at - started_at`
- 실제 수면 시작/기상 시각이 있으면 보조 해석에 사용

## 8.3 Diaper
### `diaper_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| diaper_type | text | wet / dirty / mixed / dry |
| stool_color | text nullable | 색상 |
| stool_texture | text nullable | 질감 |
| rash_observed | boolean | 발진 여부 |
| metadata | jsonb nullable | 기타 정보 |

## 8.4 Pumping
### `pump_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| left_amount_ml | numeric nullable | 좌측 양 |
| right_amount_ml | numeric nullable | 우측 양 |
| left_duration_sec | integer nullable | 좌측 시간 |
| right_duration_sec | integer nullable | 우측 시간 |
| total_amount_ml | numeric nullable | 총량 캐시 |
| metadata | jsonb nullable | 추가값 |

## 8.5 Health
### `health_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| health_type | text | temperature / medication / symptom / vaccination / doctor_visit |
| temperature_c | numeric nullable | 섭씨 표준 저장 |
| medication_name | text nullable | 약 이름 |
| dosage_value | numeric nullable | 투여량 |
| dosage_unit | text nullable | ml / mg / tablet |
| symptom_summary | text nullable | 증상 요약 |
| clinic_name | text nullable | 병원명 |
| diagnosis | text nullable | 진단 내용 |
| metadata | jsonb nullable | 추가값 |

### 단위 표준화 원칙
- 체온은 DB에서 `temperature_c`로 표준 저장
- UI에서 화씨가 필요하면 변환 표시만 한다.

## 8.6 Care
### `care_event_details`
| 컬럼 | 타입 | 설명 |
|---|---|---|
| event_id | uuid PK/FK | base event |
| care_type | text | bath / tummy_time / walk / play / custom |
| duration_sec | integer nullable | 지속 시간 |
| quantity_value | numeric nullable | 부가 수치 |
| quantity_unit | text nullable | 부가 단위 |
| metadata | jsonb nullable | 추가값 |

## 9. JSONB 사용 정책

### JSONB 허용 영역
- UI 확장 필드
- 지역/기기 특화 필드
- 임시 실험 필드
- 드물게만 쓰는 보조 필드

### JSONB 금지 영역
- `baby_id`, `actor_user_id`, `event_type_slug`
- 집계 필수 수치
- 권한 판단 필드
- 자주 필터링/정렬하는 필드

### 검증 전략
Supabase 문서 기준 `pg_jsonschema`를 활용해 JSONB 형식 검증을 붙일 수 있다.
권장 사용처:
- `activity_events.metadata`
- 각 detail table의 `metadata`

단, 핵심 필드는 여전히 일반 컬럼으로 둔다.

## 10. 이벤트 생성/수정/삭제 규칙

## 10.1 생성
- 앱은 `client_uid`를 포함해 업로드
- 서버는 `client_uid` unique 제약으로 중복 방지

## 10.2 수정
- `updated_at` 갱신
- 중요한 변경은 `audit_logs` 기록
- 공동양육 환경에서는 마지막 수정자/수정 시각을 노출 가능하게 설계

## 10.3 삭제
- 기본은 soft delete
- 집계 테이블은 deleted_at 반영 로직 필요

## 11. 타임라인 표시 규칙
타임라인은 `activity_events`를 기준으로 정렬한다.

### 기본 정렬
1. `recorded_at desc`
2. 동률이면 `created_at desc`

### 진행 중 이벤트
- `status = running`인 이벤트는 홈 상단 고정 카드로 우선 노출 가능

## 12. 분석과 이벤트 스키마의 관계

### 원시 저장소
- `activity_events`
- `feeding_event_details`
- `sleep_event_details` 등

### 파생 분석 구조(후속)
- `daily_activity_summaries`
- `feeding_interval_summaries`
- `sleep_interval_summaries`
- `daily_sleep_totals`

### 원칙
- 원시 이벤트를 수정 없이 남기고
- 분석은 파생 계산으로 재생성 가능해야 한다.

## 13. 예시 레코드

## 13.1 모유수유 예시
- `activity_events`
  - event_type_slug = `breastfeeding`
  - status = `completed`
  - started_at = `2026-04-03T09:10:00Z`
  - ended_at = `2026-04-03T09:28:00Z`
- `feeding_event_details`
  - breast_side = `both`
  - left_duration_sec = 480
  - right_duration_sec = 600

## 13.2 분유 수유 예시
- `activity_events`
  - event_type_slug = `bottle_feeding`
  - recorded_at = `2026-04-03T12:00:00Z`
- `feeding_event_details`
  - amount_value = 180
  - amount_unit = `ml`
  - content_type = `formula`

## 13.3 수면 타이머 예시
- 시작 시 `activity_events.status = running`
- 종료 시 `status = completed`, `ended_at` 기록
- `sleep_event_details.sleep_type = nap`

## 14. 개선 제안 3가지
1. **feeding/health 세부 타입도 lookup table로 더 정규화할지 검토**
2. **event_revisions 테이블로 변경 이력 전용 구조를 둘지 검토**
3. **주요 detail metadata에 JSON schema 검증을 붙일지 검토**

### 이번에 반영한 개선안
위 3개 중 **3번 방향을 문서에 반영**했다.
- JSONB는 허용하되, `pg_jsonschema`를 통한 검증 가능성을 설계에 포함했다.

## 15. 결론
- 이벤트는 하나의 `activity_events` 타임라인을 기준으로 관리한다.
- 타입별 detail table로 무결성을 확보한다.
- JSONB는 보조 수단으로만 쓴다.
- `event_type`은 enum이 아니라 lookup table로 관리한다.

## 16. 관련 문서
- `docs/architecture/erd.md`
- `docs/architecture/supabase-architecture.md`
- `docs/plan/user-flows.md`

## 17. 참고 출처
- Supabase JSON / JSONB: https://supabase.com/docs/guides/database/json
- Supabase Enums: https://supabase.com/docs/guides/database/postgres/enums
- Supabase Tables and Data: https://supabase.com/docs/guides/database/tables
- Supabase User Management: https://supabase.com/docs/guides/auth/managing-user-data
