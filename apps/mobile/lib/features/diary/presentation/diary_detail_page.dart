import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../domain/diary_entry_summary.dart';

class DiaryDetailPage extends StatefulWidget {
  const DiaryDetailPage({
    super.key,
    required this.repository,
    required this.entry,
  });

  final DiaryRepository repository;
  final DiaryEntrySummary entry;

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  late String _selectedVisibility;
  late String _currentVisibility;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _selectedVisibility = widget.entry.visibility;
    _currentVisibility = widget.entry.visibility;
  }

  bool get _canEditVisibility {
    final currentUserId = widget.repository.currentUser?.id;
    return currentUserId != null && currentUserId == widget.entry.authorUserId;
  }

  bool get _hasVisibilityChanges => _selectedVisibility != _currentVisibility;

  Future<void> _saveVisibility() async {
    if (!_canEditVisibility || !_hasVisibilityChanges) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.repository.updateDiaryVisibility(
        diaryEntryId: widget.entry.id,
        visibility: _selectedVisibility,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '공개 범위 변경 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _visibilityLabel(String visibility) {
    switch (visibility) {
      case 'private':
        return '비공개';
      case 'household':
        return 'household 공유';
      case 'public':
        return '공개';
      default:
        return visibility;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('일기 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.entry.title?.isNotEmpty == true
                        ? widget.entry.title!
                        : '(제목 없음)',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text('현재 공개 범위: ${_visibilityLabel(_currentVisibility)}'),
                  const SizedBox(height: 4),
                  Text('일기 날짜: ${widget.entry.eventDate ?? '없음'}'),
                  const SizedBox(height: 4),
                  Text('아기 ID: ${widget.entry.babyId}'),
                  const SizedBox(height: 16),
                  SelectableText(
                    widget.entry.body,
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('공개 범위 변경', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    _canEditVisibility
                        ? '이 일기의 공개 범위를 바꿀 수 있습니다.'
                        : '다른 사용자의 일기는 공개 범위를 바꿀 수 없습니다.',
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedVisibility,
                    decoration: const InputDecoration(
                      labelText: '공개 범위',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'private', child: Text('비공개')),
                      DropdownMenuItem(
                        value: 'household',
                        child: Text('household 공유'),
                      ),
                      DropdownMenuItem(value: 'public', child: Text('공개')),
                    ],
                    onChanged: _canEditVisibility
                        ? (value) => setState(
                            () => _selectedVisibility = value ?? 'private',
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed:
                        _canEditVisibility &&
                            !_isSaving &&
                            _hasVisibilityChanges
                        ? _saveVisibility
                        : null,
                    child: Text(_isSaving ? '저장 중...' : '공개 범위 저장'),
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
        ],
      ),
    );
  }
}
