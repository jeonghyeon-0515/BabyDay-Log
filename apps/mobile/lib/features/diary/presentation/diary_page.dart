import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../../baby/domain/baby_summary.dart';
import '../../baby/presentation/baby_context_header.dart';
import '../data/diary_repository.dart';
import '../domain/diary_entry_summary.dart';
import 'diary_create_page.dart';
import 'diary_detail_page.dart';
import 'diary_entry_card.dart';
import 'diary_list_page.dart';
import 'public_diary_feed_page.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({
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
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DiaryRepository? _repository;
  List<DiaryEntrySummary> _entries = const [];
  List<DiaryEntrySummary> _publicEntries = const [];
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

  @override
  void didUpdateWidget(covariant DiaryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedBaby?.id != widget.selectedBaby?.id) {
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
      final results = await Future.wait<List<DiaryEntrySummary>>([
        repository.fetchRecentDiaries(
          limit: 20,
          babyId: widget.selectedBaby?.id,
        ),
        repository.fetchPublicDiaries(
          limit: 20,
          babyId: widget.selectedBaby?.id,
        ),
      ]);
      final entries = results[0];
      final publicEntries = results[1];
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _publicEntries = publicEntries;
        _message = entries.isEmpty ? '아직 일기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '일기를 불러오지 못했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openDetail(DiaryEntrySummary entry) async {
    final repository = _repository;
    if (repository == null) return;

    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => DiaryDetailPage(repository: repository, entry: entry),
      ),
    );

    if (refreshed == true && mounted) {
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canUseDiary = widget.bootstrapState.supabaseInitialized;
    final latest = _entries.isEmpty ? null : _entries.first;
    final latestPublic = _publicEntries.isEmpty ? null : _publicEntries.first;
    final currentUserId = _repository?.currentUser?.id;
    final publicCount = _publicEntries.length;

    return Scaffold(
      appBar: AppBar(title: const Text('일기')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('일기', style: theme.textTheme.headlineSmall),
                ),
                FilledButton(
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
              ],
            ),
            const SizedBox(height: 12),
            BabyContextHeader(
              selectedBaby: widget.selectedBaby,
              availableBabies: widget.availableBabies,
              onSelectBaby: widget.onSelectBaby,
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: '내 일기',
              subtitle: '작성한 일기와 최근 흐름을 확인합니다.',
              trailingLabel: '${_entries.length}개',
              child: _entries.isEmpty
                  ? const _EmptySectionText('작성된 일기가 없습니다.')
                  : Column(
                      children: [
                        DiaryEntryCard(
                          entry: latest ?? _entries.first,
                          currentUserId: currentUserId,
                          onTap: () => _openDetail(latest ?? _entries.first),
                        ),
                        if (_entries.length > 1) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '최근 작성된 일기',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final entry in _entries.skip(1).take(3)) ...[
                            DiaryEntryCard(
                              entry: entry,
                              currentUserId: currentUserId,
                              onTap: () => _openDetail(entry),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
                    ),
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
                  value: latest?.titleDisplay ?? '(제목 없음)',
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
                  child: Text(_isLoading ? '불러오는 중...' : '새로고침'),
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
                OutlinedButton(
                  onPressed: canUseDiary && _repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PublicDiaryFeedPage(repository: _repository!),
                          ),
                        )
                      : null,
                  child: const Text('공개 피드'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: '공개 피드',
              subtitle: '가족 밖으로 공유된 일기와 흐름을 확인합니다.',
              trailingLabel: '$publicCount개',
              child: Column(
                children: [
                  if (latestPublic == null)
                    const _EmptySectionText('표시할 공개 일기가 없습니다.')
                  else ...[
                    DiaryEntryCard(
                      entry: latestPublic,
                      currentUserId: currentUserId,
                      onTap: () => _openDetail(latestPublic),
                      highlight: true,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '최근 공개 일기',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final entry in _publicEntries.skip(1).take(3)) ...[
                      DiaryEntryCard(
                        entry: entry,
                        currentUserId: currentUserId,
                        onTap: () => _openDetail(entry),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
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
                '지금은 일기를 불러올 수 없어요.',
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.trailingLabel,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String trailingLabel;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Chip(
                  label: Text(trailingLabel),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptySectionText extends StatelessWidget {
  const _EmptySectionText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(message)),
    );
  }
}
