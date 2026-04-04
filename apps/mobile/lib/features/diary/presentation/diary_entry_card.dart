import 'package:flutter/material.dart';

import '../domain/diary_entry_summary.dart';

class DiaryEntryCard extends StatelessWidget {
  const DiaryEntryCard({
    super.key,
    required this.entry,
    this.currentUserId,
    this.onTap,
    this.highlight = false,
  });

  final DiaryEntrySummary entry;
  final String? currentUserId;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final surface = highlight
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final onSurface = highlight ? colors.onPrimaryContainer : colors.onSurface;

    return Card(
      color: surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      entry.titleDisplay,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                      ),
                    ),
                  ),
                  if (onTap != null) const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MetaChip(
                    label: entry.authorLabel(currentUserId: currentUserId),
                  ),
                  _MetaChip(label: '공개 범위: ${entry.visibilityLabel}'),
                  _MetaChip(label: '날짜: ${entry.eventDateLabel}'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                entry.body,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
  }
}
