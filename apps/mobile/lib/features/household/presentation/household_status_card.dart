import 'package:flutter/material.dart';

import '../../../bootstrap.dart';
import '../data/household_repository.dart';
import '../domain/household_summary.dart';

class HouseholdStatusCard extends StatefulWidget {
  const HouseholdStatusCard({super.key, required this.bootstrapState});

  final BootstrapState bootstrapState;

  @override
  State<HouseholdStatusCard> createState() => _HouseholdStatusCardState();
}

class _HouseholdStatusCardState extends State<HouseholdStatusCard> {
  HouseholdRepository? _repository;
  List<HouseholdSummary> _households = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.bootstrapState.supabaseInitialized) {
      _repository = HouseholdRepository();
      _loadHouseholds();
    }
  }

  Future<void> _loadHouseholds() async {
    final repository = _repository;
    if (repository == null) return;

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final households = await repository.fetchMyHouseholds();
      if (!mounted) return;
      setState(() {
        _households = households;
        _message = households.isEmpty ? '참여 중인 household가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = 'household 조회 실패: $error';
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
    final canUseHousehold = widget.bootstrapState.supabaseInitialized;
    final primaryHousehold = _households.isEmpty ? null : _households.first;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Household 상태', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _HouseholdRow(label: 'household 수', value: '${_households.length}'),
            _HouseholdRow(
              label: '기본 household',
              value: primaryHousehold?.name ?? '없음',
            ),
            _HouseholdRow(label: '역할', value: primaryHousehold?.role ?? '없음'),
            _HouseholdRow(label: '상태', value: primaryHousehold?.status ?? '없음'),
            _HouseholdRow(
              label: '성장 기준',
              value: primaryHousehold?.growthChartStandard ?? '없음',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: canUseHousehold && !_isLoading
                      ? _loadHouseholds
                      : null,
                  child: Text(_isLoading ? '조회 중...' : 'household 다시 조회'),
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
            if (!canUseHousehold) ...[
              const SizedBox(height: 12),
              Text(
                'Supabase 초기화 후 household 조회를 사용할 수 있습니다.',
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

class _HouseholdRow extends StatelessWidget {
  const _HouseholdRow({required this.label, required this.value});

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
