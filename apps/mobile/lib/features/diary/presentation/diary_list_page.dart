import 'package:flutter/material.dart';

import '../data/diary_repository.dart';
import '../domain/diary_entry_summary.dart';
import 'diary_detail_page.dart';
import 'diary_entry_card.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key, required this.repository});

  final DiaryRepository repository;

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
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
      final entries = await widget.repository.fetchRecentDiaries();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _message = entries.isEmpty ? '작성된 일기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '일기 조회 실패: $error';
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
    final refreshed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) =>
            DiaryDetailPage(repository: widget.repository, entry: entry),
      ),
    );

    if (refreshed == true && mounted) {
      await _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.repository.currentUser?.id;
    return Scaffold(
      appBar: AppBar(title: const Text('일기 목록')),
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
              DiaryEntryCard(
                entry: entry,
                currentUserId: currentUserId,
                onTap: () => _openDetail(entry),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
