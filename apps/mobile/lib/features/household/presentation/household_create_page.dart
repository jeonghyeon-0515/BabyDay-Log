import 'package:flutter/material.dart';

import '../data/household_repository.dart';

class HouseholdCreatePage extends StatefulWidget {
  const HouseholdCreatePage({super.key, required this.repository});

  final HouseholdRepository repository;

  @override
  State<HouseholdCreatePage> createState() => _HouseholdCreatePageState();
}

class _HouseholdCreatePageState extends State<HouseholdCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _localeController;
  late final TextEditingController _timezoneController;
  late final TextEditingController _growthStandardController;
  bool _isSaving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _localeController = TextEditingController(text: 'ko');
    _timezoneController = TextEditingController(text: 'Asia/Seoul');
    _growthStandardController = TextEditingController(text: 'kr_2017');
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() {
      _isSaving = true;
      _message = null;
    });

    try {
      await widget.repository.createHousehold(
        name: _nameController.text.trim(),
        locale: _localeController.text.trim(),
        timezone: _timezoneController.text.trim(),
        growthChartStandard: _growthStandardController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가족을 만들었어요.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _message = '가족을 만들지 못했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _localeController.dispose();
    _timezoneController.dispose();
    _growthStandardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('가족 만들기')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '가족 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '가족 이름을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: Text(_isSaving ? '저장 중...' : '가족 만들기'),
                ),
              ],
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}
