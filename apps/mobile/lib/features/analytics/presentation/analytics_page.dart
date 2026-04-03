import 'package:flutter/material.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('분석')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '패턴 / 인터벌 / 통계 화면은 다음 단계에서 연결합니다.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
