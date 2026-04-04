import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../domain/diary_entry_summary.dart';

class PublicDiaryFeedPage extends StatefulWidget {
  const PublicDiaryFeedPage({super.key, required this.repository});

  final DiaryRepository repository;

  @override
  State<PublicDiaryFeedPage> createState() => _PublicDiaryFeedPageState();
}

class _PublicDiaryFeedPageState extends State<PublicDiaryFeedPage> {
  List<DiaryEntrySummary> _entries = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final entries = await widget.repository.fetchPublicDiaries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _message = entries.isEmpty ? '표시할 공개 일기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '공개 일기 조회 실패: $error';
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
    return Scaffold(
      appBar: AppBar(title: const Text('공개 일기 피드')),
      body: RefreshIndicator(
        onRefresh: _loadEntries,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            for (final entry in _entries) ...[
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
          ],
        ),
      ),
    );
  }
}
