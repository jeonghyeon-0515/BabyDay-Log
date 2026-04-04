import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_context_header.dart';
import '../data/analytics_repository.dart';
import '../domain/activity_analytics_summary.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
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
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsRepository? _repository;
  ActivityAnalyticsSummary? _summary;
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = AnalyticsRepository();
      _loadSummary();
    }
  }

  @override
  void didUpdateWidget(covariant AnalyticsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBaby?.id != widget.selectedBaby?.id) {
      _loadSummary();
    }
  }

  Future<void> _loadSummary() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final summary = await repository.fetchSummary(babyId: widget.selectedBaby?.id);
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _message = summary.totalEvents == 0
            ? '분석할 activity event가 아직 없습니다.'
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '분석 데이터 조회 실패: $error';
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
    final canUseAnalytics = widget.bootstrapState.supabaseInitialized;
    final summary = _summary;
    final topTypeEntries =
        summary == null
              ? <MapEntry<String, int>>[]
              : List<MapEntry<String, int>>.from(summary.typeCounts.entries)
          ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('분석')),
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('분석 요약', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '최근 activity 기록을 기준으로 오늘 분석의 첫 단계를 보여줍니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
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
                _MetricCard(
                  label: '최근 이벤트 수',
                  value: '${summary?.totalEvents ?? 0}',
                ),
                _MetricCard(
                  label: '이벤트 종류 수',
                  value: '${summary?.distinctTypes ?? 0}',
                ),
                _MetricCard(
                  label: '최신 타입',
                  value: summary?.latestEventType ?? '없음',
                ),
                _MetricCard(
                  label: '최신 기록 시각',
                  value: summary?.latestRecordedAt ?? '없음',
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: canUseAnalytics && !_isLoading ? _loadSummary : null,
              child: Text(_isLoading ? '조회 중...' : '분석 새로고침'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('주요 이벤트 분포', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (topTypeEntries.isEmpty)
                      const Text('표시할 이벤트 분포가 없습니다.')
                    else
                      ...topTypeEntries
                          .take(5)
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(entry.key)),
                                  Text('${entry.value}건'),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
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
            if (!canUseAnalytics) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 분석 탭을 사용할 수 있습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
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
