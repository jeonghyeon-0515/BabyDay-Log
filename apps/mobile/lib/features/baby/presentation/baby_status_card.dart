import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../data/baby_repository.dart';
import '../domain/baby_summary.dart';
import 'baby_list_page.dart';

class BabyStatusCard extends StatefulWidget {
  const BabyStatusCard({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<BabyStatusCard> createState() => _BabyStatusCardState();
}

class _BabyStatusCardState extends State<BabyStatusCard> {
  BabyRepository? _repository;
  List<BabySummary> _babies = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = BabyRepository();
      _loadBabies();
    }
  }

  Future<void> _loadBabies() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final babies = await repository.fetchMyBabies();
      if (!mounted) return;
      setState(() {
        _babies = babies;
        _message = babies.isEmpty ? '등록된 아기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '아기 조회 실패: $error';
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
    final canUseBabies = widget.bootstrapState.supabaseInitialized;
    final primaryBaby = _babies.isEmpty ? null : _babies.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('아기 상태', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _BabyRow(label: '아기 수', value: '${_babies.length}'),
            _BabyRow(label: '기본 아기', value: primaryBaby?.name ?? '없음'),
            _BabyRow(label: '생년월일', value: primaryBaby?.birthDate ?? '없음'),
            _BabyRow(label: '성별', value: primaryBaby?.sex ?? '없음'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseBabies && !_isLoading ? _loadBabies : null,
                  child: Text(_isLoading ? '조회 중...' : '아기 다시 조회'),
                ),
                OutlinedButton(
                  onPressed: canUseBabies && _repository != null
                      ? () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                BabyListPage(repository: _repository!),
                          ),
                        )
                      : null,
                  child: const Text('상세 보기'),
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
            if (!canUseBabies) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 아기 조회를 사용할 수 있습니다.',
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

class _BabyRow extends StatelessWidget {
  const _BabyRow({required this.label, required this.value});

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
