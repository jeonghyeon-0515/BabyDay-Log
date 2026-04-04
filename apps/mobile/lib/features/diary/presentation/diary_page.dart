import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry_summary.dart';
import 'diary_create_page.dart';
import 'diary_list_page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DiaryRepository? _repository;
  List<DiaryEntrySummary> _entries = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = DiaryRepository();
      _loadEntries();
    }
  }

  Future<void> _loadEntries() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final entries = await repository.fetchRecentDiaries(limit: 20);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _message = entries.isEmpty ? '작성된 일기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '일기 탭 조회 실패: $error';
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
    final canUseDiary = widget.bootstrapState.supabaseInitialized;
    final latest = _entries.isEmpty ? null : _entries.first;
    final publicCount = _entries
        .where((entry) => entry.visibility == 'public')
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('일기')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('일기 요약', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              '비공개/공개 성장일기의 첫 단계를 연결했습니다.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DiaryMetricCard(label: '일기 수', value: '${_entries.length}'),
                _DiaryMetricCard(label: '공개 일기 수', value: '$publicCount'),
                _DiaryMetricCard(
                  label: '최신 제목',
                  value: latest?.title ?? '(제목 없음)',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseDiary && !_isLoading ? _loadEntries : null,
                  child: Text(_isLoading ? '조회 중...' : '일기 새로고침'),
                ),
                OutlinedButton(
                  onPressed: canUseDiary && _repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DiaryCreatePage(repository: _repository!),
                          ),
                        )
                      : null,
                  child: const Text('일기 작성'),
                ),
                OutlinedButton(
                  onPressed: canUseDiary && _repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                DiaryListPage(repository: _repository!),
                          ),
                        )
                      : null,
                  child: const Text('전체 보기'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in _entries.take(5)) ...[
              Card(
                child: ListTile(
                  title: Text(
                    entry.title?.isNotEmpty == true ? entry.title! : '(제목 없음)',
                  ),
                  subtitle: Text(
                    'visibility: ${entry.visibility}\n'
                    'eventDate: ${entry.eventDate ?? '없음'}\n'
                    '${entry.body}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
            if (!canUseDiary) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 일기 탭을 사용할 수 있습니다.',
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

class _DiaryMetricCard extends StatelessWidget {
  const _DiaryMetricCard({required this.label, required this.value});

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
