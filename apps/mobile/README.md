# BabyDay Log Mobile

Flutter + Supabase bootstrap 앱입니다.

## 실행 예시
루트 예시 환경 파일을 활용하는 권장 방식:

```bash
cd apps/mobile
flutter run --dart-define-from-file=../../config/env/dev.json
```

직접 값을 넘기는 방식:

```bash
cd apps/mobile
flutter run \
  --dart-define=APP_ENV=dev \
  --dart-define=SUPABASE_URL=https://nnzwtoohzwubpigijjvj.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=SUPABASE_PROJECT_REF=nnzwtoohzwubpigijjvj
```

## 현재 범위
- Flutter 앱 bootstrap
- Supabase 초기화
- 기본 환경 표시 화면

## 다음 예정
- auth/profile/household 구조
- baby/activity repository
- Kakao > Naver > Google 로그인
