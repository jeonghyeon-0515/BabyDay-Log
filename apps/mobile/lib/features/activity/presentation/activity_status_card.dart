import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../data/activity_repository.dart';
import '../domain/activity_event_summary.dart';

class ActivityStatusCard extends StatefulWidget {
  const ActivityStatusCard({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<ActivityStatusCard> createState() => _ActivityStatusCardState();
}

class _ActivityStatusCardState extends State<ActivityStatusCard> {
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

  Future<void> _loadEvents() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final events = await repository.fetchRecentActivityEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _message = events.isEmpty ? '최근 activity event가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'activity 조회 실패: $error';
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
    final canUseActivity = widget.bootstrapState.supabaseInitialized;
    final latestEvent = _events.isEmpty ? null : _events.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity 상태', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _ActivityRow(label: '최근 이벤트 수', value: '${_events.length}'),
            _ActivityRow(
              label: '최신 타입',
              value: latestEvent?.eventTypeSlug ?? '없음',
            ),
            _ActivityRow(label: '최신 상태', value: latestEvent?.status ?? '없음'),
            _ActivityRow(
              label: '기록 시각',
              value: latestEvent?.recordedAt ?? '없음',
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: canUseActivity && !_isLoading ? _loadEvents : null,
              child: Text(_isLoading ? '조회 중...' : 'activity 다시 조회'),
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
            if (!canUseActivity) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 activity 조회를 사용할 수 있습니다.',
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

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}
