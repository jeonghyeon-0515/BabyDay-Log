import 'package:babyday_log/app/app.dart';
import 'package:babyday_log/bootstrap.dart';
import 'package:babyday_log/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bootstrap home renders environment and status', (tester) async {
    const config = AppConfig(
      environment: 'test',
      supabaseUrl: '',
      supabaseAnonKey: '',
      projectRef: 'example',
    );

    const state = BootstrapState(config: config, supabaseInitialized: false);

    await tester.pumpWidget(const BabyDayLogApp(bootstrapState: state));

    expect(find.text('BabyDay Log'), findsOneWidget);
    expect(find.text('Flutter + Supabase Bootstrap'), findsOneWidget);
    expect(find.text('dart-define 값 대기'), findsOneWidget);
    expect(find.text('example'), findsOneWidget);
  });
}
