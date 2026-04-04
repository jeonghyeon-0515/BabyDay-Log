import 'package:flutter/material.dart';

import '../domain/baby_summary.dart';

class BabyContextHeader extends StatelessWidget {
  const BabyContextHeader({
    super.key,
    required this.selectedBaby,
    required this.availableBabies,
    required this.onSelectBaby,
  });

  final BabySummary? selectedBaby;
  final List<BabySummary> availableBabies;
  final ValueChanged<String> onSelectBaby;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasBaby = selectedBaby != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.primary,
              child: Text(
                hasBaby ? selectedBaby!.name.substring(0, 1) : '•',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasBaby ? selectedBaby!.name : '아기를 등록해 주세요',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasBaby
                        ? '${selectedBaby!.birthDate} · ${_sexLabel(selectedBaby!.sex)}'
                        : '등록 후 기록과 분석을 시작할 수 있어요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.tonalIcon(
              onPressed: availableBabies.isEmpty
                  ? null
                  : () => _showSelector(context),
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              label: const Text('바꾸기'),
            ),
          ],
        ),
      ),
    );
  }

  String _sexLabel(String sex) {
    switch (sex) {
      case 'male':
        return '남아';
      case 'female':
        return '여아';
      case 'other':
        return '기타';
      default:
        return '미정';
    }
  }

  Future<void> _showSelector(BuildContext context) async {
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return ListView(
          shrinkWrap: true,
          children: [
            for (final baby in availableBabies)
              ListTile(
                title: Text(baby.name),
                subtitle: Text('생년월일: ${baby.birthDate}'),
                trailing: baby.id == selectedBaby?.id
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(baby.id),
              ),
          ],
        );
      },
    );

    if (selectedId != null) {
      onSelectBaby(selectedId);
    }
  }
}
