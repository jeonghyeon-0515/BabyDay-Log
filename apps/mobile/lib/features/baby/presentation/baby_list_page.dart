import 'package:flutter/material.dart';

import '../data/baby_repository.dart';
import '../domain/baby_summary.dart';

class BabyListPage extends StatefulWidget {
  const BabyListPage({super.key, required this.repository});

  final BabyRepository repository;

  @override
  State<BabyListPage> createState() => _BabyListPageState();
}

class _BabyListPageState extends State<BabyListPage> {
  List<BabySummary> _babies = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBabies();
  }

  Future<void> _loadBabies() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final babies = await widget.repository.fetchMyBabies();
      if (!mounted) return;
      setState(() {
        _babies = babies;
        _message = babies.isEmpty ? '등록된 아기가 없습니다.' : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '아기 정보를 불러오지 못했어요.';
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
      appBar: AppBar(title: const Text('아기 목록')),
      body: RefreshIndicator(
        onRefresh: _loadBabies,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            for (final baby in _babies) ...[
              Card(
                child: ListTile(
                  title: Text(baby.name),
                  subtitle: Text(
                    '${baby.birthDate}\n'
                    '${baby.sex}',
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
