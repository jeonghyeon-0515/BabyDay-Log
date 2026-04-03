import 'package:flutter/material.dart';

import '../data/household_repository.dart';
import '../domain/household_summary.dart';

class HouseholdListPage extends StatefulWidget {
  const HouseholdListPage({super.key, required this.repository});

  final HouseholdRepository repository;

  @override
  State<HouseholdListPage> createState() => _HouseholdListPageState();
}

class _HouseholdListPageState extends State<HouseholdListPage> {
  List<HouseholdSummary> _households = const [];
  String? _message;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHouseholds();
  }

  Future<void> _loadHouseholds() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final households = await widget.repository.fetchMyHouseholds();
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
    return Scaffold(
      appBar: AppBar(title: const Text('Household 목록')),
      body: RefreshIndicator(
        onRefresh: _loadHouseholds,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading) const LinearProgressIndicator(),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            for (final household in _households) ...[
              Card(
                child: ListTile(
                  title: Text(household.name),
                  subtitle: Text(
                    'role: ${household.role} · status: ${household.status}\n'
                    'locale: ${household.locale} · timezone: ${household.timezone}\n'
                    'growth: ${household.growthChartStandard}',
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
