import 'package:flutter/material.dart';

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('일기')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '비공개/공개 성장일기 화면은 다음 단계에서 연결합니다.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
