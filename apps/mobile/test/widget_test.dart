import 'package:babyday_log/app/app.dart';
import 'package:babyday_log/bootstrap.dart';
import 'package:babyday_log/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home tab renders dashboard shell', (tester) async {
    const config = AppConfig(
      environment: 'test',
      supabaseUrl: '',
      supabaseAnonKey: '',
      projectRef: 'example',
    );

    const state = BootstrapState(config: config, supabaseInitialized: false);

    await tester.pumpWidget(const BabyDayLogApp(bootstrapState: state));

    expect(find.text('홈'), findsWidgets);
    expect(find.text('오늘 홈'), findsOneWidget);
    expect(find.text('현재 아기'), findsWidgets);
    expect(find.text('Household 요약'), findsOneWidget);
  });
}
