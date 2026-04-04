import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../analytics/presentation/analytics_page.dart';
import '../../baby/data/baby_repository.dart';
import '../../baby/domain/baby_summary.dart';
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
  BabyRepository? _babyRepository;
  List<BabySummary> _availableBabies = const [];
  String? _selectedBabyId;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _babyRepository = BabyRepository();
      _loadBabyContext();
    }
  }

  Future<void> _loadBabyContext() async {
    final babyRepository = _babyRepository;
    if (babyRepository == null) return;

    final babies = await babyRepository.fetchMyBabies();
    if (!mounted) return;

    setState(() {
      _availableBabies = babies;
      if (babies.isEmpty) {
        _selectedBabyId = null;
      } else if (_selectedBabyId == null ||
          babies.every((baby) => baby.id != _selectedBabyId)) {
        _selectedBabyId = babies.first.id;
      }
    });
  }

  void _selectBaby(String babyId) {
    setState(() {
      _selectedBabyId = babyId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedBaby = _availableBabies
        .where((baby) => baby.id == _selectedBabyId)
        .cast<BabySummary?>()
        .firstOrNull;
    final pages = <Widget>[
      HomeScreen(
        bootstrapState: widget.bootstrapState,
        selectedBaby: selectedBaby,
        availableBabies: _availableBabies,
        onSelectBaby: _selectBaby,
      ),
      RecordsPage(
        bootstrapState: widget.bootstrapState,
        selectedBaby: selectedBaby,
        availableBabies: _availableBabies,
        onSelectBaby: _selectBaby,
      ),
      AnalyticsPage(
        bootstrapState: widget.bootstrapState,
        selectedBaby: selectedBaby,
        availableBabies: _availableBabies,
        onSelectBaby: _selectBaby,
      ),
      DiaryPage(
        bootstrapState: widget.bootstrapState,
        selectedBaby: selectedBaby,
        availableBabies: _availableBabies,
        onSelectBaby: _selectBaby,
      ),
      MorePage(
        bootstrapState: widget.bootstrapState,
        selectedBaby: selectedBaby,
        availableBabies: _availableBabies,
        onSelectBaby: _selectBaby,
      ),
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
