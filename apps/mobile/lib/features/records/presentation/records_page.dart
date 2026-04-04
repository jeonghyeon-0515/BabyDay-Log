import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/domain/activity_event_summary.dart';
import '../../activity/presentation/activity_create_page.dart';
import '../../activity/presentation/activity_list_page.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_context_header.dart';

class RecordsPage extends StatefulWidget {
  const RecordsPage({
    super.key,
    required this.bootstrapState,
    required this.selectedBaby,
    required this.availableBabies,
    required this.onSelectBaby,
  });

  final BootstrapState bootstrapState;
  final BabySummary? selectedBaby;
  final List<BabySummary> availableBabies;
  final ValueChanged<String> onSelectBaby;

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  ActivityRepository? _repository;
  List<ActivityEventSummary> _events = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = ActivityRepository();
      _loadEvents();
    }
  }

  @override
  void didUpdateWidget(covariant RecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBaby?.id != widget.selectedBaby?.id) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final events = await repository.fetchRecentActivityEvents(
        limit: 20,
        babyId: widget.selectedBaby?.id,
      );
      if (!mounted) return;
      setState(() {
        _events = events;
        _message = events.isEmpty ? '아직 기록이 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '기록을 불러오지 못했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseRecords = widget.bootstrapState.supabaseInitialized;
    final repository = _repository;
    final todayEventCount = _countTodayEvents();
    final latestFeeding = _latestEventWhere((event) => event.isFeeding);
    final latestSleep = _latestEventWhere((event) => event.isSleep);
    final latestDiaper = _latestEventWhere((event) => event.isDiaper);

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('기록', style: theme.textTheme.headlineSmall),
                ),
                FilledButton(
                  onPressed: canUseRecords && repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ActivityCreatePage(repository: repository),
                          ),
                        )
                      : null,
                  child: const Text('기록 추가'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BabyContextHeader(
              selectedBaby: widget.selectedBaby,
              availableBabies: widget.availableBabies,
              onSelectBaby: widget.onSelectBaby,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _RecordsMetricCard(
                  label: '오늘 기록 수',
                  value: '$todayEventCount건',
                ),
                _RecordsMetricCard(
                  label: '최근 수유',
                  value: _summaryCardValue(latestFeeding),
                ),
                _RecordsMetricCard(
                  label: '최근 수면',
                  value: _summaryCardValue(latestSleep),
                ),
                _RecordsMetricCard(
                  label: '최근 기저귀',
                  value: _summaryCardValue(latestDiaper),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseRecords && !_isLoading ? _loadEvents : null,
                  child: Text(_isLoading ? '불러오는 중...' : '새로고침'),
                ),
                OutlinedButton(
                  onPressed: canUseRecords && repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ActivityListPage(repository: repository),
                          ),
                        )
                      : null,
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (!canUseRecords) ...[
              const SizedBox(height: 12),
              Text(
                '지금은 기록을 불러올 수 없어요.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (final event in _events) ...[
              Card(
                child: ListTile(
                  title: Text(event.eventTypeLabel),
                  isThreeLine: true,
                  subtitle: Text(_eventSubtitle(event)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _eventSubtitle(ActivityEventSummary event) {
    final buffer = StringBuffer()
      ..write('${event.displayDetailSummary}\n')
      ..write(event.recordedAt);

    if (event.note != null && event.note!.trim().isNotEmpty) {
      buffer.write('\n메모: ${event.note}');
    }
    return buffer.toString();
  }

  int _countTodayEvents() {
    final now = DateTime.now().toLocal();
    return _events
        .where((event) => _isSameLocalDay(event.recordedAtDateTime, now))
        .length;
  }

  ActivityEventSummary? _latestEventWhere(
    bool Function(ActivityEventSummary) test,
  ) {
    for (final event in _events) {
      if (test(event)) {
        return event;
      }
    }
    return null;
  }

  bool _isSameLocalDay(DateTime? eventTime, DateTime now) {
    if (eventTime == null) return false;
    return eventTime.year == now.year &&
        eventTime.month == now.month &&
        eventTime.day == now.day;
  }

  String _summaryCardValue(ActivityEventSummary? event) {
    if (event == null) {
      return '없음';
    }

    final recordedAt = event.recordedAtDateTime;
    final recordedText = recordedAt == null
        ? '시각 없음'
        : '${recordedAt.month}/${recordedAt.day} ${recordedAt.hour.toString().padLeft(2, '0')}:${recordedAt.minute.toString().padLeft(2, '0')}';

    return '${event.displayDetailSummary}\n$recordedText';
  }
}

class _RecordsMetricCard extends StatelessWidget {
  const _RecordsMetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 165,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
