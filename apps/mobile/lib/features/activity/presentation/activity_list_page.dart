import 'package:flutter/material.dart';

import '../data/activity_repository.dart';
import '../domain/activity_event_summary.dart';

class ActivityListPage extends StatefulWidget {
  const ActivityListPage({super.key, required this.repository});

  final ActivityRepository repository;

  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  List<ActivityEventSummary> _events = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final events = await widget.repository.fetchRecentActivityEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _message = events.isEmpty ? '최근 기록이 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '기록을 불러오지 못했어요.';
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
      appBar: AppBar(title: const Text('기록 목록')),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            for (final event in _events) ...[
              Card(
                child: ListTile(
                  title: Text(event.eventTypeLabel),
                  subtitle: Text(_eventSubtitle(event)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  String _eventSubtitle(ActivityEventSummary event) {
    final buffer = StringBuffer()
      ..write('${event.displayDetailSummary}\n')
      ..write(event.recordedAt);

    if (event.note != null && event.note!.trim().isNotEmpty) {
      buffer.write('\n메모: ${event.note}');
    }
    return buffer.toString();
  }
}
