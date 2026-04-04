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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('현재 아기', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(selectedBaby?.name ?? '선택된 아기 없음'),
            const SizedBox(height: 4),
            Text(
              selectedBaby == null
                  ? '아기가 아직 없습니다.'
                  : '생년월일: ${selectedBaby!.birthDate} · 성별: ${selectedBaby!.sex}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: availableBabies.isEmpty
                  ? null
                  : () => _showSelector(context),
              child: const Text('아기 선택'),
            ),
          ],
        ),
      ),
    );
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
