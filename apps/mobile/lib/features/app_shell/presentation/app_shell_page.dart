import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../analytics/presentation/analytics_page.dart';
import '../../diary/presentation/diary_page.dart';
import '../../home/presentation/home_screen.dart';
import '../../more/presentation/more_page.dart';
import '../../records/presentation/records_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(bootstrapState: widget.bootstrapState),
      RecordsPage(bootstrapState: widget.bootstrapState),
      AnalyticsPage(bootstrapState: widget.bootstrapState),
      const DiaryPage(),
      MorePage(bootstrapState: widget.bootstrapState),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '홈'),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            label: '분석',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: '일기',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: '더보기'),
        ],
      ),
    );
  }
}
