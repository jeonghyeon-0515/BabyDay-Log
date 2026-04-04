import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../activity/domain/activity_event_type.dart';
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
      _isLoading = true;
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
      final summary = await repository.fetchSummary(
        babyId: widget.selectedBaby?.id,
      );
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _message = summary.hasData ? null : '기록이 아직 충분하지 않아 분석 요약이 비어 있습니다.';
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
    final recent7dEntries =
        summary?.recent7dTypeCounts.entries.toList() ??
        const <MapEntry<String, int>>[];
    final sortedRecent7dEntries = List<MapEntry<String, int>>.from(
      recent7dEntries,
    )..sort((a, b) => b.value.compareTo(a.value));

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
              summary?.dataInsight ??
                  '최근 기록을 모아 24시간/7일 요약과 수유·수면·기저귀 패턴을 보여줍니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            BabyContextHeader(
              selectedBaby: widget.selectedBaby,
              availableBabies: widget.availableBabies,
              onSelectBaby: widget.onSelectBaby,
            ),
            const SizedBox(height: 12),
            if (summary != null && !summary.hasEnoughRecentData)
              _WarningCard(
                message: summary.dataInsight,
                icon: Icons.info_outline,
              ),
            if (_isLoading && summary == null) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (summary != null && summary.hasData)
              ..._buildAnalyticsContent(summary, sortedRecent7dEntries)
            else if (summary != null) ...[
              const SizedBox(height: 16),
              _EmptyAnalyticsCard(
                message:
                    '기록이 아직 충분하지 않습니다.\n수유·수면·기저귀 기록이 쌓이면 24시간/7일 비교와 패턴 분석이 자동으로 채워집니다.',
              ),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseAnalytics && !_isLoading
                      ? _loadSummary
                      : null,
                  child: Text(_isLoading ? '조회 중...' : '분석 새로고침'),
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

  List<Widget> _buildAnalyticsContent(
    ActivityAnalyticsSummary summary,
    List<MapEntry<String, int>> sortedRecent7dEntries,
  ) {
    return [
      const SizedBox(height: 12),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricCard(
            label: '최근 24시간',
            value: '${summary.recent24hCount}건',
            helper: '오늘 들어온 기록',
          ),
          _MetricCard(
            label: '최근 7일',
            value: '${summary.recent7dCount}건',
            helper: '분석 기준 기록 수',
          ),
          _MetricCard(
            label: '이벤트 종류',
            value: '${summary.distinctTypes}개',
            helper: '수유/수면/기저귀 등',
          ),
          _MetricCard(
            label: '최신 기록',
            value: summary.latestRecordedAt ?? '없음',
            helper: summary.latestEventType == null
                ? '아직 기록이 없습니다'
                : activityEventTypeLabel(summary.latestEventType!),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: '최근 7일 주요 분포',
        subtitle: '무엇이 얼마나 자주 기록되었는지 빠르게 확인합니다.',
        child: sortedRecent7dEntries.isEmpty
            ? const Text('표시할 분포가 없습니다.')
            : Column(
                children: sortedRecent7dEntries
                    .take(5)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(activityEventTypeLabel(entry.key)),
                            ),
                            Text('${entry.value}건'),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
      ),
      const SizedBox(height: 16),
      _InsightSection(
        title: '수유 패턴',
        icon: Icons.local_drink_outlined,
        text: summary.feedingInsight,
      ),
      const SizedBox(height: 12),
      _InsightSection(
        title: '수면 패턴',
        icon: Icons.bedtime_outlined,
        text: summary.sleepInsight,
      ),
      const SizedBox(height: 12),
      _InsightSection(
        title: '기저귀 패턴',
        icon: Icons.baby_changing_station_outlined,
        text: summary.diaperInsight,
      ),
      const SizedBox(height: 16),
    ];
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final String value;
  final String helper;

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
              const SizedBox(height: 8),
              Text(helper, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.icon,
    required this.text,
  });

  final String title;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalyticsCard extends StatelessWidget {
  const _EmptyAnalyticsCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('분석 데이터가 아직 적어요', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
